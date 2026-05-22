import Foundation
import KamikazeCore

public struct PilotInput: Sendable, Equatable {
    public var throttle: Double
    public var pitch: Double
    public var yaw: Double
    public var roll: Double
    public var firing: Bool

    public init(throttle: Double = 0, pitch: Double = 0, yaw: Double = 0, roll: Double = 0, firing: Bool = false) {
        self.throttle = throttle
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
        self.firing = firing
    }
}

public struct CombatantState: Sendable, Equatable, Identifiable {
    public var id: String
    public var aircraft: AircraftBlueprint
    public var team: Team
    public var position: Vector3
    public var heading: Double
    public var pitch: Double
    public var roll: Double
    public var throttle: Double
    public var health: Double
    public var ammo: Int
    public var fuelRemaining: Double
    public var damageState: DamageState
    public var weaponCooldownRemaining: Double
    public var isPlayer: Bool
    public var isActive: Bool

    public init(spawn: SpawnDefinition, aircraft: AircraftBlueprint, isPlayer: Bool) {
        id = spawn.id
        self.aircraft = aircraft
        team = spawn.team
        position = spawn.position
        heading = spawn.heading
        pitch = spawn.pitch
        roll = 0
        throttle = 0.65
        health = aircraft.durability
        ammo = aircraft.armament.ammoCapacity
        fuelRemaining = 240
        damageState = .pristine
        weaponCooldownRemaining = 0
        self.isPlayer = isPlayer
        isActive = spawn.cinematicIntroDelay == 0
    }

    public var isAlive: Bool {
        health > 0
    }

    public var speed: Double {
        let engineFactor = max(0.22, 1 - (damageState.engineLoss * 0.72))
        let fuelFactor = fuelRemaining <= 0 ? 0.2 : 1
        return (aircraft.cruiseSpeed + ((aircraft.maxSpeed - aircraft.cruiseSpeed) * throttle)) * engineFactor * fuelFactor
    }

    public var forward: Vector3 {
        let cosPitch = cos(pitch)
        return Vector3(
            x: sin(heading) * cosPitch,
            y: sin(pitch),
            z: -cos(heading) * cosPitch
        ).normalized
    }
}

public struct CombatEvent: Sendable, Equatable, Identifiable {
    public enum Kind: Sendable, Equatable {
        case shotFired(origin: Vector3, direction: Vector3)
        case hit(targetID: String)
        case destroyed(targetID: String)
        case cinematicBeat(id: String, title: String, body: String)
    }

    public var id: UUID
    public var time: Double
    public var kind: Kind

    public init(id: UUID = UUID(), time: Double, kind: Kind) {
        self.id = id
        self.time = time
        self.kind = kind
    }
}

public enum MissionOutcome: String, Sendable, Equatable {
    case inProgress
    case success
    case failure
}

public struct MissionSnapshot: Sendable, Equatable {
    public var time: Double
    public var outcome: MissionOutcome
    public var player: CombatantState
    public var enemies: [CombatantState]
    public var events: [CombatEvent]
    public var objectiveSummary: [String]

    public var remainingEnemyCount: Int {
        enemies.filter(\.isAlive).count
    }
}

public struct GameSimulation: Sendable {
    public let mission: MissionDefinition
    public private(set) var combatants: [CombatantState]
    public private(set) var missionTime: Double
    public private(set) var outcome: MissionOutcome
    public private(set) var events: [CombatEvent]

    private let weatherProfile: WeatherProfile
    private let aimAssistMultiplier: Double
    private let steeringBonus: Double
    private let engineCeilingBonus: Double
    private let fuelLeakBonus: Double
    private let stabilityBonus: Double
    private var triggeredBeatIDs: Set<String>

