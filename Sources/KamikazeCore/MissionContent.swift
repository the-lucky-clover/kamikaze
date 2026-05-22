import Foundation

public enum Team: String, Codable, Sendable {
    case player
    case enemy
}

public struct Armament: Codable, Sendable, Equatable {
    public var ammoCapacity: Int
    public var fireCooldown: Double
    public var damagePerHit: Double
    public var effectiveRange: Double

    public init(ammoCapacity: Int, fireCooldown: Double, damagePerHit: Double, effectiveRange: Double) {
        self.ammoCapacity = ammoCapacity
        self.fireCooldown = fireCooldown
        self.damagePerHit = damagePerHit
        self.effectiveRange = effectiveRange
    }
}

public struct AircraftBlueprint: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var cruiseSpeed: Double
    public var maxSpeed: Double
    public var throttleResponse: Double
    public var turnRate: Double
    public var climbRate: Double
    public var durability: Double
    public var armament: Armament
    public var unlockedByDefault: Bool

    public init(
        id: String,
        displayName: String,
        cruiseSpeed: Double,
        maxSpeed: Double,
        throttleResponse: Double,
        turnRate: Double,
        climbRate: Double,
        durability: Double,
        armament: Armament,
        unlockedByDefault: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.cruiseSpeed = cruiseSpeed
        self.maxSpeed = maxSpeed
        self.throttleResponse = throttleResponse
        self.turnRate = turnRate
        self.climbRate = climbRate
        self.durability = durability
        self.armament = armament
        self.unlockedByDefault = unlockedByDefault
    }
}

public struct SpawnDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var aircraftID: String
    public var team: Team
    public var position: Vector3
    public var heading: Double
    public var pitch: Double
    public var cinematicIntroDelay: Double

    public init(id: String, aircraftID: String, team: Team, position: Vector3, heading: Double, pitch: Double, cinematicIntroDelay: Double = 0) {
        self.id = id
        self.aircraftID = aircraftID
        self.team = team
        self.position = position
        self.heading = heading
        self.pitch = pitch
        self.cinematicIntroDelay = cinematicIntroDelay
    }
}

public enum ObjectiveDefinition: Codable, Sendable, Equatable {
    case destroyAllEnemies
    case survive(seconds: Double)
    case escort(timeLimit: Double)

    private enum CodingKeys: String, CodingKey {
        case type
        case seconds
        case timeLimit
    }

    private enum Kind: String, Codable {
        case destroyAllEnemies
        case survive
        case escort
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .destroyAllEnemies:
            self = .destroyAllEnemies
        case .survive:
            self = .survive(seconds: try container.decode(Double.self, forKey: .seconds))
        case .escort:
            self = .escort(timeLimit: try container.decode(Double.self, forKey: .timeLimit))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .destroyAllEnemies:
            try container.encode(Kind.destroyAllEnemies, forKey: .type)
        case let .survive(seconds):
            try container.encode(Kind.survive, forKey: .type)
            try container.encode(seconds, forKey: .seconds)
        case let .escort(timeLimit):
            try container.encode(Kind.escort, forKey: .type)
            try container.encode(timeLimit, forKey: .timeLimit)
        }
    }
}

public struct CinematicBeat: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var triggerTime: Double
    public var title: String
    public var body: String

    public init(id: String, triggerTime: Double, title: String, body: String) {
        self.id = id
        self.triggerTime = triggerTime
        self.title = title
        self.body = body
    }
}

public struct MissionDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var briefing: String
    public var debrief: String
    public var recommendedAircraftID: String
    public var missionDuration: Double
    public var archiveRewardID: String
    public var aircraftRewardID: String?
    public var objectives: [ObjectiveDefinition]
    public var playerSpawn: SpawnDefinition
    public var enemySpawns: [SpawnDefinition]
    public var cinematicBeats: [CinematicBeat]

    public init(
        id: String,
        title: String,
        subtitle: String,
        briefing: String,
        debrief: String,
        recommendedAircraftID: String,
        missionDuration: Double,
        archiveRewardID: String,
        aircraftRewardID: String? = nil,
        objectives: [ObjectiveDefinition],
        playerSpawn: SpawnDefinition,
        enemySpawns: [SpawnDefinition],
        cinematicBeats: [CinematicBeat]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.briefing = briefing
        self.debrief = debrief
        self.recommendedAircraftID = recommendedAircraftID
        self.missionDuration = missionDuration
        self.archiveRewardID = archiveRewardID
        self.aircraftRewardID = aircraftRewardID
        self.objectives = objectives
        self.playerSpawn = playerSpawn
        self.enemySpawns = enemySpawns
        self.cinematicBeats = cinematicBeats
    }
}

public struct ArchiveEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var category: String
    public var unlockedByDefault: Bool
    public var body: String

    public init(id: String, title: String, category: String, unlockedByDefault: Bool, body: String) {
        self.id = id
        self.title = title
        self.category = category
        self.unlockedByDefault = unlockedByDefault
        self.body = body
    }
}

