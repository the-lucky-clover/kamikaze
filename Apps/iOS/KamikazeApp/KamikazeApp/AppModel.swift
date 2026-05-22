import SwiftUI
import Kamikaze

struct GameCatalog {
    var aircraft: [AircraftBlueprint]
    var missions: [MissionDefinition]
    var archive: [ArchiveEntry]
    var upgrades: [UpgradeDefinition]
    var weather: [WeatherProfile]

    static func load() -> GameCatalog {
        GameCatalog(
            aircraft: Bundle.main.decode([AircraftBlueprint].self, from: "aircraft.json") ?? ContentLibrary.aircraft,
            missions: Bundle.main.decode([MissionDefinition].self, from: "missions.json") ?? ContentLibrary.missions,
            archive: Bundle.main.decode([ArchiveEntry].self, from: "archive.json") ?? ContentLibrary.archive,
            upgrades: Bundle.main.decode([UpgradeDefinition].self, from: "upgrades.json") ?? ContentLibrary.upgrades,
            weather: Bundle.main.decode([WeatherProfile].self, from: "presets.json") ?? ContentLibrary.weather
        )
    }
}

enum CameraMode {
    case chase
    case cockpit
}

enum AppScreen {
    case studioIntro
    case attractMode
    case menu
    case missionSelect
    case briefing
    case flight
    case debrief
    case archive
    case hangar
    case settings
    case replay
}

