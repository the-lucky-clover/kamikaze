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
    public var weatherProfileID: String?
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
        weatherProfileID: String? = nil,
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
        self.weatherProfileID = weatherProfileID
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
        ),
        WeatherProfile(
            id: "moonlit_pacific",
            displayName: "Moonlit Pacific",
            visibility: 0.55,
            windIntensity: 0.3,
            stormIntensity: 0.15,
            cloudDensity: 0.25,
            oceanRoughness: 0.35,
            antiAircraftPressure: 0.6
        ),
        WeatherProfile(
            id: "iwo_jima_volcanic_haze",
            displayName: "Iwo Jima Volcanic Haze",
            visibility: 0.48,
            windIntensity: 0.55,
            stormIntensity: 0.45,
            cloudDensity: 0.65,
            oceanRoughness: 0.5,
            antiAircraftPressure: 0.78
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
        ),
        AircraftBlueprint(
            id: "f6f_hellcat",
            displayName: "F6F Hellcat",
            cruiseSpeed: 105,
            maxSpeed: 180,
            throttleResponse: 1.0,
            turnRate: 0.72,
            climbRate: 24,
            durability: 140,
            armament: Armament(ammoCapacity: 600, fireCooldown: 0.12, damagePerHit: 20, effectiveRange: 260),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "d4y_suisei",
            displayName: "D4Y Suisei",
            cruiseSpeed: 86,
            maxSpeed: 152,
            throttleResponse: 0.8,
            turnRate: 0.58,
            climbRate: 20,
            durability: 130,
            armament: Armament(ammoCapacity: 500, fireCooldown: 0.16, damagePerHit: 24, effectiveRange: 210),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "n1k2_shiden_kai",
            displayName: "N1K2 Shiden-Kai",
            cruiseSpeed: 94,
            maxSpeed: 172,
            throttleResponse: 0.98,
            turnRate: 0.88,
            climbRate: 24,
            durability: 108,
            armament: Armament(ammoCapacity: 400, fireCooldown: 0.13, damagePerHit: 18, effectiveRange: 235),
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
            id: "propaganda_and_indoctrination",
            title: "The Language of Duty",
            category: "Historical",
            unlockedByDefault: true,
            body: "State media in wartime Japan produced a specific kind of sentence: one that described necessity as honour, and honour as inevitability. Pilots who trained after 1943 learned the vocabulary of sacrifice before they learned to read an altimeter in low visibility. Survivors described receiving both kinds of instruction on the same day."
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
        ),
        ArchiveEntry(
            id: "leyte_naval_doctrine",
            title: "The Limits of Doctrine",
            category: "Doctrine",
            unlockedByDefault: false,
            body: "The Philippine Sea operations of 1944 exposed the limits of carrier doctrine built on earlier assumptions. Both sides improvised in real time, committing to engagements whose consequences could not be undone before the intelligence supporting them was obsolete."
        ),
        ArchiveEntry(
            id: "okinawa_civilian_toll",
            title: "Okinawa — The Other Count",
            category: "Archive",
            unlockedByDefault: false,
            body: "Okinawa was the first battle of the Pacific campaign fought on inhabited Japanese home-territory soil. Civilian casualties exceeded military ones. Families describe being given instructions by retreating soldiers that were not oriented toward survival."
        ),
        ArchiveEntry(
            id: "fuel_shortage_crisis",
            title: "Fuel and Its Absence",
            category: "Doctrine",
            unlockedByDefault: false,
            body: "By mid-1944 the Japanese fuel supply chain had fractured beyond recovery. Training programs shortened, sorties were rationed, and aircraft sat grounded while replacement parts were redistributed from theaters that were already losing. Pilots flew with less preparation on longer routes to targets they had fewer resources to reach."
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
            weatherProfileID: "golden_pacific",
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
        ),
        MissionDefinition(
            id: "leyte_gulf_intercept",
            title: "Leyte Gulf Reckoning",
            subtitle: "One carrier task force between the invasion fleet and the sea.",
            briefing: "October 1944. The Philippine Sea. The largest naval engagement in history is already committed. Intelligence is obsolete by the time it arrives. Your task force is positioned on the wrong side of a deteriorating weather front. Locate the incoming strike formation and break it before it reaches the fleet.",
            debrief: "Whatever survived returned without ceremony. The battle continued for three more days. The names were counted later.",
            recommendedAircraftID: "sbd_dauntless",
            missionDuration: 280,
            archiveRewardID: "training_collapse",
            aircraftRewardID: "f6f_hellcat",
            weatherProfileID: "late_war_squall",
            objectives: [.destroyAllEnemies, .survive(seconds: 120)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "sbd_dauntless",
                team: .player,
                position: Vector3(x: 0, y: 45, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0
            ),
            enemySpawns: [
                SpawnDefinition(id: "leyte_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -160, y: 58, z: -320), heading: 0.4, pitch: 0, cinematicIntroDelay: 3),
                SpawnDefinition(id: "leyte_wing_l", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 140, y: 55, z: -380), heading: -0.4, pitch: 0, cinematicIntroDelay: 6),
                SpawnDefinition(id: "leyte_wing_r", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -80, y: 50, z: -440), heading: 0.2, pitch: 0, cinematicIntroDelay: 9),
                SpawnDefinition(id: "leyte_tail", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 60, y: 60, z: -500), heading: -0.15, pitch: 0, cinematicIntroDelay: 14)
            ],
            cinematicBeats: [
                CinematicBeat(id: "leyte_launch", triggerTime: 1, title: "Philippine Sea, 1944", body: "The largest naval engagement in history is already committed. Fuel and positions now determine more than tactics."),
                CinematicBeat(id: "leyte_transit", triggerTime: 14, title: "Strike Transit", body: "Below, the Philippine Sea runs gray beneath overcast. Somewhere ahead, fleet wakes cross each other's paths."),
                CinematicBeat(id: "leyte_contact", triggerTime: 25, title: "Fleet Contact", body: "The task force silhouette is visible before it is identifiable. Every decision made here was made weeks ago, by people who are not here."),
                CinematicBeat(id: "leyte_attack", triggerTime: 40, title: "Attack Run", body: "The anti-aircraft pattern is a language that says the same thing every time."),
                CinematicBeat(id: "leyte_extract", triggerTime: 105, title: "Extract", body: "Whatever survives returns. That is the whole instruction.")
            ]
        ),
        MissionDefinition(
            id: "iwo_jima_scramble",
            title: "Iwo Jima Scramble",
            subtitle: "A volcanic island where the sky itself was hostile.",
            briefing: "February 1945. The volcanic plateau of Iwo Jima. The dust entered cockpit seals and fouled instruments. Mechanics worked in respirators when they had them. An incoming formation has been detected on radar. Scramble, intercept, and prevent the strike from reaching the airfield.",
            debrief: "The runway had been repaired twice this week. The mechanics did not stop for the debrief.",
            recommendedAircraftID: "f6f_hellcat",
            missionDuration: 220,
            archiveRewardID: "leyte_naval_doctrine",
            aircraftRewardID: "a6m_zero",
            weatherProfileID: "iwo_jima_volcanic_haze",
            objectives: [.destroyAllEnemies, .survive(seconds: 75)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "f6f_hellcat",
                team: .player,
                position: Vector3(x: 0, y: 50, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0
            ),
            enemySpawns: [
                SpawnDefinition(id: "iwo_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -100, y: 62, z: -300), heading: 0.3, pitch: 0, cinematicIntroDelay: 2),
                SpawnDefinition(id: "iwo_high", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 80, y: 72, z: -350), heading: -0.25, pitch: -0.05, cinematicIntroDelay: 5),
                SpawnDefinition(id: "iwo_low", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 20, y: 38, z: -390), heading: 0.15, pitch: 0.05, cinematicIntroDelay: 10)
            ],
            cinematicBeats: [
                CinematicBeat(id: "iwo_scramble", triggerTime: 1, title: "Sulfur Island", body: "The volcanic dust entered cockpit seals and fouled instruments. Mechanics worked in respirators when they had them."),
                CinematicBeat(id: "iwo_transit", triggerTime: 10, title: "Scramble Transit", body: "Below, black sand beaches. Above, a sky without color that the briefers had not mentioned."),
                CinematicBeat(id: "iwo_contact", triggerTime: 18, title: "Intercept", body: "The incoming formation was tighter than expected. Doctrine had not planned for this kind of pressure at this altitude."),
                CinematicBeat(id: "iwo_attack", triggerTime: 30, title: "Engagement", body: "Tracer fire in volcanic haze becomes a texture, not a warning."),
                CinematicBeat(id: "iwo_extract", triggerTime: 65, title: "Extract Under Fire", body: "The runway had been repaired twice this week. The third repair had not started.")
            ]
        ),
        MissionDefinition(
            id: "okinawa_dawn_patrol",
            title: "Okinawa Dawn",
            subtitle: "The last campaign before the home islands. The sky was never this full again.",
            briefing: "April 1945. The last island before Japan. The carrier screen defending the invasion fleet is the densest anti-aircraft network assembled in the Pacific theater. Five carriers, destroyer screens, and a CAP the size of a weather system. Navigate the typhoon wall and break the intercept pattern before the fleet takes another hit.",
            debrief: "The soldiers told the families that Okinawa would be defended at any cost. The families did not ask what the cost included.",
            recommendedAircraftID: "f6f_hellcat",
            missionDuration: 320,
            archiveRewardID: "okinawa_civilian_toll",
            aircraftRewardID: "d4y_suisei",
            weatherProfileID: "typhoon_wall",
            objectives: [.destroyAllEnemies, .survive(seconds: 150)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "f6f_hellcat",
                team: .player,
                position: Vector3(x: 0, y: 48, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0
            ),
            enemySpawns: [
                SpawnDefinition(id: "oki_lead", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: -180, y: 60, z: -280), heading: 0.45, pitch: 0, cinematicIntroDelay: 3),
                SpawnDefinition(id: "oki_wing_l", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: 160, y: 54, z: -340), heading: -0.45, pitch: 0, cinematicIntroDelay: 5),
                SpawnDefinition(id: "oki_wing_r", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -60, y: 68, z: -400), heading: 0.2, pitch: 0, cinematicIntroDelay: 8),
                SpawnDefinition(id: "oki_high", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: 100, y: 75, z: -460), heading: -0.1, pitch: -0.06, cinematicIntroDelay: 11),
                SpawnDefinition(id: "oki_tail", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -30, y: 44, z: -520), heading: 0.05, pitch: 0, cinematicIntroDelay: 15)
            ],
            cinematicBeats: [
                CinematicBeat(id: "oki_briefing", triggerTime: 1, title: "The Last Island Before Home", body: "The soldiers told the families that Okinawa would be defended at any cost. The families did not ask what the cost included."),
                CinematicBeat(id: "oki_transit", triggerTime: 16, title: "Dawn Over the China Sea", body: "At altitude, the storm front looks like a decision that has already been made. Below it, the fleet waits."),
                CinematicBeat(id: "oki_contact", triggerTime: 28, title: "Fleet Contact — Okinawa", body: "Five carriers, destroyer screens, and a CAP density that suggests someone has read the after-action reports from every previous engagement."),
                CinematicBeat(id: "oki_attack", triggerTime: 45, title: "Attack Run Into the Wall", body: "The anti-aircraft curtain at Okinawa was the densest recorded in the Pacific theater. It shows."),
                CinematicBeat(id: "oki_extract", triggerTime: 135, title: "Breaking Off", body: "Survival at Okinawa was not celebrated. There was too much to count.")
            ]
        ),
        MissionDefinition(
            id: "kyushu_last_sortie",
            title: "Kyushu, Last Sortie",
            subtitle: "Fuel for one mission. No word from command.",
            briefing: "Summer 1945. Kyushu, the southernmost home island. The pilots grew up an hour from these runways. The mission brief does not include a return window. Fuel was calculated for the intercept only. A carrier task force has been sighted in the approaches. This is the final operational sortie from this airfield.",
            debrief: "The word 'last' had appeared in the briefing seven times. After the mission, no one counted how many times it had been accurate.",
            recommendedAircraftID: "n1k2_shiden_kai",
            missionDuration: 360,
            archiveRewardID: "fuel_shortage_crisis",
            aircraftRewardID: "n1k2_shiden_kai",
            weatherProfileID: "late_war_squall",
            objectives: [.destroyAllEnemies, .survive(seconds: 180)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "n1k2_shiden_kai",
                team: .player,
                position: Vector3(x: 0, y: 52, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0
            ),
            enemySpawns: [
                SpawnDefinition(id: "kyu_lead", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: -200, y: 65, z: -260), heading: 0.5, pitch: 0, cinematicIntroDelay: 2),
                SpawnDefinition(id: "kyu_wing_l", aircraftID: "f6f_hellcat", team: .enemy, position: Vector3(x: 180, y: 58, z: -310), heading: -0.5, pitch: 0, cinematicIntroDelay: 4),
                SpawnDefinition(id: "kyu_wing_r", aircraftID: "f6f_hellcat", team: .enemy, position: Vector3(x: -120, y: 72, z: -370), heading: 0.3, pitch: 0, cinematicIntroDelay: 7),
                SpawnDefinition(id: "kyu_high", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: 80, y: 80, z: -430), heading: -0.2, pitch: -0.05, cinematicIntroDelay: 10),
                SpawnDefinition(id: "kyu_mid", aircraftID: "f6f_hellcat", team: .enemy, position: Vector3(x: -40, y: 56, z: -490), heading: 0.1, pitch: 0, cinematicIntroDelay: 13),
                SpawnDefinition(id: "kyu_tail", aircraftID: "n1k2_shiden_kai", team: .enemy, position: Vector3(x: 30, y: 62, z: -550), heading: -0.05, pitch: 0, cinematicIntroDelay: 18)
            ],
            cinematicBeats: [
                CinematicBeat(id: "kyu_briefing", triggerTime: 1, title: "Home Territory", body: "Kyushu is not a foreign island. The pilots grew up an hour from these runways. The word 'last' appears in the briefing seven times."),
                CinematicBeat(id: "kyu_transit", triggerTime: 18, title: "Final Transit", body: "Below, the Inland Sea. Rice fields visible between cloud breaks. The mission brief did not include a return window."),
                CinematicBeat(id: "kyu_contact", triggerTime: 32, title: "Task Force Contact", body: "The final carrier screen is fully committed. Return fuel was not calculated because it was not part of the operational logic."),
                CinematicBeat(id: "kyu_attack", triggerTime: 55, title: "Last Attack Run", body: "Six aircraft in the intercept screen. This is what remaining resources look like."),
                CinematicBeat(id: "kyu_after", triggerTime: 165, title: "Whatever Comes After", body: "The debrief, if there is one, will use the word 'maximum' where it means something else.")
            ]
        )
    ]
}