    public init(
        mission: MissionDefinition,
        selectedAircraft: AircraftBlueprint,
        aircraftCatalog: [AircraftBlueprint] = ContentLibrary.aircraft,
        purchasedUpgradeIDs: [String] = [],
        aimAssistLevel: AimAssistLevel = .standard
    ) {
        self.mission = mission
        let indexedAircraft = Dictionary(uniqueKeysWithValues: aircraftCatalog.map { ($0.id, $0) })
        weatherProfile = ContentLibrary.weather.first(where: { $0.id == mission.weatherProfileID }) ?? ContentLibrary.weather[0]
        steeringBonus = ContentLibrary.upgrades
            .filter { purchasedUpgradeIDs.contains($0.id) && $0.effectType == .steeringAuthority }
            .reduce(0) { $0 + $1.magnitude }
        engineCeilingBonus = ContentLibrary.upgrades
            .filter { purchasedUpgradeIDs.contains($0.id) && $0.effectType == .engineCeiling }
            .reduce(0) { $0 + $1.magnitude }
        fuelLeakBonus = ContentLibrary.upgrades
            .filter { purchasedUpgradeIDs.contains($0.id) && $0.effectType == .fuelLeakReduction }
            .reduce(0) { $0 + $1.magnitude }
        stabilityBonus = ContentLibrary.upgrades
            .filter { purchasedUpgradeIDs.contains($0.id) && $0.effectType == .stabilityDamping }
            .reduce(0) { $0 + $1.magnitude }
        let aimBonus = ContentLibrary.upgrades
            .filter { purchasedUpgradeIDs.contains($0.id) && $0.effectType == .aimAssist }
            .reduce(0) { $0 + $1.magnitude }
        let aimAssistLevelBonus: Double
        switch aimAssistLevel {
        case .off:
            aimAssistLevelBonus = -1.8
        case .standard:
            aimAssistLevelBonus = 0
        case .generous:
            aimAssistLevelBonus = 0.4
        }
        aimAssistMultiplier = max(1, 1.8 + aimBonus + aimAssistLevelBonus)

        let playerSpawn = SpawnDefinition(
            id: mission.playerSpawn.id,
            aircraftID: selectedAircraft.id,
            team: mission.playerSpawn.team,
            position: mission.playerSpawn.position,
            heading: mission.playerSpawn.heading,
            pitch: mission.playerSpawn.pitch,
            cinematicIntroDelay: mission.playerSpawn.cinematicIntroDelay,
            aiRole: mission.playerSpawn.aiRole
        )
        let player = CombatantState(spawn: playerSpawn, aircraft: selectedAircraft, isPlayer: true)
        let enemies = mission.enemySpawns.compactMap { spawn -> CombatantState? in
            guard let aircraft = indexedAircraft[spawn.aircraftID] else { return nil }
            return CombatantState(spawn: spawn, aircraft: aircraft, isPlayer: false)
        }
        combatants = [player] + enemies
        missionTime = 0
        outcome = .inProgress
        events = []
        triggeredBeatIDs = []
    }

    public var player: CombatantState {
        combatants.first(where: \.isPlayer)!
    }

    public var snapshot: MissionSnapshot {
        MissionSnapshot(
            time: missionTime,
            outcome: outcome,
            player: player,
            enemies: combatants.filter { !$0.isPlayer },
            events: events,
            objectiveSummary: objectiveLines()
        )
    }

    public mutating func advance(playerInput: PilotInput, deltaTime: Double) {
        guard outcome == .inProgress else { return }
        missionTime += deltaTime
        events.removeAll(keepingCapacity: true)
        triggerCinematicBeats()
        activateIntroSpawns()
        updatePlayer(with: playerInput, deltaTime: deltaTime)
        updateEnemies(deltaTime: deltaTime)
        resolveCombat(playerInput: playerInput, deltaTime: deltaTime)
        evaluateMissionOutcome()
    }

    private mutating func triggerCinematicBeats() {
        let beats = mission.cinematicBeats.filter { beat in
            beat.triggerTime <= missionTime && !triggeredBeatIDs.contains(beat.id)
        }
        for beat in beats {
            triggeredBeatIDs.insert(beat.id)
            events.append(CombatEvent(time: missionTime, kind: .cinematicBeat(id: beat.id, title: beat.title, body: beat.body)))
        }
    }

    private mutating func activateIntroSpawns() {
        for index in combatants.indices where !combatants[index].isActive && mission.enemySpawns.contains(where: { $0.id == combatants[index].id && $0.cinematicIntroDelay <= missionTime }) {
            combatants[index].isActive = true
        }
    }

