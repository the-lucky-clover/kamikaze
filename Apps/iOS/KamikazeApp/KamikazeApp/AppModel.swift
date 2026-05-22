import Foundation
import SwiftUI
import Kamikaze

struct GameCatalog {
    var aircraft: [AircraftBlueprint]
    var missions: [MissionDefinition]
    var archive: [ArchiveEntry]

    static func load() -> GameCatalog {
        GameCatalog(
            aircraft: Bundle.main.decode([AircraftBlueprint].self, from: "aircraft.json") ?? ContentLibrary.aircraft,
            missions: Bundle.main.decode([MissionDefinition].self, from: "missions.json") ?? ContentLibrary.missions,
            archive: Bundle.main.decode([ArchiveEntry].self, from: "archive.json") ?? ContentLibrary.archive
        )
    }
}

enum AppScreen {
    case menu
    case briefing
    case flight
    case debrief
    case archive
    case hangar
    case settings
}

final class AppModel: ObservableObject {
    @Published var screen: AppScreen = .menu
    @Published var progression: PlayerProgression
    @Published var selectedMissionID: String
    @Published var flightSession: FlightSession?
    @Published var lastOutcome: MissionOutcome = .inProgress

    let catalog: GameCatalog
    let audioDirector = AudioDirector()
    private let saveStore = UserDefaultsSaveStore()

    init() {
        catalog = .load()
        progression = (try? saveStore.load()) ?? .default
        selectedMissionID = catalog.missions.first?.id ?? "embers_over_midway"
        audioDirector.apply(settings: progression.settings)
        audioDirector.transition(to: .menu)
    }

    var selectedMission: MissionDefinition {
        catalog.missions.first(where: { $0.id == selectedMissionID }) ?? catalog.missions[0]
    }

    var selectedAircraft: AircraftBlueprint {
        catalog.aircraft.first(where: { $0.id == progression.selectedAircraftID && progression.unlockedAircraftIDs.contains($0.id) })
            ?? catalog.aircraft.first(where: { progression.unlockedAircraftIDs.contains($0.id) })
            ?? catalog.aircraft[0]
    }

    var unlockedAircraft: [AircraftBlueprint] {
        catalog.aircraft.filter { progression.unlockedAircraftIDs.contains($0.id) }
    }

    var unlockedArchiveEntries: [ArchiveEntry] {
        catalog.archive.filter { progression.unlockedArchiveEntryIDs.contains($0.id) }
    }

    func showBriefing() {
        screen = .briefing
    }

    func showMenu() {
        flightSession?.stop()
        flightSession = nil
        screen = .menu
        audioDirector.transition(to: .menu)
    }

    func showHangar() {
        screen = .hangar
    }

    func showArchive() {
        screen = .archive
    }

    func showSettings() {
        screen = .settings
    }

    func startMission() {
        let session = FlightSession(
            mission: selectedMission,
            selectedAircraft: selectedAircraft,
            aircraftCatalog: catalog.aircraft,
            settings: progression.settings,
            audioDirector: audioDirector
        ) { [weak self] outcome in
            self?.finishMission(outcome)
        }
        flightSession?.stop()
        flightSession = session
        session.start()
        screen = .flight
        audioDirector.transition(to: .mission)
    }

    func finishMission(_ outcome: MissionOutcome) {
        lastOutcome = outcome
        if outcome == .success {
            progression.applyMissionRewards(for: selectedMission)
            saveProgression()
        }
        screen = .debrief
        audioDirector.transition(to: .debrief)
    }

    func selectAircraft(_ aircraftID: String) {
        guard progression.unlockedAircraftIDs.contains(aircraftID) else { return }
        progression.selectedAircraftID = aircraftID
        saveProgression()
    }

    func update(settings: PlayerSettings) {
        progression.settings = settings
        audioDirector.apply(settings: settings)
        saveProgression()
    }

    private func saveProgression() {
        try? saveStore.save(progression)
    }
}

@MainActor
final class FlightSession: ObservableObject {
    @Published private(set) var snapshot: MissionSnapshot
    @Published private(set) var cinematicText: (title: String, body: String)?
    @Published var throttleInput: Double = 0
    @Published var pitchInput: Double = 0
    @Published var yawInput: Double = 0
    @Published var firing: Bool = false
    @Published var isPaused = false

    let mission: MissionDefinition
    let renderer = FlightSceneRenderer()

    private var simulation: GameSimulation
    private var timer: Timer?
    private let settings: PlayerSettings
    private let audioDirector: AudioDirector
    private let onComplete: (MissionOutcome) -> Void

    init(
        mission: MissionDefinition,
        selectedAircraft: AircraftBlueprint,
        aircraftCatalog: [AircraftBlueprint],
        settings: PlayerSettings,
        audioDirector: AudioDirector,
        onComplete: @escaping (MissionOutcome) -> Void
    ) {
        self.mission = mission
        self.settings = settings
        self.audioDirector = audioDirector
        self.onComplete = onComplete
        simulation = GameSimulation(mission: mission, selectedAircraft: selectedAircraft, aircraftCatalog: aircraftCatalog)
        snapshot = simulation.snapshot
        renderer.update(with: snapshot)
    }

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        isPaused.toggle()
    }

    private func tick() {
        guard !isPaused else { return }
        simulation.advance(
            playerInput: PilotInput(
                throttle: throttleInput,
                pitch: settings.invertedPitch ? -pitchInput : pitchInput,
                yaw: yawInput,
                firing: firing
            ),
            deltaTime: 1.0 / 30.0
        )
        snapshot = simulation.snapshot
        renderer.update(with: snapshot)
        handle(events: snapshot.events)
        audioDirector.updateDynamicMix(
            altitude: snapshot.player.position.y,
            combatIntensity: min(1, Double(snapshot.events.count) / 4),
            weatherSeverity: 0.72,
            fleetProximity: max(0, 1 - (snapshot.player.position.length / 1_200))
        )
        if snapshot.outcome != .inProgress {
            stop()
            onComplete(snapshot.outcome)
        }
    }

    private func handle(events: [CombatEvent]) {
        for event in events {
            switch event.kind {
            case .shotFired:
                audioDirector.playEffect(.guns)
            case .destroyed:
                audioDirector.playEffect(.explosion)
            case let .cinematicBeat(_, title, body):
                cinematicText = (title, body)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    if self?.cinematicText?.title == title {
                        self?.cinematicText = nil
                    }
                }
            case .hit:
                break
            }
        }
    }
}

struct UserDefaultsSaveStore: SaveStore {
    private let defaults = UserDefaults.standard
    private let key = "com.theluckyclover.kamikaze.progression"

    func load() throws -> PlayerProgression {
        guard let data = defaults.data(forKey: key) else {
            return .default
        }
        return try JSONDecoder().decode(PlayerProgression.self, from: data)
    }

    func save(_ progression: PlayerProgression) throws {
        let data = try JSONEncoder().encode(progression)
        defaults.set(data, forKey: key)
    }
}

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        guard let url = url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
