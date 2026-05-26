import { AIRole, AircraftBlueprint, CombatEvent, CombatantState, DamageState, MissionDefinition, MissionOutcome, MissionSnapshot, PilotInput, SpawnDefinition, Team, UpgradeDefinition, UpgradeEffectType, Vector3, WeatherProfile, clamp, pristineDamageState } from './types'

const id = () => Math.random().toString(36).slice(2)
const aimAssistBonuses = { off: -1.8, standard: 0, generous: 0.4 } as const
const baseEnemyTargetingCone = 0.72
const visibilityConePenalty = 0.25
const hitChanceFloor = { player: 0.16, enemy: 0.12 } as const
const hitChanceBase = { player: 0.52, enemy: 0.38 } as const
export type BrowserAimAssistLevel = keyof typeof aimAssistBonuses

export class GameSimulation {
  missionTime = 0
  outcome: MissionOutcome = 'inProgress'
  events: CombatEvent[] = []
  combatants: CombatantState[] = []
  private triggeredBeatIDs = new Set<string>()
  private weatherProfile: WeatherProfile
  private aimAssistMultiplier: number
  private steeringBonus: number
  private engineCeilingBonus: number
  private fuelLeakBonus: number
  private stabilityBonus: number

  constructor(
    public readonly mission: MissionDefinition,
    selectedAircraft: AircraftBlueprint,
    aircraftCatalog: AircraftBlueprint[],
    weatherCatalog: WeatherProfile[],
    upgrades: UpgradeDefinition[],
    purchasedUpgradeIDs: string[] = [],
    aimAssistLevel: BrowserAimAssistLevel = 'standard',
  ) {
    const indexedAircraft = new Map(aircraftCatalog.map((aircraft) => [aircraft.id, aircraft]))
    this.weatherProfile = weatherCatalog.find((weather) => weather.id === mission.weatherProfileID) ?? weatherCatalog[0]
    const sum = (effectType: UpgradeEffectType) => upgrades.filter((upgrade) => purchasedUpgradeIDs.includes(upgrade.id) && upgrade.effectType === effectType).reduce((acc, upgrade) => acc + upgrade.magnitude, 0)
    this.steeringBonus = sum(UpgradeEffectType.steeringAuthority)
    this.engineCeilingBonus = sum(UpgradeEffectType.engineCeiling)
    this.fuelLeakBonus = sum(UpgradeEffectType.fuelLeakReduction)
    this.stabilityBonus = sum(UpgradeEffectType.stabilityDamping)
    const aimBonus = sum(UpgradeEffectType.aimAssist)
    this.aimAssistMultiplier = Math.max(1, 1.8 + aimBonus + aimAssistBonuses[aimAssistLevel])

    const playerSpawn: SpawnDefinition = { ...mission.playerSpawn, aircraftID: selectedAircraft.id }
    this.combatants = [this.spawnCombatant(playerSpawn, selectedAircraft, true)]
    for (const spawn of mission.enemySpawns) {
      const aircraft = indexedAircraft.get(spawn.aircraftID)
      if (aircraft) this.combatants.push(this.spawnCombatant(spawn, aircraft, false))
    }
  }

  get player(): CombatantState { return this.combatants.find((combatant) => combatant.isPlayer)! }

  get snapshot(): MissionSnapshot {
    return {
      time: this.missionTime,
      outcome: this.outcome,
      player: this.player,
      enemies: this.combatants.filter((combatant) => !combatant.isPlayer),
      events: this.events,
      objectiveSummary: this.objectiveLines(),
    }
  }

  advance(playerInput: PilotInput, deltaTime: number): void {
    if (this.outcome !== 'inProgress') return
    this.missionTime += deltaTime
    this.events = []
    this.triggerCinematicBeats()
    this.activateIntroSpawns()
    this.updatePlayer(playerInput, deltaTime)
    this.updateEnemies(deltaTime)
    this.resolveCombat(playerInput, deltaTime)
    this.evaluateMissionOutcome()
  }

  private spawnCombatant(spawn: SpawnDefinition, aircraft: AircraftBlueprint, isPlayer: boolean): CombatantState {
    return {
      id: spawn.id,
      aircraft,
      team: spawn.team,
      position: Vector3.from(spawn.position),
      heading: spawn.heading,
      pitch: spawn.pitch,
      roll: 0,
      throttle: 0.65,
      health: aircraft.durability,
      ammo: aircraft.armament.ammoCapacity,
      fuelRemaining: 240,
      damageState: pristineDamageState(),
      weaponCooldownRemaining: 0,
      isPlayer,
      isActive: spawn.cinematicIntroDelay === 0,
    }
  }

  private forward(combatant: CombatantState): Vector3 {
    const cosPitch = Math.cos(combatant.pitch)
    return new Vector3(Math.sin(combatant.heading) * cosPitch, Math.sin(combatant.pitch), -Math.cos(combatant.heading) * cosPitch).normalized
  }