    private mutating func updatePlayer(with input: PilotInput, deltaTime: Double) {
        guard let playerIndex = combatants.firstIndex(where: \.isPlayer) else { return }
        combatants[playerIndex].heading += weatherProfile.windIntensity * 0.006 * sin(missionTime * 0.4) * deltaTime
        let weatherThrottleCeiling = 1.0 - (weatherProfile.stormIntensity * 0.12)
        let throttleUpperBound = min(1.0, weatherThrottleCeiling + (engineCeilingBonus * 0.1))
        combatants[playerIndex].throttle = clamp(
            combatants[playerIndex].throttle + (input.throttle * combatants[playerIndex].aircraft.throttleResponse * deltaTime),
            lower: 0.2,
            upper: throttleUpperBound
        )
        let steeringAuthority = max(0.15 + (steeringBonus * 0.5), 1 - (combatants[playerIndex].damageState.steeringLoss * 0.75))
        let divePenalty = combatants[playerIndex].pitch < -0.2 ? 0.6 : 1
        let pitchModifier = input.pitch * combatants[playerIndex].aircraft.climbRate * 0.01 * steeringAuthority * divePenalty * deltaTime
        combatants[playerIndex].pitch = clamp(combatants[playerIndex].pitch + pitchModifier, lower: -0.6, upper: 0.65)
        let instabilityDrift = sin(missionTime * 1.35) * combatants[playerIndex].damageState.stabilityLoss * 0.08
        let stabilityMultiplier = max(0.1, 1 - stabilityBonus)
        let stormDrift = instabilityDrift * (1 + weatherProfile.stormIntensity * 0.5) * stabilityMultiplier
        let rollDamping = 0.92
        let rollInputStrength = 1.2
        combatants[playerIndex].roll = (combatants[playerIndex].roll * rollDamping) + (input.roll * rollInputStrength * deltaTime)
        combatants[playerIndex].roll = clamp(combatants[playerIndex].roll, lower: -1.0, upper: 1.0)
        let rollYawCoupling = combatants[playerIndex].roll * 0.35 * steeringAuthority * deltaTime
        combatants[playerIndex].heading += (input.yaw * combatants[playerIndex].aircraft.turnRate * steeringAuthority * deltaTime) + (stormDrift * deltaTime) + rollYawCoupling
        combatants[playerIndex].position = combatants[playerIndex].position + (combatants[playerIndex].forward * combatants[playerIndex].speed * deltaTime)
        combatants[playerIndex].position.y = max(4, combatants[playerIndex].position.y)
        combatants[playerIndex].fuelRemaining = max(
            0,
            combatants[playerIndex].fuelRemaining - ((0.55 + combatants[playerIndex].throttle + (combatants[playerIndex].damageState.fuelLeak * (2.2 * (1 - fuelLeakBonus)))) * deltaTime)
        )
        combatants[playerIndex].weaponCooldownRemaining = max(0, combatants[playerIndex].weaponCooldownRemaining - deltaTime)
    }

