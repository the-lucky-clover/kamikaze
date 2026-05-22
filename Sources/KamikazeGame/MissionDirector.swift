import Foundation
import KamikazeCore

public struct MissionDirector: Sendable {
    public var progression: PlayerProgression

    public init(progression: PlayerProgression = .default) {
        self.progression = progression
    }

    public func selectableAircraft() -> [AircraftBlueprint] {
        ContentLibrary.aircraft.filter { progression.unlockedAircraftIDs.contains($0.id) }
    }

    public func mission(withID id: String) -> MissionDefinition? {
        ContentLibrary.missions.first(where: { $0.id == id })
    }

    public func selectedAircraft() -> AircraftBlueprint {
        selectableAircraft().first(where: { $0.id == progression.selectedAircraftID })
            ?? selectableAircraft().first
            ?? ContentLibrary.aircraft[0]
    }

    public func startMission(id: String) -> GameSimulation? {
        guard let mission = mission(withID: id) else { return nil }
        return GameSimulation(
            mission: mission,
            selectedAircraft: selectedAircraft(),
            purchasedUpgradeIDs: progression.purchasedUpgradeIDs,
            aimAssistLevel: progression.settings.aimAssistLevel
        )
    }

    public mutating func applyOutcome(_ outcome: MissionOutcome, for missionID: String) {
        guard outcome == .success else { return }
        guard let mission = mission(withID: missionID) else { return }
        progression.applyMissionRewards(for: mission)
    }

    public func unlockedArchiveEntries() -> [ArchiveEntry] {
        ContentLibrary.archive.filter { entry in
            progression.unlockedArchiveEntryIDs.contains(entry.id)
        }
    }
}