  private speed(combatant: CombatantState): number {
    const engineFactor = Math.max(0.22, 1 - combatant.damageState.engineLoss * 0.72)
    const fuelFactor = combatant.fuelRemaining <= 0 ? 0.2 : 1
    return (combatant.aircraft.cruiseSpeed + (combatant.aircraft.maxSpeed - combatant.aircraft.cruiseSpeed) * combatant.throttle) * engineFactor * fuelFactor
  }

  private triggerCinematicBeats(): void {
    for (const beat of this.mission.cinematicBeats) {
      if (beat.triggerTime <= this.missionTime && !this.triggeredBeatIDs.has(beat.id)) {
        this.triggeredBeatIDs.add(beat.id)
        this.events.push({ id: id(), time: this.missionTime, kind: 'cinematicBeat', beatID: beat.id, title: beat.title, body: beat.body })
      }
    }
  }

  private activateIntroSpawns(): void {
    for (const combatant of this.combatants) {
      if (!combatant.isActive && this.mission.enemySpawns.some((spawn) => spawn.id === combatant.id && spawn.cinematicIntroDelay <= this.missionTime)) {
        combatant.isActive = true
      }
    }
  }

  private updatePlayer(input: PilotInput, deltaTime: number): void {
    const player = this.player
    player.heading += this.weatherProfile.windIntensity * 0.006 * Math.sin(this.missionTime * 0.4) * deltaTime
    const weatherThrottleCeiling = 1 - this.weatherProfile.stormIntensity * 0.12
    const throttleUpperBound = Math.min(1, weatherThrottleCeiling + this.engineCeilingBonus * 0.1)
    player.throttle = clamp(player.throttle + input.throttle * player.aircraft.throttleResponse * deltaTime, 0.2, throttleUpperBound)
    const steeringAuthority = Math.max(0.15 + this.steeringBonus * 0.5, 1 - player.damageState.steeringLoss * 0.75)
    const divePenalty = player.pitch < -0.2 ? 0.6 : 1
    player.pitch = clamp(player.pitch + input.pitch * player.aircraft.climbRate * 0.01 * steeringAuthority * divePenalty * deltaTime, -0.6, 0.65)
    const instabilityDrift = Math.sin(this.missionTime * 1.35) * player.damageState.stabilityLoss * 0.08
    const stormDrift = instabilityDrift * (1 + this.weatherProfile.stormIntensity * 0.5) * Math.max(0.1, 1 - this.stabilityBonus)
    player.roll = clamp(player.roll * 0.92 + input.roll * 1.2 * deltaTime, -1, 1)
    const rollYawCoupling = player.roll * 0.35 * steeringAuthority * deltaTime
    player.heading += input.yaw * player.aircraft.turnRate * steeringAuthority * deltaTime + stormDrift * deltaTime + rollYawCoupling
    player.position = player.position.add(this.forward(player).scale(this.speed(player) * deltaTime))
    player.position.y = Math.max(4, player.position.y)
    player.fuelRemaining = Math.max(0, player.fuelRemaining - ((0.55 + player.throttle + player.damageState.fuelLeak * (2.2 * (1 - this.fuelLeakBonus))) * deltaTime))
    player.weaponCooldownRemaining = Math.max(0, player.weaponCooldownRemaining - deltaTime)
  }

