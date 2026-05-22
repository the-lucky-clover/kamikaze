import SwiftUI
import SceneKit
import Kamikaze

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.03, green: 0.05, blue: 0.09), Color(red: 0.18, green: 0.16, blue: 0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            switch model.screen {
            case .menu:
                MainMenuView()
            case .briefing:
                BriefingView()
            case .flight:
                FlightView()
            case .debrief:
                DebriefView()
            case .archive:
                ArchiveView()
            case .hangar:
                HangarView()
            case .settings:
                SettingsView()
            }
        }
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("KAMIKAZE")
                .font(.system(size: 42, weight: .black, design: .serif))
                .foregroundStyle(.white)
            Text("A playable anti-war elegy wrapped inside a high-intensity arcade Pacific flight simulator.")
                .font(.title3)
                .foregroundStyle(Color.white.opacity(0.82))
                .frame(maxWidth: 540, alignment: .leading)
            Text("The memorial wall is the first screen because the point is not to forget what the engine noise was for.")
                .font(.body)
                .foregroundStyle(Color(red: 0.93, green: 0.82, blue: 0.68))
                .frame(maxWidth: 540, alignment: .leading)
            VStack(spacing: 12) {
                MenuButton(title: "Mission Briefing", subtitle: model.selectedMission.title) {
                    model.audioDirector.playEffect(.confirm)
                    model.showBriefing()
                }
                MenuButton(title: "Hangar", subtitle: model.selectedAircraft.displayName) {
                    model.showHangar()
                }
                MenuButton(title: "Memorial Archive", subtitle: "\(model.unlockedArchiveEntries.count) entries unlocked") {
                    model.showArchive()
                }
                MenuButton(title: "Settings", subtitle: "Audio, subtitles, and pitch") {
                    model.showSettings()
                }
            }
            Spacer()
        }
        .padding(32)
    }
}

struct BriefingView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.selectedMission.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(model.selectedMission.subtitle)
                .font(.title3)
                .foregroundStyle(Color(red: 0.92, green: 0.83, blue: 0.7))
            Text(model.selectedMission.briefing)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.84))
                .frame(maxWidth: .infinity, alignment: .leading)
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label(model.selectedAircraft.displayName, systemImage: "airplane")
                    ForEach(model.selectedMission.objectives.indices, id: \.self) { index in
                        Text(model.selectedMission.objectives[index].briefText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.white)
            } label: {
                Text("Sortie plan")
                    .foregroundStyle(Color(red: 0.93, green: 0.82, blue: 0.68))
            }
            HStack(spacing: 14) {
                PrimaryButton(title: "Launch") {
                    model.startMission()
                }
                SecondaryButton(title: "Back") {
                    model.showMenu()
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

struct FlightView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        if let session = model.flightSession {
            ZStack {
                FlightViewport(renderer: session.renderer)
                    .ignoresSafeArea()

                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.selectedMission.title.uppercased())
                                .font(.headline)
                            Text("Integrity \(Int(session.snapshot.player.health))   Ammo \(session.snapshot.player.ammo)")
                            Text("Altitude \(Int(session.snapshot.player.position.y))m   Time \(Int(session.snapshot.time))s")
                            Text("Fuel \(Int(session.snapshot.player.fuelRemaining))%   Visibility \(Int((1 - session.snapshot.player.damageState.visibilityLoss) * 100))%")
                        }
                        .padding(14)
                        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))

                        Spacer()

                        Button(session.isPaused ? "Resume" : "Pause") {
                            session.togglePause()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white)
                    .padding()

                    if let beat = session.cinematicText {
                        VStack(spacing: 6) {
                            Text(beat.title.uppercased())
                                .font(.headline)
                            Text(beat.body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: 560)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(session.snapshot.objectiveSummary, id: \.self) { line in
                                    Text(line)
                                        .font(.footnote)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            TacticalOverlayView(snapshot: session.snapshot)
                                .frame(width: 168, height: 168)
                        }

                        HStack(alignment: .bottom, spacing: 14) {
                            VStack(spacing: 8) {
                                HoldButton(title: "Throttle +") { active in
                                    session.throttleInput = active ? 0.55 : 0
                                }
                                HoldButton(title: "Throttle -") { active in
                                    session.throttleInput = active ? -0.55 : 0
                                }
                                }

                            VStack(spacing: 8) {
                                HoldButton(title: "Climb") { active in
                                    session.pitchInput = active ? 1 : 0
                                }
                                HoldButton(title: "Dive") { active in
                                    session.pitchInput = active ? -1 : 0
                                }
                                }

                            VStack(spacing: 8) {
                                HoldButton(title: "Bank Left") { active in
                                    session.yawInput = active ? -1 : 0
                                }
                                HoldButton(title: "Bank Right") { active in
                                    session.yawInput = active ? 1 : 0
                                }
                            }

                            HoldButton(title: "FIRE", accent: .red) { active in
                                session.firing = active
                            }
                            .frame(width: 120, height: 120)
                        }
                    }
                    .padding(18)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 22))
                    .padding()
                }
            }
        }
    }
}

