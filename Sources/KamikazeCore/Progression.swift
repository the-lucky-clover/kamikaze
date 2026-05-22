import Foundation

public struct PlayerSettings: Codable, Sendable, Equatable {
    public var musicVolume: Double
    public var effectsVolume: Double
    public var subtitlesEnabled: Bool
    public var invertedPitch: Bool

    public init(musicVolume: Double = 0.8, effectsVolume: Double = 0.9, subtitlesEnabled: Bool = true, invertedPitch: Bool = false) {
        self.musicVolume = musicVolume
        self.effectsVolume = effectsVolume
        self.subtitlesEnabled = subtitlesEnabled
        self.invertedPitch = invertedPitch
    }
}

public struct PlayerProgression: Codable, Sendable, Equatable {
    public var completedMissionIDs: [String]
    public var unlockedAircraftIDs: [String]
    public var unlockedArchiveEntryIDs: [String]
    public var selectedAircraftID: String
    public var settings: PlayerSettings

    public init(
        completedMissionIDs: [String],
        unlockedAircraftIDs: [String],
        unlockedArchiveEntryIDs: [String],
        selectedAircraftID: String,
        settings: PlayerSettings = PlayerSettings()
    ) {
        self.completedMissionIDs = completedMissionIDs
        self.unlockedAircraftIDs = unlockedAircraftIDs
        self.unlockedArchiveEntryIDs = unlockedArchiveEntryIDs
        self.selectedAircraftID = selectedAircraftID
        self.settings = settings
    }

    public static let `default` = PlayerProgression(
        completedMissionIDs: [],
        unlockedAircraftIDs: ContentLibrary.aircraft.filter(\.unlockedByDefault).map(\.id),
        unlockedArchiveEntryIDs: ContentLibrary.archive.filter(\.unlockedByDefault).map(\.id),
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

    public var availableMissions: [MissionDefinition] {
        var result: [MissionDefinition] = []
        let missions = ContentLibrary.missions
        for (index, mission) in missions.enumerated() {
            if index == 0 || completedMissionIDs.contains(missions[index - 1].id) {
                result.append(mission)
            }
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