    private mutating func updateEnemies(deltaTime: Double) {
        let playerPosition = player.position
        for index in combatants.indices where !combatants[index].isPlayer && combatants[index].isAlive && combatants[index].isActive {
            combatants[index].heading += weatherProfile.windIntensity * 0.004 * sin(missionTime * 0.4 + Double(index)) * deltaTime
            combatants[index].roll *= 0.88
            let baseRole = mission.enemySpawns.first(where: { $0.id == combatants[index].id })?.aiRole ?? .intercept
            let role: AIRole = combatants[index].health < combatants[index].aircraft.durability * 0.25 ? .retreat : baseRole
            switch role {
            case .intercept:
                pursuePlayer(at: index, playerPosition: playerPosition, deltaTime: deltaTime)
            case .patrol:
                if let spawnPos = mission.enemySpawns.first(where: { $0.id == combatants[index].id })?.position {
                    let distToPlayer = (playerPosition - combatants[index].position).length
                    if distToPlayer > 350 {
                        let angle = missionTime * 0.25
                        let targetX = spawnPos.x + cos(angle) * 120
                        let targetZ = spawnPos.z + sin(angle * 0.5) * 80
                        let target = Vector3(x: targetX, y: spawnPos.y, z: targetZ)
                        let toTarget = (target - combatants[index].position).normalized
                        let desiredHeading = atan2(toTarget.x, -toTarget.z)
                        let desiredPitch = asin(clamp(toTarget.y, lower: -1.0, upper: 1.0))
                        combatants[index].heading += (desiredHeading - combatants[index].heading) * min(deltaTime * 0.5, 1)
                        combatants[index].pitch += (desiredPitch - combatants[index].pitch) * min(deltaTime * 0.3, 1)
                        combatants[index].throttle = clamp(combatants[index].throttle + (0.05 * deltaTime), lower: 0.45, upper: 0.82)
                    } else {
                        pursuePlayer(at: index, playerPosition: playerPosition, deltaTime: deltaTime)
                    }
                } else {
                    pursuePlayer(at: index, playerPosition: playerPosition, deltaTime: deltaTime)
                }
            case .formationWing:
                if let leadIndex = combatants.indices.first(where: { !combatants[$0].isPlayer && combatants[$0].isAlive && combatants[$0].isActive && $0 != index }) {
                    let lead = combatants[leadIndex]
                    let offset = Vector3(x: 25, y: 0, z: -20)
                    let formationTarget = lead.position + offset
                    let toTarget = (formationTarget - combatants[index].position).normalized
                    let desiredHeading = atan2(toTarget.x, -toTarget.z)
                    combatants[index].heading += (desiredHeading - combatants[index].heading) * min(deltaTime * 0.7, 1)
                    combatants[index].pitch += (lead.pitch - combatants[index].pitch) * min(deltaTime * 0.5, 1)
                    combatants[index].throttle = clamp(lead.throttle + 0.05, lower: 0.5, upper: 1.0)
                } else {
                    pursuePlayer(at: index, playerPosition: playerPosition, deltaTime: deltaTime)
                }
            case .retreat:
                let toAway = (combatants[index].position - playerPosition).normalized
                let fleeHeading = atan2(toAway.x, -toAway.z)
                combatants[index].heading += (fleeHeading - combatants[index].heading) * min(deltaTime * 0.8, 1)
                combatants[index].pitch = clamp(combatants[index].pitch + (0.4 * deltaTime), lower: -0.2, upper: 0.6)
                combatants[index].throttle = min(1.0, combatants[index].throttle + 0.2 * deltaTime)
            }
            combatants[index].position = combatants[index].position + (combatants[index].forward * combatants[index].speed * deltaTime)
            combatants[index].position.y = max(6, combatants[index].position.y)
            combatants[index].fuelRemaining = max(
                0,
                combatants[index].fuelRemaining - ((0.45 + combatants[index].throttle + (combatants[index].damageState.fuelLeak * 1.6)) * deltaTime)
            )
            combatants[index].weaponCooldownRemaining = max(0, combatants[index].weaponCooldownRemaining - deltaTime)
        }
    }

    private mutating func pursuePlayer(at index: Int, playerPosition: Vector3, deltaTime: Double) {
        let toPlayer = (playerPosition - combatants[index].position).normalized
        let desiredHeading = atan2(toPlayer.x, -toPlayer.z)
        let desiredPitch = asin(clamp(toPlayer.y, lower: -1.0, upper: 1.0))
        combatants[index].heading += (desiredHeading - combatants[index].heading) * min(deltaTime * 0.6, 1)
        combatants[index].pitch += (desiredPitch - combatants[index].pitch) * min(deltaTime * 0.35, 1)
        combatants[index].throttle = clamp(combatants[index].throttle + (0.1 * deltaTime), lower: 0.5, upper: 1)
    }

    private mutating func resolveCombat(playerInput: PilotInput, deltaTime: Double) {
        guard let playerIndex = combatants.firstIndex(where: \.isPlayer) else { return }
        if playerInput.firing {
            fireIfPossible(attackerIndex: playerIndex, preferredTargetTeam: .enemy)
        }
        for index in combatants.indices where !combatants[index].isPlayer && combatants[index].isAlive && combatants[index].isActive {
            let toPlayer = player.position - combatants[index].position
            if toPlayer.length < combatants[index].aircraft.armament.effectiveRange {
                fireIfPossible(attackerIndex: index, preferredTargetTeam: .player)
            }
        }
        let playerPos = combatants[playerIndex].position
        for emitter in mission.navalAAEmitters where combatants[playerIndex].isAlive {
            let dist = (playerPos - emitter.position).length
            if dist <= emitter.range {
                let fireInterval = 1.0 / emitter.fireRate
                let phase = emitter.position.x + emitter.position.z
                if fmod(missionTime + phase * 0.1, fireInterval) < deltaTime {
                    applyDamage(to: playerIndex, amount: emitter.damagePerRound * (1.0 - dist / emitter.range))
                }
            }
        }
    }