  private updateEnemies(deltaTime: number): void {
    const playerPosition = this.player.position
    this.combatants.forEach((combatant, index) => {
      if (combatant.isPlayer || combatant.health <= 0 || !combatant.isActive) return
      combatant.heading += this.weatherProfile.windIntensity * 0.004 * Math.sin(this.missionTime * 0.4 + index) * deltaTime
      combatant.roll *= 0.88
      const spawn = this.mission.enemySpawns.find((candidate) => candidate.id === combatant.id)
      const role = combatant.health < combatant.aircraft.durability * 0.25 ? AIRole.retreat : (spawn?.aiRole ?? AIRole.intercept)
      switch (role) {
        case AIRole.intercept:
          this.pursuePlayer(combatant, playerPosition, deltaTime)
          break
        case AIRole.patrol: {
          if (!spawn) break
          const distToPlayer = playerPosition.sub(combatant.position).length
          if (distToPlayer > 350) {
            const angle = this.missionTime * 0.25
            const target = new Vector3(spawn.position.x + Math.cos(angle) * 120, spawn.position.y, spawn.position.z + Math.sin(angle * 0.5) * 80)
            const toTarget = target.sub(combatant.position).normalized
            const desiredHeading = Math.atan2(toTarget.x, -toTarget.z)
            const desiredPitch = Math.asin(clamp(toTarget.y, -1, 1))
            combatant.heading = this.steerHeading(combatant.heading, desiredHeading, deltaTime * 0.5)
            combatant.pitch += (desiredPitch - combatant.pitch) * Math.min(deltaTime * 0.3, 1)
            combatant.throttle = clamp(combatant.throttle + 0.05 * deltaTime, 0.45, 0.82)
          } else {
            this.pursuePlayer(combatant, playerPosition, deltaTime)
          }
          break
        }
        case AIRole.formationWing: {
          const lead = this.combatants.find((candidate, candidateIndex) => candidateIndex !== index && !candidate.isPlayer && candidate.health > 0 && candidate.isActive)
          if (lead) {
            const formationTarget = lead.position.add(new Vector3(25, 0, -20))
            const toTarget = formationTarget.sub(combatant.position).normalized
            const desiredHeading = Math.atan2(toTarget.x, -toTarget.z)
            combatant.heading = this.steerHeading(combatant.heading, desiredHeading, deltaTime * 0.7)
            combatant.pitch += (lead.pitch - combatant.pitch) * Math.min(deltaTime * 0.5, 1)
            combatant.throttle = clamp(lead.throttle + 0.05, 0.5, 1)
          } else {
            this.pursuePlayer(combatant, playerPosition, deltaTime)
          }
          break
        }
        case AIRole.retreat: {
          const away = combatant.position.sub(playerPosition).normalized
          const fleeHeading = Math.atan2(away.x, -away.z)
          combatant.heading = this.steerHeading(combatant.heading, fleeHeading, deltaTime * 0.8)
          combatant.pitch = clamp(combatant.pitch + 0.4 * deltaTime, -0.2, 0.6)
          combatant.throttle = Math.min(1, combatant.throttle + 0.2 * deltaTime)
          break
        }
      }
      combatant.position = combatant.position.add(this.forward(combatant).scale(this.speed(combatant) * deltaTime))
      combatant.position.y = Math.max(6, combatant.position.y)
      combatant.fuelRemaining = Math.max(0, combatant.fuelRemaining - ((0.45 + combatant.throttle + combatant.damageState.fuelLeak * 1.6) * deltaTime))
      combatant.weaponCooldownRemaining = Math.max(0, combatant.weaponCooldownRemaining - deltaTime)
    })
  }

  private pursuePlayer(combatant: CombatantState, playerPosition: Vector3, deltaTime: number): void {
    const toPlayer = playerPosition.sub(combatant.position).normalized
    const desiredHeading = Math.atan2(toPlayer.x, -toPlayer.z)
    const desiredPitch = Math.asin(clamp(toPlayer.y, -1, 1))
    combatant.heading = this.steerHeading(combatant.heading, desiredHeading, deltaTime * 0.6)
    combatant.pitch += (desiredPitch - combatant.pitch) * Math.min(deltaTime * 0.35, 1)
    combatant.throttle = clamp(combatant.throttle + 0.1 * deltaTime, 0.5, 1)
  }

  private resolveCombat(playerInput: PilotInput, deltaTime: number): void {
    const playerIndex = this.combatants.findIndex((combatant) => combatant.isPlayer)
    if (playerIndex == null) return
    if (playerInput.firing) this.fireIfPossible(playerIndex, Team.enemy)
    this.combatants.forEach((combatant, index) => {
      if (combatant.isPlayer || combatant.health <= 0 || !combatant.isActive) return
      const toPlayer = this.player.position.sub(combatant.position)
      if (toPlayer.length < combatant.aircraft.armament.effectiveRange) {
        const targetingCone = baseEnemyTargetingCone - combatant.damageState.visibilityLoss * visibilityConePenalty
        if (Vector3.dot(this.forward(combatant), toPlayer.normalized) > targetingCone) this.fireIfPossible(index, Team.player)
      }
    })
    const playerPos = this.combatants[playerIndex].position
    for (const emitter of this.mission.navalAAEmitters) {
      const emitterPosition = Vector3.from(emitter.position)
      const dist = playerPos.sub(emitterPosition).length
      if (dist <= emitter.range) {
        const fireInterval = 1 / emitter.fireRate
        const phase = emitter.position.x + emitter.position.z
        if (((this.missionTime + phase * 0.1) % fireInterval) < deltaTime) {
          this.applyDamage(playerIndex, emitter.damagePerRound * (1 - dist / emitter.range))
        }
      }
    }
  }