enum TransitionTone {
    case black
    case white
}

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: AppScreen = .studioIntro
    @Published var progression: PlayerProgression
    @Published var selectedMissionID: String
    @Published var flightSession: FlightSession?
    @Published var lastOutcome: MissionOutcome = .inProgress
    @Published var transitionOpacity: Double = 1
    @Published var transitionTone: TransitionTone = .black
    @Published var lastReplayFrames: [(time: Double, snapshot: MissionSnapshot)] = []

    let catalog: GameCatalog
    let audioDirector = AudioDirector()
    private let saveStore: any SaveStore = {
        let fs = FileSystemSaveStore()
        // Prefer file-system persistence; fall back to UserDefaults if the
        // file doesn't exist yet or is unreadable (first launch, migration, etc.)
        if (try? fs.load()) != nil {
            return fs
        }
        return UserDefaultsSaveStore()
    }()

    init() {
        catalog = .load()
        progression = (try? saveStore.load()) ?? .default
        selectedMissionID = progression.availableMissions.first?.id ?? catalog.missions.first?.id ?? "embers_over_midway"
        audioDirector.apply(settings: progression.settings)
        audioDirector.transition(to: .menu)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.transitionOpacity = 0
            }
        }
    }

    var availableMissions: [MissionDefinition] {
        catalog.missions.enumerated().compactMap { index, mission in
            guard index == 0 || progression.completedMissionIDs.contains(mission.id) || progression.completedMissionIDs.contains(catalog.missions[index - 1].id) else {
                return nil
            }
            return mission
        }
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

    var unlockedUpgrades: [UpgradeDefinition] {
        catalog.upgrades.filter { progression.purchasedUpgradeIDs.contains($0.id) }
    }

    func weatherProfile(for mission: MissionDefinition) -> WeatherProfile {
        catalog.weather.first(where: { $0.id == mission.weatherProfileID }) ?? ContentLibrary.weather[0]
    }

    func isMissionCompleted(_ mission: MissionDefinition) -> Bool {
        progression.completedMissionIDs.contains(mission.id)
    }

    func isMissionUnlocked(_ mission: MissionDefinition) -> Bool {
        availableMissions.contains(where: { $0.id == mission.id })
    }

    func showBriefing() {
        performTransition(to: .briefing)
    }

    func showMissionSelect() {
        performTransition(to: .missionSelect)
    }

    func selectMission(_ missionID: String) {
        selectedMissionID = missionID
        performTransition(to: .briefing)
    }

    func showMenu() {
        performTransition(to: .menu) {
            self.flightSession?.stop()
            self.flightSession = nil
            self.audioDirector.transition(to: .menu)
        }
    }

    func showMissionSelect() {
        performTransition(to: .missionSelect)
    }

    func showHangar() {
        performTransition(to: .hangar)
    }

    func showArchive() {
        performTransition(to: .archive)
    }

    func showSettings() {
        performTransition(to: .settings)
    }

    func showReplay() {
        performTransition(to: .replay)
    }

    func advanceFromStudioIntro() {
        performTransition(to: .attractMode, tone: .black)
    }

    func advanceFromAttractMode() {
        performTransition(to: .menu, tone: .black)
    }

    func startMission() {
        let session = FlightSession(
            mission: selectedMission,
            selectedAircraft: selectedAircraft,
            aircraftCatalog: catalog.aircraft,
            purchasedUpgradeIDs: progression.purchasedUpgradeIDs,
            settings: progression.settings,
            audioDirector: audioDirector
        ) { [weak self] outcome in
            self?.finishMission(outcome)
        }
        performTransition(to: .flight, tone: .white) {
            self.flightSession?.stop()
            self.flightSession = session
            session.start()
            self.audioDirector.transition(to: .mission)
        }
    }

    func finishMission(_ outcome: MissionOutcome) {
        performTransition(to: .debrief, tone: .black) {
            self.lastOutcome = outcome
            if let session = self.flightSession {
                self.lastReplayFrames = session.replayFrames
            }
            if outcome == .success {
                self.progression.applyMissionRewards(for: self.selectedMission)
                self.saveProgression()
            }
            self.audioDirector.transition(to: .debrief)
        }
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

    private func performTransition(to newScreen: AppScreen, tone: TransitionTone = .black, midpoint: (() -> Void)? = nil) {
        transitionTone = tone
        withAnimation(.easeInOut(duration: 0.35)) {
            transitionOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            midpoint?()
            self.screen = newScreen
            withAnimation(.easeInOut(duration: 0.55)) {
                self.transitionOpacity = 0
            }
        }
    }
}

struct ReplayRecorder: Sendable {
    private(set) var frames: [(time: Double, snapshot: MissionSnapshot)] = []
    private let maxFrames = 3600

    mutating func record(time: Double, snapshot: MissionSnapshot) {
        guard frames.count < maxFrames else { return }
        frames.append((time: time, snapshot: snapshot))
    }

    mutating func reset() {
        frames.removeAll(keepingCapacity: true)
    }
}

@MainActor
final class FlightSession: ObservableObject {
    @Published private(set) var snapshot: MissionSnapshot
    @Published private(set) var cinematicText: (title: String, body: String)?
    @Published var throttleInput: Double = 0
    @Published var pitchInput: Double = 0
    @Published var yawInput: Double = 0
    @Published var rollInput: Double = 0
    @Published var firing: Bool = false
    @Published var isPaused = false
    @Published var cameraMode: CameraMode = .chase

    let mission: MissionDefinition
    let renderer = FlightSceneRenderer()

    private var simulation: GameSimulation
    private var timer: Timer?
    private let settings: PlayerSettings
    private let audioDirector: AudioDirector
    private let weatherSeverity: Double
    private let onComplete: (MissionOutcome) -> Void
    private let weatherProfile: WeatherProfile
    private var replayRecorder = ReplayRecorder()
    private var nextEngineStrainTime: Double = 0
    private var nextWeatherAudioTime: Double = 0

    var replayFrames: [(time: Double, snapshot: MissionSnapshot)] { replayRecorder.frames }

    init(
        mission: MissionDefinition,
        selectedAircraft: AircraftBlueprint,
        aircraftCatalog: [AircraftBlueprint],
        purchasedUpgradeIDs: [String],
        settings: PlayerSettings,
        audioDirector: AudioDirector,
        onComplete: @escaping (MissionOutcome) -> Void
    ) {
        self.mission = mission
        self.settings = settings
        self.audioDirector = audioDirector
        self.onComplete = onComplete
        weatherProfile = ContentLibrary.weather.first(where: { $0.id == mission.weatherProfileID }) ?? ContentLibrary.weather[0]
        simulation = GameSimulation(
            mission: mission,
            selectedAircraft: selectedAircraft,
            aircraftCatalog: aircraftCatalog,
            purchasedUpgradeIDs: purchasedUpgradeIDs,
            aimAssistLevel: settings.aimAssistLevel
        )
        snapshot = simulation.snapshot
        renderer.cameraMode = cameraMode
        renderer.applyEnvironment(weather: weatherProfile, tone: mission.environmentTone)
        renderer.update(with: snapshot)
    }

    func start() {
        stop()
        replayRecorder.reset()
        replayRecorder.record(time: snapshot.time, snapshot: snapshot)
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
                roll: rollInput,
                firing: firing
            ),
            deltaTime: 1.0 / 30.0
        )
        snapshot = simulation.snapshot
        replayRecorder.record(time: simulation.missionTime, snapshot: simulation.snapshot)
        renderer.cameraMode = cameraMode
        renderer.update(with: snapshot)
        handle(events: snapshot.events)
        audioDirector.updateDynamicMix(
            altitude: snapshot.player.position.y,
            combatIntensity: min(1, Double(snapshot.events.count) / 4),
            weatherSeverity: weatherProfile.stormIntensity,
            fleetProximity: max(0, 1 - (snapshot.player.position.length / 1_200))
        )
        if snapshot.player.damageState.engineLoss > 0.5, snapshot.time >= nextEngineStrainTime {
            audioDirector.playEffect(.engineStrain)
            nextEngineStrainTime = snapshot.time + 3
        }
        if weatherProfile.stormIntensity > 0.7, snapshot.time >= nextWeatherAudioTime {
            audioDirector.playEffect(.rainHeavy)
            nextWeatherAudioTime = snapshot.time + 4
        } else if weatherProfile.stormIntensity > 0.3, snapshot.time >= nextWeatherAudioTime {
            audioDirector.playEffect(.rainLight)
            nextWeatherAudioTime = snapshot.time + 6
        }
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
            case let .hit(targetID):
                if targetID == snapshot.player.id {
                    audioDirector.playEffect(.cockpitCreak)
                }
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

struct FileSystemSaveStore: SaveStore {
    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("Kamikaze", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        fileURL = dir.appendingPathComponent("progression.json")
    }

    func load() throws -> PlayerProgression {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(PlayerProgression.self, from: data)
    }

    func save(_ progression: PlayerProgression) throws {
        let data = try JSONEncoder().encode(progression)
        try data.write(to: fileURL, options: .atomic)
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