    private mutating func fireIfPossible(attackerIndex: Int, preferredTargetTeam: Team) {
        guard combatants[attackerIndex].ammo > 0 else { return }
        guard combatants[attackerIndex].weaponCooldownRemaining <= 0 else { return }
        let targets = combatants.indices.filter { index in
            combatants[index].team == preferredTargetTeam && combatants[index].isAlive && combatants[index].isActive
        }
        guard let targetIndex = bestTarget(for: attackerIndex, candidates: targets) else { return }
        combatants[attackerIndex].ammo -= 1
        combatants[attackerIndex].weaponCooldownRemaining = combatants[attackerIndex].aircraft.armament.fireCooldown
        let direction = (combatants[targetIndex].position - combatants[attackerIndex].position).normalized
        events.append(CombatEvent(time: missionTime, kind: .shotFired(origin: combatants[attackerIndex].position, direction: direction)))
        let damageMultiplier = combatants[attackerIndex].isPlayer ? 1.35 : 1
        applyDamage(to: targetIndex, amount: combatants[attackerIndex].aircraft.armament.damagePerHit * damageMultiplier)
    }

    private func bestTarget(for attackerIndex: Int, candidates: [Int]) -> Int? {
        let attacker = combatants[attackerIndex]
        let validTargets = candidates
            .map { ($0, combatants[$0]) }
            .filter { _, target in
                let offset = target.position - attacker.position
                let distance = offset.length
                guard distance <= attacker.aircraft.armament.effectiveRange else { return false }
                let alignment = Vector3.dot(attacker.forward, offset.normalized)
                return alignment > 0.86
            }
        if let targetIndex = validTargets.min(by: { lhs, rhs in
            (lhs.1.position - attacker.position).length < (rhs.1.position - attacker.position).length
        })?.0 {
            return targetIndex
        }
        guard attacker.isPlayer else { return nil }
        return candidates
            .map { ($0, combatants[$0]) }
            .filter { _, target in
                let offset = target.position - attacker.position
                return offset.length <= attacker.aircraft.armament.effectiveRange * aimAssistMultiplier
            }
            .min(by: { lhs, rhs in
                (lhs.1.position - attacker.position).length < (rhs.1.position - attacker.position).length
            })?
            .0
    }

    private mutating func applyDamage(to targetIndex: Int, amount: Double) {
        combatants[targetIndex].health = max(0, combatants[targetIndex].health - amount)
        combatants[targetIndex].damageState.applyHit(normalizedSeverity: amount / max(combatants[targetIndex].aircraft.durability, 1))
        events.append(CombatEvent(time: missionTime, kind: .hit(targetID: combatants[targetIndex].id)))
        if !combatants[targetIndex].isAlive {
            events.append(CombatEvent(time: missionTime, kind: .destroyed(targetID: combatants[targetIndex].id)))
        }
    }

    mutating func debugApplyDamage(toCombatantID id: String, amount: Double) {
        guard let targetIndex = combatants.firstIndex(where: { $0.id == id }) else { return }
        applyDamage(to: targetIndex, amount: amount)
    }

    private mutating func evaluateMissionOutcome() {
        if !player.isAlive {
            outcome = .failure
            return
        }
        if player.fuelRemaining <= 0 && player.position.y < 8 {
            outcome = .failure
            return
        }
        let allEnemiesDestroyed = combatants.filter { !$0.isPlayer }.allSatisfy { !$0.isAlive }
        let objectivesComplete = mission.objectives.allSatisfy { objective in
            switch objective {
            case .destroyAllEnemies:
                return allEnemiesDestroyed
            case let .survive(seconds):
                return missionTime >= seconds
            case let .escort(timeLimit):
                return missionTime >= timeLimit && player.isAlive
            }
        }
        if objectivesComplete {
            outcome = .success
            return
        }
        if missionTime >= mission.missionDuration {
            outcome = .failure
        }
    }

    private func objectiveLines() -> [String] {
        mission.objectives.map { objective in
            switch objective {
            case .destroyAllEnemies:
                return "Destroy enemy fighters — \(combatants.filter { !$0.isPlayer && $0.isAlive }.count) remaining"
            case let .survive(seconds):
                return "Hold the line for \(Int(max(0, seconds - missionTime))) more seconds"
            case let .escort(timeLimit):
                return "Escort the fleet for \(Int(max(0, timeLimit - missionTime))) more seconds"
            }
        }
    }
}