  private fireIfPossible(attackerIndex: number, preferredTargetTeam: Team): void {
    const attacker = this.combatants[attackerIndex]
    if (attacker.ammo <= 0 || attacker.weaponCooldownRemaining > 0) return
    const targets = this.combatants.map((combatant, index) => ({ combatant, index })).filter(({ combatant }) => combatant.team === preferredTargetTeam && combatant.health > 0 && combatant.isActive)
    const targetIndex = this.bestTarget(attackerIndex, targets.map(({ index }) => index))
    if (targetIndex == null) return
    const target = this.combatants[targetIndex]
    const offset = target.position.sub(attacker.position)
    const distance = offset.length
    const alignment = clamp(Vector3.dot(this.forward(attacker), offset.normalized), -1, 1)
    const rangeRatio = clamp(1 - (distance / attacker.aircraft.armament.effectiveRange), 0, 1)
    const focus = clamp((alignment - 0.75) / 0.25, 0, 1)
    const chanceFloor = attacker.isPlayer ? hitChanceFloor.player : hitChanceFloor.enemy
    const chanceBase = attacker.isPlayer ? hitChanceBase.player : hitChanceBase.enemy
    const hitChance = clamp(chanceBase + focus * 0.32 + rangeRatio * 0.24 - target.damageState.stabilityLoss * 0.08, chanceFloor, 0.97)
    attacker.ammo -= 1
    attacker.weaponCooldownRemaining = attacker.aircraft.armament.fireCooldown
    const direction = offset.normalized
    this.events.push({ id: id(), time: this.missionTime, kind: 'shotFired', origin: attacker.position, direction })
    if (Math.random() <= hitChance) {
      const impactQuality = 0.5 + rangeRatio * 0.35 + focus * 0.3
      this.applyDamage(targetIndex, attacker.aircraft.armament.damagePerHit * impactQuality * (attacker.isPlayer ? 1.25 : 1))
    }
  }

  private bestTarget(attackerIndex: number, candidates: number[]): number | undefined {
    const attacker = this.combatants[attackerIndex]
    const validTargets = candidates.filter((candidateIndex) => {
      const target = this.combatants[candidateIndex]
      const offset = target.position.sub(attacker.position)
      const distance = offset.length
      if (distance > attacker.aircraft.armament.effectiveRange) return false
      return Vector3.dot(this.forward(attacker), offset.normalized) > 0.86
    })
    if (validTargets.length > 0) return validTargets.sort((lhs, rhs) => this.combatants[lhs].position.sub(attacker.position).length - this.combatants[rhs].position.sub(attacker.position).length)[0]
    if (!attacker.isPlayer) return undefined
    return candidates.filter((candidateIndex) => this.combatants[candidateIndex].position.sub(attacker.position).length <= attacker.aircraft.armament.effectiveRange * this.aimAssistMultiplier).sort((lhs, rhs) => this.combatants[lhs].position.sub(attacker.position).length - this.combatants[rhs].position.sub(attacker.position).length)[0]
  }

  private applyDamage(targetIndex: number, amount: number): void {
    const target = this.combatants[targetIndex]
    target.health = Math.max(0, target.health - amount)
    target.damageState.applyHit(amount / Math.max(target.aircraft.durability, 1))
    target.heading += (Math.random() - 0.5) * 0.14
    target.roll = clamp(target.roll + (Math.random() - 0.5) * 0.5, -1, 1)
    this.events.push({ id: id(), time: this.missionTime, kind: 'hit', targetID: target.id })
    if (target.health <= 0) this.events.push({ id: id(), time: this.missionTime, kind: 'destroyed', targetID: target.id })
  }

  /**
   * Interpolates heading toward a target heading while wrapping around ±π.
   */
  private steerHeading(current: number, desired: number, rate: number): number {
    const delta = Math.atan2(Math.sin(desired - current), Math.cos(desired - current))
    return current + delta * Math.min(Math.max(rate, 0), 1)
  }

  private evaluateMissionOutcome(): void {
    const player = this.player
    if (player.health <= 0) { this.outcome = 'failure'; return }
    if (player.fuelRemaining <= 0 && player.position.y < 8) { this.outcome = 'failure'; return }
    const allEnemiesDestroyed = this.combatants.filter((combatant) => !combatant.isPlayer).every((combatant) => combatant.health <= 0)
    const objectivesComplete = this.mission.objectives.every((objective) => {
      if (objective.type === 'destroyAllEnemies') return allEnemiesDestroyed
      if (objective.type === 'survive') return this.missionTime >= objective.seconds
      return this.missionTime >= objective.timeLimit && player.health > 0
    })
    if (objectivesComplete) { this.outcome = 'success'; return }
    if (this.missionTime >= this.mission.missionDuration) this.outcome = 'failure'
  }

  private objectiveLines(): string[] {
    return this.mission.objectives.map((objective) => {
      if (objective.type === 'destroyAllEnemies') return `Destroy enemy fighters — ${this.combatants.filter((combatant) => !combatant.isPlayer && combatant.health > 0).length} remaining`
      if (objective.type === 'survive') return `Hold the line for ${Math.max(0, Math.floor(objective.seconds - this.missionTime))} more seconds`
      return `Escort the fleet for ${Math.max(0, Math.floor(objective.timeLimit - this.missionTime))} more seconds`
    })
  }
}