struct DebriefView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(model.lastOutcome == .success ? "Sortie Complete" : "Lost to the Sea")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(model.selectedMission.debrief)
                .foregroundStyle(Color.white.opacity(0.84))
            if model.lastOutcome == .success {
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Unlocked archive: \(model.catalog.archive.first(where: { $0.id == model.selectedMission.archiveRewardID })?.title ?? model.selectedMission.archiveRewardID)")
                        if let aircraftRewardID = model.selectedMission.aircraftRewardID,
                           let aircraft = model.catalog.aircraft.first(where: { $0.id == aircraftRewardID }) {
                            Text("Unlocked aircraft: \(aircraft.displayName)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.white)
                } label: {
                    Text("What remains")
                        .foregroundStyle(Color(red: 0.93, green: 0.82, blue: 0.68))
                }
            }
            HStack(spacing: 14) {
                PrimaryButton(title: "Return to Menu") {
                    model.showMenu()
                }
                SecondaryButton(title: "Open Archive") {
                    model.showArchive()
                }
            }
            Spacer()
        }
        .padding(28)
    }
}

struct ArchiveView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Memorial Archive")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                ForEach(model.unlockedArchiveEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.category.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.93, green: 0.82, blue: 0.68))
                        Text(entry.title)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text(entry.body)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    .padding()
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                }
                SecondaryButton(title: "Back") {
                    model.showMenu()
                }
            }
            .padding(28)
        }
    }
}

struct HangarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hangar")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            ForEach(model.unlockedAircraft) { aircraft in
                Button {
                    model.selectAircraft(aircraft.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(aircraft.displayName)
                                .font(.title3.bold())
                            Text("Cruise \(Int(aircraft.cruiseSpeed)) • Turn \(String(format: "%.2f", aircraft.turnRate)) • Durability \(Int(aircraft.durability))")
                                .font(.footnote)
                        }
                        Spacer()
                        if aircraft.id == model.selectedAircraft.id {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.white.opacity(aircraft.id == model.selectedAircraft.id ? 0.14 : 0.06), in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
            SecondaryButton(title: "Back") {
                model.showMenu()
            }
            Spacer()
        }
        .padding(28)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var draftSettings = PlayerSettings()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Group {
                SliderRow(title: "Music Volume", value: $draftSettings.musicVolume)
                SliderRow(title: "Effects Volume", value: $draftSettings.effectsVolume)
                Toggle("Subtitles", isOn: $draftSettings.subtitlesEnabled)
                Toggle("Invert Pitch", isOn: $draftSettings.invertedPitch)
            }
            .tint(Color(red: 0.93, green: 0.82, blue: 0.68))
            .foregroundStyle(.white)
            HStack(spacing: 14) {
                PrimaryButton(title: "Save") {
                    model.update(settings: draftSettings)
                    model.showMenu()
                }
                SecondaryButton(title: "Back") {
                    model.showMenu()
                }
            }
            Spacer()
        }
        .padding(28)
        .onAppear {
            draftSettings = model.progression.settings
        }
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value * 100))%")
            }
            Slider(value: $value, in: 0...1)
        }
    }
}

struct FlightViewport: UIViewRepresentable {
    @ObservedObject var renderer: FlightSceneRenderer

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = renderer.scene
        view.pointOfView = renderer.cameraNode
        view.backgroundColor = .black
        view.preferredFramesPerSecond = 60
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = renderer.scene
        uiView.pointOfView = renderer.cameraNode
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .foregroundStyle(.white)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(red: 0.93, green: 0.82, blue: 0.68), in: Capsule())
            .foregroundStyle(.black)
            .fontWeight(.bold)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct HoldButton: View {
    let title: String
    var accent: Color = Color(red: 0.93, green: 0.82, blue: 0.68)
    let onPressChanged: (Bool) -> Void

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(accent.opacity(0.32), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(accent, lineWidth: 1.5))
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: onPressChanged, perform: {})
    }
}

struct TacticalOverlayView: View {
    let snapshot: MissionSnapshot

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.stroke(Path(ellipseIn: rect.insetBy(dx: 6, dy: 6)), with: .color(Color.green.opacity(0.7)), lineWidth: 1)
            context.stroke(Path(ellipseIn: rect.insetBy(dx: 28, dy: 28)), with: .color(Color.green.opacity(0.45)), lineWidth: 1)
            context.stroke(Path { path in
                path.move(to: CGPoint(x: size.width / 2, y: 8))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height - 8))
                path.move(to: CGPoint(x: 8, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width - 8, y: size.height / 2))
            }, with: .color(Color.green.opacity(0.35)), lineWidth: 1)

            let stormRect = CGRect(x: size.width * 0.58, y: size.height * 0.16, width: size.width * 0.28, height: size.height * 0.42)
            context.fill(Path(ellipseIn: stormRect), with: .color(Color.orange.opacity(0.18)))

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.green))

            for enemy in snapshot.enemies where enemy.isAlive {
                let offset = CGPoint(
                    x: CGFloat(max(-60, min(60, enemy.position.x - snapshot.player.position.x))),
                    y: CGFloat(max(-60, min(60, enemy.position.z - snapshot.player.position.z)))
                )
                let point = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
                context.fill(Path(CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(.red))
            }
        }
        .background(Color(red: 0.03, green: 0.08, blue: 0.06).opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .topLeading) {
            Text("TACTICAL")
                .font(.caption2.bold())
                .foregroundStyle(Color.green.opacity(0.82))
                .padding(8)
        }
    }
}

private extension ObjectiveDefinition {
    var briefText: String {
        switch self {
        case .destroyAllEnemies:
            return "Destroy all enemy fighters in the sector."
        case let .survive(seconds):
            return "Survive for at least \(Int(seconds)) seconds after the intercept begins."
        case let .escort(timeLimit):
            return "Escort the fleet wake for \(Int(timeLimit)) seconds."
        }
    }
}
