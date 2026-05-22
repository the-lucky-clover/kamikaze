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
            body: "A wall of names appears before every sortie. It is not a scoreboard. It is a reminder that every machine in the sky was built to carry a living person toward someone else's grief."
        ),
        ArchiveEntry(
            id: "midway_letters",
            title: "Letters Never Posted",
            category: "Archive",
            unlockedByDefault: false,
            body: "Recovered fragments describe fear of the ocean below more than fear of the enemy ahead. The mission reward is not glory; it is a chance to read what war interrupted."
        )
    ]

    public static let missions: [MissionDefinition] = [
        MissionDefinition(
            id: "embers_over_midway",
            title: "Embers Over Midway",
            subtitle: "Hold the dawn long enough for the fleet to breathe.",
            briefing: "A strike group is approaching through the stormlight. Intercept the fighters threatening the carrier screen, then guide yourself home before the ocean takes back the horizon.",
            debrief: "The sea keeps no victory parades. Only the names you brought back, and the names you could not.",
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
                SpawnDefinition(id: "zero_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -120, y: 55, z: -360), heading: 0.2, pitch: 0, cinematicIntroDelay: 4),
                SpawnDefinition(id: "zero_wing", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 90, y: 52, z: -400), heading: -0.2, pitch: 0, cinematicIntroDelay: 7),
                SpawnDefinition(id: "zero_tail", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 48, z: -460), heading: 0.05, pitch: 0, cinematicIntroDelay: 12)
            ],
            cinematicBeats: [
                CinematicBeat(id: "brief_intro", triggerTime: 1, title: "Pacific Morning", body: "Cloud light breaks across the carrier decks. Somewhere beyond the glare, more young pilots are flying toward the same sunrise."),
                CinematicBeat(id: "combat_note", triggerTime: 22, title: "Elegy in the Dive", body: "Every tracer line is a sentence that can never be unsaid."),
                CinematicBeat(id: "return_home", triggerTime: 85, title: "Come Back Alive", body: "Hold formation with the fleet wake and let the engines cool before memory catches up.")
            ]
        )
    ]
}
