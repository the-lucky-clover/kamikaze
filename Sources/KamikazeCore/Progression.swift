import Foundation

public enum ColorBlindMode: String, Codable, Sendable, CaseIterable {
    case none
    case deuteranopia
    case protanopia
}

public enum AimAssistLevel: String, Codable, Sendable, CaseIterable {
    case off
    case standard
    case generous
}

public struct PlayerSettings: Codable, Sendable, Equatable {
    public var musicVolume: Double
    public var effectsVolume: Double
    public var subtitlesEnabled: Bool
    public var invertedPitch: Bool
    public var colorBlindMode: ColorBlindMode
    public var aimAssistLevel: AimAssistLevel
    public var motionBlurEnabled: Bool
    public var uiScale: Double

    public init(
        musicVolume: Double = 0.8,
        effectsVolume: Double = 0.9,
        subtitlesEnabled: Bool = true,
        invertedPitch: Bool = false,
        colorBlindMode: ColorBlindMode = .none,
        aimAssistLevel: AimAssistLevel = .standard,
        motionBlurEnabled: Bool = false,
        uiScale: Double = 1.0
    ) {
        self.musicVolume = musicVolume
        self.effectsVolume = effectsVolume
        self.subtitlesEnabled = subtitlesEnabled
        self.invertedPitch = invertedPitch
        self.colorBlindMode = colorBlindMode
        self.aimAssistLevel = aimAssistLevel
        self.motionBlurEnabled = motionBlurEnabled
        self.uiScale = uiScale
    }
}

public struct PlayerProgression: Codable, Sendable, Equatable {
    public var completedMissionIDs: [String]
    public var unlockedAircraftIDs: [String]
    public var unlockedArchiveEntryIDs: [String]
    public var purchasedUpgradeIDs: [String]
    public var selectedAircraftID: String
    public var settings: PlayerSettings

    public init(
        completedMissionIDs: [String],
        unlockedAircraftIDs: [String],
        unlockedArchiveEntryIDs: [String],
        purchasedUpgradeIDs: [String],
        selectedAircraftID: String,
        settings: PlayerSettings = PlayerSettings()
    ) {
        self.completedMissionIDs = completedMissionIDs
        self.unlockedAircraftIDs = unlockedAircraftIDs
        self.unlockedArchiveEntryIDs = unlockedArchiveEntryIDs
        self.purchasedUpgradeIDs = purchasedUpgradeIDs
        self.selectedAircraftID = selectedAircraftID
        self.settings = settings
    }

    public static let `default` = PlayerProgression(
        completedMissionIDs: [],
        unlockedAircraftIDs: ContentLibrary.aircraft.filter(\.unlockedByDefault).map(\.id),
        unlockedArchiveEntryIDs: ContentLibrary.archive.filter(\.unlockedByDefault).map(\.id),
        purchasedUpgradeIDs: [],
        selectedAircraftID: ContentLibrary.aircraft.first(where: \.unlockedByDefault)?.id ?? "f4f_wildcat"
    )

    public mutating func applyMissionRewards(for mission: MissionDefinition) {
        if !completedMissionIDs.contains(mission.id) {
            completedMissionIDs.append(mission.id)
        }
        unlockArchiveEntry(id: mission.archiveRewardID)
        if let aircraftRewardID = mission.aircraftRewardID {
            unlockAircraft(id: aircraftRewardID)
        }
        if let upgradeRewardID = mission.upgradeRewardID {
            unlockUpgrade(id: upgradeRewardID)
        }
        if !unlockedAircraftIDs.contains(selectedAircraftID) {
            selectedAircraftID = unlockedAircraftIDs.first ?? mission.recommendedAircraftID
        }
    }

    public mutating func unlockAircraft(id: String) {
        guard !unlockedAircraftIDs.contains(id) else { return }
        unlockedAircraftIDs.append(id)
    }

    public mutating func unlockArchiveEntry(id: String) {
        guard !unlockedArchiveEntryIDs.contains(id) else { return }
        unlockedArchiveEntryIDs.append(id)
    }

    public mutating func unlockUpgrade(id: String) {
        guard !purchasedUpgradeIDs.contains(id) else { return }
        purchasedUpgradeIDs.append(id)
    }

    public var availableMissions: [MissionDefinition] {
        ContentLibrary.missions.enumerated().compactMap { index, mission in
            guard index == 0 || completedMissionIDs.contains(mission.id) || completedMissionIDs.contains(ContentLibrary.missions[index - 1].id) else {
                return nil
            }
            return mission
        }
        return result
    }
}

public protocol SaveStore {
    func load() throws -> PlayerProgression
    func save(_ progression: PlayerProgression) throws
}

public final class InMemorySaveStore: SaveStore {
    public private(set) var progression: PlayerProgression

    public init(progression: PlayerProgression = .default) {
        self.progression = progression
    }

    public func load() throws -> PlayerProgression {
        progression
    }

    public func save(_ progression: PlayerProgression) throws {
        self.progression = progression
    }
}
