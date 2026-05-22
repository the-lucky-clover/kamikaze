import Foundation

public enum Team: String, Codable, Sendable {
    case player
    case enemy
}

public enum EnvironmentTone: String, Codable, Sendable {
    case earlyWar
    case lateWar
}

public enum AIRole: String, Codable, Sendable {
    case intercept
    case patrol
    case formationWing
    case retreat
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

public struct NavalAAEmitter: Codable, Sendable, Equatable {
    public var position: Vector3
    public var range: Double
    public var fireRate: Double
    public var damagePerRound: Double

    public init(position: Vector3, range: Double, fireRate: Double, damagePerRound: Double) {
        self.position = position
        self.range = range
        self.fireRate = fireRate
        self.damagePerRound = damagePerRound
    }
}

public enum UpgradeEffectType: String, Codable, Sendable {
    case fuelLeakReduction
    case steeringAuthority
    case engineCeiling
    case stabilityDamping
    case aimAssist
}

public struct UpgradeDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var effectType: UpgradeEffectType
    public var magnitude: Double

    public init(id: String, displayName: String, effectType: UpgradeEffectType, magnitude: Double) {
        self.id = id
        self.displayName = displayName
        self.effectType = effectType
        self.magnitude = magnitude
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
    public var aiRole: AIRole

    public init(
        id: String,
        aircraftID: String,
        team: Team,
        position: Vector3,
        heading: Double,
        pitch: Double,
        cinematicIntroDelay: Double = 0,
        aiRole: AIRole = .intercept
    ) {
        self.id = id
        self.aircraftID = aircraftID
        self.team = team
        self.position = position
        self.heading = heading
        self.pitch = pitch
        self.cinematicIntroDelay = cinematicIntroDelay
        self.aiRole = aiRole
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
    public var weatherProfileID: String
    public var environmentTone: EnvironmentTone
    public var upgradeRewardID: String?
    public var objectives: [ObjectiveDefinition]
    public var playerSpawn: SpawnDefinition
    public var enemySpawns: [SpawnDefinition]
    public var cinematicBeats: [CinematicBeat]
    public var navalAAEmitters: [NavalAAEmitter]

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
        weatherProfileID: String = "golden_pacific",
        environmentTone: EnvironmentTone = .earlyWar,
        upgradeRewardID: String? = nil,
        objectives: [ObjectiveDefinition],
        playerSpawn: SpawnDefinition,
        enemySpawns: [SpawnDefinition],
        cinematicBeats: [CinematicBeat],
        navalAAEmitters: [NavalAAEmitter] = []
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
        self.environmentTone = environmentTone
        self.upgradeRewardID = upgradeRewardID
        self.objectives = objectives
        self.playerSpawn = playerSpawn
        self.enemySpawns = enemySpawns
        self.cinematicBeats = cinematicBeats
        self.navalAAEmitters = navalAAEmitters
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

    public static let upgrades: [UpgradeDefinition] = [
        UpgradeDefinition(id: "navigation_charts", displayName: "Better Navigation Charts", effectType: .steeringAuthority, magnitude: 0.12),
        UpgradeDefinition(id: "engine_tuning", displayName: "Improved Engine Tuning", effectType: .engineCeiling, magnitude: 0.15),
        UpgradeDefinition(id: "fuel_seals", displayName: "Reduced Fuel Leakage", effectType: .fuelLeakReduction, magnitude: 0.40),
        UpgradeDefinition(id: "reinforced_cables", displayName: "Reinforced Control Cables", effectType: .steeringAuthority, magnitude: 0.18),
        UpgradeDefinition(id: "better_optics", displayName: "Better Optics", effectType: .aimAssist, magnitude: 0.25),
        UpgradeDefinition(id: "pilot_stamina", displayName: "Improved Pilot Stamina", effectType: .stabilityDamping, magnitude: 0.20),
        UpgradeDefinition(id: "weather_tools", displayName: "Weather Prediction Tools", effectType: .stabilityDamping, magnitude: 0.15),
        UpgradeDefinition(id: "radio_clarity", displayName: "Radio Clarity Upgrades", effectType: .aimAssist, magnitude: 0.15)
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
            id: "n1k2j_shinden",
            displayName: "N1K2-J Shinden-Kai",
            cruiseSpeed: 102,
            maxSpeed: 172,
            throttleResponse: 1.10,
            turnRate: 0.95,
            climbRate: 28,
            durability: 95,
            armament: Armament(ammoCapacity: 360, fireCooldown: 0.13, damagePerHit: 17, effectiveRange: 225),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "ki84_hayate",
            displayName: "Ki-84 Hayate",
            cruiseSpeed: 106,
            maxSpeed: 178,
            throttleResponse: 0.85,
            turnRate: 0.75,
            climbRate: 30,
            durability: 135,
            armament: Armament(ammoCapacity: 400, fireCooldown: 0.16, damagePerHit: 24, effectiveRange: 245),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "f6f_hellcat",
            displayName: "F6F Hellcat",
            cruiseSpeed: 95,
            maxSpeed: 163,
            throttleResponse: 0.88,
            turnRate: 0.72,
            climbRate: 25,
            durability: 160,
            armament: Armament(ammoCapacity: 520, fireCooldown: 0.14, damagePerHit: 20, effectiveRange: 255),
            unlockedByDefault: false
        ),
        AircraftBlueprint(
            id: "f4u_corsair",
            displayName: "F4U Corsair",
            cruiseSpeed: 105,
            maxSpeed: 180,
            throttleResponse: 0.90,
            turnRate: 0.68,
            climbRate: 32,
            durability: 145,
            armament: Armament(ammoCapacity: 460, fireCooldown: 0.15, damagePerHit: 22, effectiveRange: 260),
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
        ArchiveEntry(id: "indoctrination_system", title: "The Indoctrination System", category: "Doctrine", unlockedByDefault: false, body: "Wartime education in Japan increasingly merged patriotism with personal sacrifice. By 1944, school curricula, newspapers, and military culture created a framework in which individual survival was framed as selfishness. Historians have documented the pressure this placed on young pilots — not simply to die, but to internalize their death as meaningful."),
        ArchiveEntry(id: "wartime_propaganda", title: "Wartime Propaganda Machinery", category: "History", unlockedByDefault: false, body: "Both sides of the Pacific War employed propaganda to sustain civilian and military morale. Japanese wartime media typically portrayed sacrifice as noble, defeat as temporary, and the enemy as barbaric. Allied reporting returned the pattern. What survives are the pamphlets, the newsreels, and the silence of the people who saw through them."),
        ArchiveEntry(id: "fuel_crisis_1944", title: "The Fuel Crisis of 1944", category: "Logistics", unlockedByDefault: false, body: "By late 1944, Japan's fuel supply chain had fractured under Allied submarine and air pressure. Training flights were shortened. Ferry missions cancelled. Combat aircraft arrived at forward bases with less fuel than their planned return routes required. This is why some missions were one-way before they were ever labelled as such."),
        ArchiveEntry(id: "leyte_gulf_doctrine", title: "Leyte Gulf: Naval Doctrine and Desperation", category: "History", unlockedByDefault: false, body: "The Battle of Leyte Gulf in October 1944 was the largest naval battle in history by tonnage engaged. Japanese planners threw multiple fleets into a coordinated decoy-and-strike maneuver that came within hours of succeeding. It failed. The loss of carrier air cover accelerated the strategic desperation that followed."),
        ArchiveEntry(id: "iwo_jima_letters", title: "Iwo Jima: Voices from the Ash", category: "Archive", unlockedByDefault: false, body: "Correspondence recovered from Iwo Jima describes volcanic heat, water shortages, and the psychological weight of a battle both sides knew would be decisive. Marines and Japanese defenders wrote home with the same cadence: they missed ordinary things. Both sides stopped receiving replies at about the same point in the campaign."),
        ArchiveEntry(id: "okinawa_ten_go_record", title: "Okinawa: Ten-Go and the Civilian Dimension", category: "History", unlockedByDefault: false, body: "Operation Ten-Go committed the battleship Yamato and a surface force to a one-way attack on Allied invasion fleets. Simultaneously, Okinawa's civilian population was caught between two military machines. Civilian casualties exceeded military deaths on the island. The battle lasted three months and is considered among the Pacific War's most devastating engagements for all parties."),
        ArchiveEntry(id: "military_censorship", title: "Wartime Censorship and Memory", category: "Doctrine", unlockedByDefault: false, body: "Wartime censorship shaped what soldiers, civilians, and historians knew about the conflict as it happened. Japanese censors suppressed casualty figures, defeat accounts, and anti-war sentiment. The result was a population prosecuting a war they were not allowed to understand. Postwar historians spent decades reconstructing what was withheld."),
        ArchiveEntry(id: "pilot_diaries_fragment", title: "A Pilot's Diary Fragment", category: "Archive", unlockedByDefault: false, body: "A fragment from a training diary, early 1945: 'Practiced carrier approaches again today. Engine cut twice on approach. The instructor said not to worry — that we would not be making many carrier approaches. I did not understand what he meant until the next morning's briefing.' The diary ends there."),
        ArchiveEntry(id: "infrastructure_collapse", title: "The Collapse of Wartime Infrastructure", category: "Logistics", unlockedByDefault: false, body: "By early 1945, Japan's military-industrial base had fractured severely. Aircraft factories ran below thirty percent capacity. Spare parts for frontline aircraft were diverted from training programs. Mechanics worked on aircraft they knew would not return. Maintenance logs from this period are sparse — not because nothing was recorded, but because there was less and less to record."),
        ArchiveEntry(id: "postwar_memory", title: "Postwar Memory Debates", category: "Memorial", unlockedByDefault: false, body: "How the Pacific War is remembered differs sharply across national contexts. In Japan, public commemoration of the conflict has been shaped by constitutional pacifism, political controversy, and genuine grief. In the United States, the war is frequently framed through the lens of strategic necessity. In Okinawa, it is remembered as a catastrophe in which the island's people were abandoned by both sides. All three framings contain truth. None is complete."),
        ArchiveEntry(id: "tokko_historical", title: "Tokko: Historical and Ethical Context", category: "Memorial", unlockedByDefault: false, body: "This game does not glorify tokko (special attack) operations. It represents the historical desperation, coercion, and human cost of a military system that ran out of options and substituted human lives for strategy. The pilots who flew these missions included people who volunteered, people who felt they could not refuse, and people who were assigned without being asked. The archive exists to hold that complexity without resolving it."),
        ArchiveEntry(id: "carrier_losses_record", title: "Carrier Losses: The Statistical Record", category: "History", unlockedByDefault: false, body: "The Imperial Japanese Navy entered the war with ten fleet carriers. By the end of 1944, effective carrier aviation had ceased to exist as an offensive capability. Trained pilots — a resource that takes years to build — were largely gone. The navy that had struck Pearl Harbor and dominated the early Pacific was, by any operational measure, a different institution by the time of Leyte Gulf."),
        ArchiveEntry(id: "education_framing", title: "A Note on Educational Framing", category: "Memorial", unlockedByDefault: true, body: "This game reconstructs historical events with care for factual grounding and ethical responsibility. It does not endorse imperial nationalism, militarism, or any form of political extremism. Combat gameplay is a vehicle for empathy and reflection — not celebration. All archival material has been written to support understanding, not glorification. The game is dedicated to everyone the war consumed, on every side."),
        ArchiveEntry(id: "pacific_war_close", title: "The Pacific War: Final Days", category: "History", unlockedByDefault: false, body: "The Pacific War ended in August 1945 following the atomic bombings of Hiroshima and Nagasaki and the Soviet declaration of war against Japan. The formal surrender took place on September 2, 1945 aboard USS Missouri. By that point, Japan had lost approximately three million military personnel and an estimated 800,000 civilians. The United States lost approximately 420,000 total. The numbers do not convey the texture of individual lives."),
        ArchiveEntry(id: "memorial_dedication", title: "Memorial Dedication", category: "Memorial", unlockedByDefault: true, body: "To the people who did not choose the war they were handed. To the families who waited. To the historians who spent careers trying to understand it. To the survivors who could not stop seeing it. This game was made with respect for all of them.")
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
            environmentTone: .earlyWar,
            upgradeRewardID: nil,
            objectives: [.destroyAllEnemies, .survive(seconds: 90)],
            playerSpawn: SpawnDefinition(
                id: "player",
                aircraftID: "f4f_wildcat",
                team: .player,
                position: Vector3(x: 0, y: 40, z: 0),
                heading: 0,
                pitch: 0,
                cinematicIntroDelay: 0,
                aiRole: .intercept
            ),
            enemySpawns: [
                SpawnDefinition(id: "zero_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -120, y: 55, z: -360), heading: 0.35, pitch: 0, cinematicIntroDelay: 4, aiRole: .intercept),
                SpawnDefinition(id: "zero_wing", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 90, y: 52, z: -400), heading: -0.35, pitch: 0, cinematicIntroDelay: 7, aiRole: .intercept),
                SpawnDefinition(id: "zero_tail", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 48, z: -460), heading: 0.1, pitch: 0, cinematicIntroDelay: 12, aiRole: .intercept)
            ],
            cinematicBeats: [
                CinematicBeat(id: "airfield_prep", triggerTime: 1, title: "Airfield Preparation", body: "Crew chiefs wave through salt wind and oil fumes. Nobody mistakes the ritual for safety."),
                CinematicBeat(id: "transit", triggerTime: 12, title: "Long Transit", body: "The ocean below is beautiful enough to make the mission feel obscene."),
                CinematicBeat(id: "fleet_discovery", triggerTime: 22, title: "Fleet Discovery", body: "Carrier wakes bloom through the glare. Somewhere beyond them, more young pilots are already committed."),
                CinematicBeat(id: "attack_run", triggerTime: 36, title: "Attack Run", body: "Every tracer line is a sentence that can never be unsaid."),
                CinematicBeat(id: "escape", triggerTime: 85, title: "Escape or Death", body: "If the engine holds and the weather relents, point home before memory arrives.")
            ],
            navalAAEmitters: []
        ),
        MissionDefinition(
            id: "leyte_gulf_dusk",
            title: "Leyte Gulf — Dusk Over the Sibuyan Sea",
            subtitle: "Hold the convoy line until the fleet can breathe again.",
            briefing: "A resupply convoy threads the Sibuyan Sea under fading light. Enemy air cover is light but persistent. Escort the column long enough for it to reach the straits.",
            debrief: "The convoy moved. Not everyone who escorted it came back with them.",
            recommendedAircraftID: "f6f_hellcat",
            missionDuration: 280,
            archiveRewardID: "leyte_gulf_doctrine",
            aircraftRewardID: "n1k2j_shinden",
            weatherProfileID: "golden_pacific",
            environmentTone: .earlyWar,
            upgradeRewardID: "navigation_charts",
            objectives: [.escort(timeLimit: 150), .survive(seconds: 120)],
            playerSpawn: SpawnDefinition(id: "player", aircraftID: "f6f_hellcat", team: .player, position: Vector3(x: 0, y: 38, z: 0), heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: .intercept),
            enemySpawns: [
                SpawnDefinition(id: "patrol_a", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -180, y: 50, z: -300), heading: 0.4, pitch: 0, cinematicIntroDelay: 5, aiRole: .patrol),
                SpawnDefinition(id: "patrol_b", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 160, y: 48, z: -340), heading: -0.4, pitch: 0, cinematicIntroDelay: 8, aiRole: .patrol),
                SpawnDefinition(id: "intercept_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 55, z: -420), heading: 0.2, pitch: 0, cinematicIntroDelay: 14, aiRole: .intercept)
            ],
            cinematicBeats: [
                CinematicBeat(id: "convoy_prep", triggerTime: 1, title: "Convoy Assembly", body: "Supply ships form lines across the Sibuyan before first light. The formations feel too optimistic for 1944."),
                CinematicBeat(id: "enemy_contact", triggerTime: 16, title: "Enemy Contact", body: "Zeros fall from cloud cover. They were not unexpected."),
                CinematicBeat(id: "fleet_pressure", triggerTime: 45, title: "Fleet Under Fire", body: "The AA guns below are firing at everything, including instinct."),
                CinematicBeat(id: "holding_pattern", triggerTime: 90, title: "Holding On", body: "Each minute of escort is a minute the column is still moving."),
                CinematicBeat(id: "dusk_closing", triggerTime: 140, title: "Dusk Closing", body: "The light is leaving the water. The mission does not end when the light does.")
            ],
            navalAAEmitters: [
                NavalAAEmitter(position: Vector3(x: 300, y: 0, z: -500), range: 280, fireRate: 0.6, damagePerRound: 6),
                NavalAAEmitter(position: Vector3(x: -320, y: 0, z: -480), range: 280, fireRate: 0.6, damagePerRound: 6)
            ]
        ),
        MissionDefinition(
            id: "iwo_jima_ash",
            title: "Iwo Jima — Ash Horizon",
            subtitle: "Break the air screen before the grey swallows everything.",
            briefing: "A late-war squall is rolling in off the Pacific. Enemy fighters are holding a defensive perimeter over the volcanic ash fields. Your fuel load is tight. Do not dwell.",
            debrief: "The ash fields kept no record of what crossed them. Only the weather remembered anything.",
            recommendedAircraftID: "f4u_corsair",
            missionDuration: 260,
            archiveRewardID: "iwo_jima_letters",
            aircraftRewardID: "ki84_hayate",
            weatherProfileID: "late_war_squall",
            environmentTone: .lateWar,
            upgradeRewardID: "engine_tuning",
            objectives: [.destroyAllEnemies, .survive(seconds: 100)],
            playerSpawn: SpawnDefinition(id: "player", aircraftID: "f4u_corsair", team: .player, position: Vector3(x: 0, y: 42, z: 0), heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: .intercept),
            enemySpawns: [
                SpawnDefinition(id: "ash_lead", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -130, y: 58, z: -350), heading: 0.3, pitch: 0, cinematicIntroDelay: 5, aiRole: .intercept),
                SpawnDefinition(id: "ash_wing_a", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 100, y: 54, z: -390), heading: -0.3, pitch: 0, cinematicIntroDelay: 7, aiRole: .formationWing),
                SpawnDefinition(id: "ash_wing_b", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 52, z: -430), heading: 0.1, pitch: 0, cinematicIntroDelay: 9, aiRole: .formationWing),
                SpawnDefinition(id: "ash_high", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: -60, y: 72, z: -380), heading: 0.15, pitch: 0, cinematicIntroDelay: 13, aiRole: .intercept),
                SpawnDefinition(id: "ash_reserve", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 180, y: 50, z: -460), heading: -0.2, pitch: 0, cinematicIntroDelay: 18, aiRole: .patrol)
            ],
            cinematicBeats: [
                CinematicBeat(id: "ash_launch", triggerTime: 1, title: "Ash Fields Below", body: "The island is grey under volcanic dust. Nothing about this place looks survivable."),
                CinematicBeat(id: "squall_front", triggerTime: 14, title: "Squall Front", body: "The storm is already here. The enemy found the same cloud cover you did."),
                CinematicBeat(id: "formation_break", triggerTime: 28, title: "Formation Contact", body: "They are flying in pairs. Someone trained them carefully, then sent them here."),
                CinematicBeat(id: "fuel_warning", triggerTime: 75, title: "Fuel Margin Narrowing", body: "The weather is burning fuel you were counting on for the return."),
                CinematicBeat(id: "ash_debrief", triggerTime: 105, title: "Breaking Through", body: "If the engine holds, you are already past the worst of it. The island does not look back.")
            ],
            navalAAEmitters: [
                NavalAAEmitter(position: Vector3(x: 200, y: 0, z: -600), range: 260, fireRate: 0.8, damagePerRound: 7),
                NavalAAEmitter(position: Vector3(x: -200, y: 0, z: -550), range: 260, fireRate: 0.8, damagePerRound: 7),
                NavalAAEmitter(position: Vector3(x: 0, y: 0, z: -700), range: 260, fireRate: 0.7, damagePerRound: 7),
                NavalAAEmitter(position: Vector3(x: 350, y: 0, z: -620), range: 240, fireRate: 0.7, damagePerRound: 6)
            ]
        ),
        MissionDefinition(
            id: "okinawa_ten_go",
            title: "Okinawa — Ten-Go",
            subtitle: "The carrier group is not a target. It is a wall.",
            briefing: "Operation Ten-Go has positioned the most heavily defended carrier group in the Pacific. Combat air patrols and overlapping AA fire blanket the approaches. This is not a mission you were meant to survive.",
            debrief: "Ten-Go was the Japanese Navy's final major offensive. History recorded it. The Pacific forgot nothing.",
            recommendedAircraftID: "f4u_corsair",
            missionDuration: 300,
            archiveRewardID: "okinawa_ten_go_record",
            aircraftRewardID: "f6f_hellcat",
            weatherProfileID: "late_war_squall",
            environmentTone: .lateWar,
            upgradeRewardID: "reinforced_cables",
            objectives: [.destroyAllEnemies],
            playerSpawn: SpawnDefinition(id: "player", aircraftID: "f4u_corsair", team: .player, position: Vector3(x: 0, y: 44, z: 0), heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: .intercept),
            enemySpawns: [
                SpawnDefinition(id: "cap_lead", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: -140, y: 60, z: -320), heading: 0.4, pitch: 0, cinematicIntroDelay: 4, aiRole: .patrol),
                SpawnDefinition(id: "cap_wing_a", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: 110, y: 56, z: -360), heading: -0.3, pitch: 0, cinematicIntroDelay: 6, aiRole: .formationWing),
                SpawnDefinition(id: "cap_wing_b", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: -80, y: 64, z: -400), heading: 0.2, pitch: 0, cinematicIntroDelay: 9, aiRole: .formationWing),
                SpawnDefinition(id: "intercept_a", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 180, y: 52, z: -440), heading: -0.15, pitch: 0, cinematicIntroDelay: 13, aiRole: .intercept),
                SpawnDefinition(id: "intercept_b", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: -200, y: 50, z: -460), heading: 0.15, pitch: 0, cinematicIntroDelay: 16, aiRole: .intercept),
                SpawnDefinition(id: "reserve_cap", aircraftID: "ki84_hayate", team: .enemy, position: Vector3(x: 0, y: 68, z: -500), heading: 0.0, pitch: 0, cinematicIntroDelay: 22, aiRole: .patrol)
            ],
            cinematicBeats: [
                CinematicBeat(id: "ten_go_brief", triggerTime: 1, title: "Operation Ten-Go", body: "The Yamato sailed on a one-way sortie. The carrier group took the same logic to its conclusion."),
                CinematicBeat(id: "cap_contact", triggerTime: 14, title: "CAP Contact", body: "Four, six fighters. They have altitude and patience you do not."),
                CinematicBeat(id: "aa_wall", triggerTime: 30, title: "AA Wall", body: "The anti-aircraft fire below is not aimed. It fills space and dares you to occupy it."),
                CinematicBeat(id: "attrition", triggerTime: 70, title: "Attrition", body: "Each pass costs something the aircraft cannot give back."),
                CinematicBeat(id: "final_run", triggerTime: 120, title: "The Last Approach", body: "Whatever is left of the formation is still fighting. History watches this part closely.")
            ],
            navalAAEmitters: [
                NavalAAEmitter(position: Vector3(x: 200, y: 0, z: -700), range: 300, fireRate: 1.1, damagePerRound: 9),
                NavalAAEmitter(position: Vector3(x: -200, y: 0, z: -680), range: 300, fireRate: 1.1, damagePerRound: 9),
                NavalAAEmitter(position: Vector3(x: 0, y: 0, z: -800), range: 300, fireRate: 1.2, damagePerRound: 9),
                NavalAAEmitter(position: Vector3(x: 320, y: 0, z: -740), range: 280, fireRate: 1.0, damagePerRound: 8),
                NavalAAEmitter(position: Vector3(x: -320, y: 0, z: -720), range: 280, fireRate: 1.0, damagePerRound: 8),
                NavalAAEmitter(position: Vector3(x: 0, y: 0, z: -600), range: 280, fireRate: 0.9, damagePerRound: 8)
            ]
        ),
        MissionDefinition(
            id: "kyushu_kikusui",
            title: "Kyushu — Kikusui",
            subtitle: "The storm is not the enemy. Everything is the enemy.",
            briefing: "Typhoon weather over Kyushu. The Kikusui operations have stripped the air reserves to nothing. Visibility is twenty percent. The AA is absolute. Fly until the engine stops or the mission is over.",
            debrief: "Kikusui. Floating chrysanthemum. A name chosen for its poetry. The Pacific found a different word for it.",
            recommendedAircraftID: "n1k2j_shinden",
            missionDuration: 260,
            archiveRewardID: "infrastructure_collapse",
            aircraftRewardID: nil,
            weatherProfileID: "typhoon_wall",
            environmentTone: .lateWar,
            upgradeRewardID: "fuel_seals",
            objectives: [.destroyAllEnemies, .survive(seconds: 120)],
            playerSpawn: SpawnDefinition(id: "player", aircraftID: "n1k2j_shinden", team: .player, position: Vector3(x: 0, y: 36, z: 0), heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: .intercept),
            enemySpawns: [
                SpawnDefinition(id: "kikusui_lead", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: -110, y: 50, z: -300), heading: 0.5, pitch: 0, cinematicIntroDelay: 4, aiRole: .intercept),
                SpawnDefinition(id: "kikusui_b", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 90, y: 46, z: -340), heading: -0.4, pitch: 0, cinematicIntroDelay: 7, aiRole: .intercept),
                SpawnDefinition(id: "kikusui_c", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 0, y: 44, z: -380), heading: 0.1, pitch: 0, cinematicIntroDelay: 10, aiRole: .formationWing),
                SpawnDefinition(id: "kikusui_d", aircraftID: "n1k2j_shinden", team: .enemy, position: Vector3(x: -80, y: 54, z: -420), heading: 0.2, pitch: 0, cinematicIntroDelay: 15, aiRole: .intercept),
                SpawnDefinition(id: "kikusui_reserve", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 120, y: 48, z: -460), heading: -0.2, pitch: 0, cinematicIntroDelay: 20, aiRole: .patrol)
            ],
            cinematicBeats: [
                CinematicBeat(id: "typhoon_wall", triggerTime: 1, title: "Typhoon Wall", body: "Visibility dropped below twenty percent an hour ago. Flying here is a choice between storms."),
                CinematicBeat(id: "stripped_reserves", triggerTime: 12, title: "Stripped Reserves", body: "The pilots sent here today were the last of them. The training program ended months before they were ready."),
                CinematicBeat(id: "kikusui_contact", triggerTime: 26, title: "Contact in the Grey", body: "They appear in the storm like something the war dreamed up for its final act."),
                CinematicBeat(id: "engine_margin", triggerTime: 80, title: "Engine Margin", body: "The oil pressure is lying to you. The engine knows."),
                CinematicBeat(id: "final_kikusui", triggerTime: 120, title: "Kikusui", body: "Floating chrysanthemum. The poetry was chosen before anyone knew what it would cost.")
            ],
            navalAAEmitters: [
                NavalAAEmitter(position: Vector3(x: 150, y: 0, z: -500), range: 280, fireRate: 1.3, damagePerRound: 11),
                NavalAAEmitter(position: Vector3(x: -150, y: 0, z: -520), range: 280, fireRate: 1.3, damagePerRound: 11),
                NavalAAEmitter(position: Vector3(x: 0, y: 0, z: -600), range: 290, fireRate: 1.4, damagePerRound: 11),
                NavalAAEmitter(position: Vector3(x: 250, y: 0, z: -560), range: 270, fireRate: 1.2, damagePerRound: 10),
                NavalAAEmitter(position: Vector3(x: -250, y: 0, z: -540), range: 270, fireRate: 1.2, damagePerRound: 10),
                NavalAAEmitter(position: Vector3(x: 0, y: 0, z: -420), range: 270, fireRate: 1.1, damagePerRound: 10),
                NavalAAEmitter(position: Vector3(x: 300, y: 0, z: -650), range: 260, fireRate: 1.0, damagePerRound: 9),
                NavalAAEmitter(position: Vector3(x: -300, y: 0, z: -630), range: 260, fireRate: 1.0, damagePerRound: 9)
            ]
        ),
        MissionDefinition(
            id: "philippine_sea_final",
            title: "Philippine Sea — The Last Sortie",
            subtitle: "There is nothing left to intercept. Fly anyway.",
            briefing: "The Philippine Sea in late 1944. Allied dominance is absolute. The remaining aircraft are not being sent because the mission is possible — they are being sent because the orders have not stopped.",
            debrief: "The war ended. The Pacific forgot very little. This mission does not conclude with a victory screen.",
            recommendedAircraftID: "f6f_hellcat",
            missionDuration: 240,
            archiveRewardID: "postwar_memory",
            aircraftRewardID: nil,
            weatherProfileID: "late_war_squall",
            environmentTone: .lateWar,
            upgradeRewardID: nil,
            objectives: [.survive(seconds: 180)],
            playerSpawn: SpawnDefinition(id: "player", aircraftID: "f6f_hellcat", team: .player, position: Vector3(x: 0, y: 40, z: 0), heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: .intercept),
            enemySpawns: [
                SpawnDefinition(id: "remnant_a", aircraftID: "ki84_hayate", team: .enemy, position: Vector3(x: -100, y: 50, z: -320), heading: 0.3, pitch: 0, cinematicIntroDelay: 8, aiRole: .intercept),
                SpawnDefinition(id: "remnant_b", aircraftID: "a6m_zero", team: .enemy, position: Vector3(x: 80, y: 46, z: -360), heading: -0.2, pitch: 0, cinematicIntroDelay: 14, aiRole: .intercept)
            ],
            cinematicBeats: [
                CinematicBeat(id: "last_sortie_launch", triggerTime: 1, title: "The Last Sortie", body: "There is no fleet to protect. There is no strategic objective left. The orders arrived and the engine started."),
                CinematicBeat(id: "final_contact", triggerTime: 20, title: "Final Contact", body: "Two aircraft. Late-war. Flying on doctrine and inertia."),
                CinematicBeat(id: "water_below", triggerTime: 60, title: "The Water Below", body: "The Pacific is indifferent to all of this."),
                CinematicBeat(id: "memorial_moment", triggerTime: 120, title: "Memorial Moment", body: "Every name on the wall was once a person watching this same water, wondering the same thing."),
                CinematicBeat(id: "last_transmission", triggerTime: 170, title: "Last Transmission", body: "Static. Then quiet. The mission clock continues to count.")
            ],
            navalAAEmitters: [
                NavalAAEmitter(position: Vector3(x: 200, y: 0, z: -500), range: 260, fireRate: 0.7, damagePerRound: 7),
                NavalAAEmitter(position: Vector3(x: -200, y: 0, z: -480), range: 260, fireRate: 0.7, damagePerRound: 7)
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