public enum ContentLibrary {
    public static let weather: [WeatherProfile] = [
        WeatherProfile(
            id: "golden_pacific",
            displayName: "Golden Pacific",
            visibility: 0.9,
            windIntensity: 0.2,
            stormIntensity: 0.1,
            cloudDensity: 0.3,
            oceanRoughness: 0.22,
            antiAircraftPressure: 0.35
        ),
        WeatherProfile(
            id: "late_war_squall",
            displayName: "Late-War Squall",
            visibility: 0.42,
            windIntensity: 0.75,
            stormIntensity: 0.84,
            cloudDensity: 0.9,
            oceanRoughness: 0.8,
            antiAircraftPressure: 0.82
        ),
        WeatherProfile(
            id: "typhoon_wall",
            displayName: "Typhoon Wall",
            visibility: 0.2,
            windIntensity: 0.95,
            stormIntensity: 1.0,
            cloudDensity: 1.0,
            oceanRoughness: 1.0,
            antiAircraftPressure: 0.9
        )
    ]

    public static let aircraft: [AircraftBlueprint] = [
        AircraftBlueprint(
            id: "f4f_wildcat",
            displayName: "F4F Wildcat",
            cruiseSpeed: 90,
            maxSpeed: 155,
            throttleResponse: 0.95,
            turnRate: 0.8,
            climbRate: 22,
            durability: 120,
            armament: Armament(ammoCapacity: 480, fireCooldown: 0.15, damagePerHit: 18, effectiveRange: 240),
            unlockedByDefault: true
        ),
        AircraftBlueprint(
            id: "sbd_dauntless",
            displayName: "SBD Dauntless",
            cruiseSpeed: 80,
            maxSpeed: 145,
            throttleResponse: 0.75,
            turnRate: 0.62,
            climbRate: 18,
            durability: 155,
            armament: Armament(ammoCapacity: 540, fireCooldown: 0.18, damagePerHit: 22, effectiveRange: 220),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "a6m_zero",
            displayName: "A6M Zero",
            cruiseSpeed: 98,
            maxSpeed: 165,
            throttleResponse: 1.05,
            turnRate: 0.92,
            climbRate: 26,
            durability: 100,
            armament: Armament(ammoCapacity: 420, fireCooldown: 0.14, damagePerHit: 16, effectiveRange: 230),
            unlockedByDefault: false
        )
    ]

    public static let archive: [ArchiveEntry] = [
        ArchiveEntry(
            id: "prologue_memorial",
            title: "Roll Call at Dawn",
            category: "Memorial",
            unlockedByDefault: true,
            body: "A wall of names appears before every sortie. It is not a scoreboard. It is a reminder that every aircraft in the sky once held a living person whose future narrowed to orders, weather, and fear."
        ),
        ArchiveEntry(
            id: "midway_letters",
            title: "Letters Never Posted",
            category: "Archive",
            unlockedByDefault: false,
            body: "Recovered fragments describe exhaustion, fuel anxiety, mechanical fragility, and shame rather than heroics. The archive unlock is meant to complicate the mission, not celebrate it."
        ),
        ArchiveEntry(
            id: "training_collapse",
            title: "Pilot Training Collapse",
            category: "Doctrine",
            unlockedByDefault: false,
            body: "Late-war pilot preparation compressed dramatically as experienced personnel vanished. Diaries and reports describe shorter instruction cycles, thinner maintenance margins, and a deadlier relationship between weather and inexperience."
        )
    ]

    public static let missions: [MissionDefinition] = [
        MissionDefinition(
            id: "embers_over_midway",
            title: "Embers Over Midway",
            subtitle: "Hold the dawn long enough for the fleet to breathe.",
            briefing: "Airfield preparation rolls into launch. From the deck edge and carrier wake, climb into a long transit, locate the fleet screen, break the incoming fighters, then survive the return over a storm-darkening Pacific.",
            debrief: "The sea keeps no victory parade. Only wake lines, names, and the silence after engines stop.",
            recommendedAircraftID: "f4f_wildcat",
            missionDuration: 240,
            archiveRewardID: "midway_letters",
            aircraftRewardID: "sbd_dauntless",
            objectives: [.destroyAllEnemies, .survive(seconds: 90)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "f4f_wildcat",
                team: .player,
                position: Vector3(x: 0, y: 40, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0
            ),
            enemySpawns: [
                SpawnDefinition(id: "zero_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -120, y: 55, z: -360), heading: 0.35, pitch: 0, cinematicIntroDelay: 4),
                SpawnDefinition(id: "zero_wing", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 90, y: 52, z: -400), heading: -0.35, pitch: 0, cinematicIntroDelay: 7),
                SpawnDefinition(id: "zero_tail", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 48, z: -460), heading: 0.1, pitch: 0, cinematicIntroDelay: 12)
            ],
            cinematicBeats: [
                CinematicBeat(id: "airfield_prep", triggerTime: 1, title: "Airfield Preparation", body: "Crew chiefs wave through salt wind and oil fumes. Nobody mistakes the ritual for safety."),
                CinematicBeat(id: "transit", triggerTime: 12, title: "Long Transit", body: "The ocean below is beautiful enough to make the mission feel obscene."),
                CinematicBeat(id: "fleet_discovery", triggerTime: 22, title: "Fleet Discovery", body: "Carrier wakes bloom through the glare. Somewhere beyond them, more young pilots are already committed."),
                CinematicBeat(id: "attack_run", triggerTime: 36, title: "Attack Run", body: "Every tracer line is a sentence that can never be unsaid."),
                CinematicBeat(id: "escape", triggerTime: 85, title: "Escape or Death", body: "If the engine holds and the weather relents, point home before memory arrives.")
            ]
        )
    ]
}
