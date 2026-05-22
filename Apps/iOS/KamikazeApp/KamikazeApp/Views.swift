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
            case .studioIntro:
                StudioIntroView()
            case .attractMode:
                AttractModeView()
            case .menu:
                MainMenuView()
            case .missionSelect:
                MissionSelectView()
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
            case .replay:
                ReplayView()
            }

            model.transitionTone.color
                .opacity(model.transitionOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

struct StudioIntroView: View {
    @EnvironmentObject private var model: AppModel
    @State private var visible = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("CORPORATE HEARTTHROB STUDIOS")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(3)
                Text("presents")
                    .font(.headline)
                    .foregroundStyle(Color.white.opacity(0.64))
            }
            .foregroundStyle(.white)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.96)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                visible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                model.advanceFromStudioIntro()
            }
        }
    }
}

struct AttractModeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var animate = false

    var body: some View {
        ZStack {
            CinematicBackdropView()
            LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()
                Text("KAMIKAZE")
                    .font(.system(size: 62, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.94)
                    .opacity(animate ? 1 : 0)
                Text("Touch anywhere to enter the memorial.")
                    .font(.title3)
                    .foregroundStyle(Color.white.opacity(0.84))
                    .opacity(animate ? 1 : 0)
                Spacer()
                Text("Demonstration reel — flight, storm, tactical overlay, archive framing")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.66))
                    .padding(.bottom, 36)
                    .opacity(animate ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.advanceFromAttractMode()
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.82)) {
                animate = true
            }
        }
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var model: AppModel
    @State private var animateIn = false

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
                MenuButton(title: "Campaign", subtitle: model.selectedMission.title) {
                    model.audioDirector.playEffect(.confirm)
                    model.showMissionSelect()
                }
                MenuButton(title: "Hangar", subtitle: model.selectedAircraft.displayName) {
                    model.showHangar()
                }
                MenuButton(title: "Memorial Archive", subtitle: "\(model.unlockedArchiveEntries.count) entries unlocked") {
                    model.showArchive()
                }
                MenuButton(title: "Settings", subtitle: "Audio, subtitles, accessibility, and UI") {
                    model.showSettings()
                }
            }
            Spacer()
        }
        .padding(32)
        .offset(y: animateIn ? 0 : 26)
        .scaleEffect(animateIn ? 1 : 0.97, anchor: .topLeading)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
}

struct MissionSelectView: View {
    @EnvironmentObject private var model: AppModel

    private let nodes: [(id: String, point: CGPoint)] = [
        ("embers_over_midway", CGPoint(x: 0.18, y: 0.3)),
        ("leyte_gulf_dusk", CGPoint(x: 0.55, y: 0.42)),
        ("iwo_jima_ash", CGPoint(x: 0.72, y: 0.48)),
        ("okinawa_ten_go", CGPoint(x: 0.78, y: 0.58)),
        ("kyushu_kikusui", CGPoint(x: 0.84, y: 0.28)),
        ("philippine_sea_final", CGPoint(x: 0.62, y: 0.18))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Campaign")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Select an unlocked node to enter the mission briefing.")
                .foregroundStyle(Color.white.opacity(0.72))
            GeometryReader { proxy in
                ZStack {
                    Canvas { context, size in
                        let rect = CGRect(origin: .zero, size: size)
                        context.fill(Path(rect), with: .linearGradient(Gradient(colors: [Color(red: 0.06, green: 0.16, blue: 0.19), Color(red: 0.05, green: 0.08, blue: 0.14)]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))
                        for pair in zip(nodes, nodes.dropFirst()) {
                            let start = CGPoint(x: pair.0.point.x * size.width, y: pair.0.point.y * size.height)
                            let end = CGPoint(x: pair.1.point.x * size.width, y: pair.1.point.y * size.height)
                            var path = Path()
                            path.move(to: start)
                            path.addLine(to: end)
                            context.stroke(path, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
                        }
                    }
                    ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
                        if let mission = model.catalog.missions.first(where: { $0.id == node.id }) {
                            let completed = model.isMissionCompleted(mission)
                            let unlocked = model.isMissionUnlocked(mission)
                            let color: Color = completed ? .green : (unlocked ? .white : .gray)
                            Button {
                                guard unlocked else { return }
                                model.selectedMissionID = mission.id
                                model.showBriefing()
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(color.opacity(unlocked ? 0.9 : 0.5))
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().stroke(color, lineWidth: 2))
                                    Text(mission.title)
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 110)
                                }
                            }
                            .buttonStyle(.plain)
                            .position(x: node.point.x * proxy.size.width, y: node.point.y * proxy.size.height)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .frame(height: 360)
            SecondaryButton(title: "Back") {
                model.showMenu()
            }
        }
        .padding(28)
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
                    Text(model.weatherProfile(for: model.selectedMission).displayName)
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
                    model.showMissionSelect()
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

                        VStack(spacing: 10) {
                            Button(session.cameraMode == .chase ? "Cockpit" : "Chase") {
                                session.cameraMode = session.cameraMode == .chase ? .cockpit : .chase
                            }
                            .buttonStyle(.bordered)
                            Button(session.isPaused ? "Resume" : "Pause") {
                                session.togglePause()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()

                    CinematicBeatOverlay(beat: session.cinematicText)

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

                            TacticalOverlayView(
                                snapshot: session.snapshot,
                                altitude: session.snapshot.player.position.y,
                                fuelRemaining: session.snapshot.player.fuelRemaining,
                                stormIntensity: model.weatherProfile(for: model.selectedMission).stormIntensity
                            )
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
                                HoldButton(title: "Yaw Left") { active in
                                    session.yawInput = active ? -1 : 0
                                }
                                HoldButton(title: "Yaw Right") { active in
                                    session.yawInput = active ? 1 : 0
                                }
                            }

                            VStack(spacing: 8) {
                                HoldButton(title: "Roll Left") { active in
                                    session.rollInput = active ? -1 : 0
                                }
                                HoldButton(title: "Roll Right") { active in
                                    session.rollInput = active ? 1 : 0
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
                        if let upgradeRewardID = model.selectedMission.upgradeRewardID,
                           let upgrade = model.catalog.upgrades.first(where: { $0.id == upgradeRewardID }) {
                            Text("Unlocked upgrade: \(upgrade.displayName)")
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
                SecondaryButton(title: "Replay") {
                    model.showReplay()
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
        ScrollView {
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

                VStack(alignment: .leading, spacing: 10) {
                    Text("Upgrades")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    if model.unlockedUpgrades.isEmpty {
                        Text("No upgrades unlocked yet.")
                            .foregroundStyle(Color.white.opacity(0.68))
                    } else {
                        ForEach(model.unlockedUpgrades) { upgrade in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(upgrade.displayName)
                                    .font(.headline)
                                Text(upgrade.effectType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.65))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }

                SecondaryButton(title: "Back") {
                    model.showMenu()
                }
            }
            .padding(28)
        }
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
                SliderRow(title: "Music Volume", value: $draftSettings.musicVolume, range: 0...1, suffix: "%")
                SliderRow(title: "Effects Volume", value: $draftSettings.effectsVolume, range: 0...1, suffix: "%")
                Toggle("Subtitles", isOn: $draftSettings.subtitlesEnabled)
                Toggle("Invert Pitch", isOn: $draftSettings.invertedPitch)
                Toggle("Motion Blur", isOn: $draftSettings.motionBlurEnabled)
                Picker("Color Blind Mode", selection: $draftSettings.colorBlindMode) {
                    ForEach(ColorBlindMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                Picker("Aim Assist", selection: $draftSettings.aimAssistLevel) {
                    ForEach(AimAssistLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                SliderRow(title: "UI Scale", value: $draftSettings.uiScale, range: 0.8...1.4, suffix: "x")
            }
            .pickerStyle(.menu)
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

struct ReplayView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var renderer = FlightSceneRenderer()
    @State private var frameIndex = 0

    var body: some View {
        VStack(spacing: 16) {
            if model.lastReplayFrames.isEmpty {
                Text("No replay available.")
                    .foregroundStyle(.white)
            } else {
                FlightViewport(renderer: renderer)
                    .frame(height: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .onAppear(perform: updateRenderer)
                Slider(value: Binding(
                    get: { Double(frameIndex) },
                    set: { frameIndex = Int($0) }
                ), in: 0...Double(max(0, model.lastReplayFrames.count - 1)), step: 1)
                .tint(Color(red: 0.93, green: 0.82, blue: 0.68))
                let safeIndex = min(max(frameIndex, 0), model.lastReplayFrames.count - 1)
                Text("Frame \(safeIndex + 1) / \(model.lastReplayFrames.count) — t=\(String(format: "%.1f", model.lastReplayFrames[safeIndex].time))s")
                    .foregroundStyle(.white)
            }
            SecondaryButton(title: "Back") {
                model.showMenu()
            }
        }
        .padding(28)
        .onChange(of: frameIndex) { _, _ in
            updateRenderer()
        }
    }

    private func updateRenderer() {
        guard !model.lastReplayFrames.isEmpty else { return }
        let safeIndex = min(max(frameIndex, 0), model.lastReplayFrames.count - 1)
        let frame = model.lastReplayFrames[safeIndex]
        renderer.applyEnvironment(weather: model.weatherProfile(for: model.selectedMission), tone: model.selectedMission.environmentTone)
        renderer.update(with: frame.snapshot)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var suffix: String = "%"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                if suffix == "%" {
                    Text("\(Int(value * 100))%")
                } else {
                    Text(String(format: "%.2f%@", value, suffix))
                }
            }
            Slider(value: $value, in: range)
        }
    }
}

struct CinematicBeatOverlay: View {
    let beat: (title: String, body: String)?
    @State private var revealedText = ""

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.black).frame(height: 40).opacity(beat == nil ? 0 : 0.8)
            if let beat {
                VStack(spacing: 6) {
                    Text(beat.title.uppercased())
                        .font(.headline)
                    Text(revealedText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: 560)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
            Rectangle().fill(.black).frame(height: 40).opacity(beat == nil ? 0 : 0.8)
        }
        .animation(.easeInOut(duration: 0.25), value: beat?.title)
        .task(id: beat?.title ?? "") {
            guard let beat else {
                revealedText = ""
                return
            }
            revealedText = ""
            for character in beat.body {
                try? await Task.sleep(for: .milliseconds(40))
                revealedText.append(character)
            }
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
    let altitude: Double
    let fuelRemaining: Double
    let stormIntensity: Double

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

            let altitudeRatio = max(0.0, min(0.95, altitude / 200.0))
            let altitudeBarHeight = size.height * altitudeRatio
            let altitudeRect = CGRect(x: 6, y: size.height - altitudeBarHeight - 6, width: 6, height: altitudeBarHeight)
            context.fill(Path(roundedRect: altitudeRect, cornerRadius: 3), with: .color(.green))

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let fuelRadius = max(18, CGFloat(fuelRemaining / 240.0) * size.width * 0.45)
            for dash in stride(from: 0.0, to: 360.0, by: 16.0) {
                let start = Angle.degrees(dash)
                let end = Angle.degrees(dash + 8)
                var arc = Path()
                arc.addArc(center: center, radius: fuelRadius, startAngle: start, endAngle: end, clockwise: false)
                context.stroke(arc, with: .color(.green.opacity(0.4)), lineWidth: 1)
            }

            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)), with: .color(.green))

            for enemy in snapshot.enemies where enemy.isAlive {
                let offset = CGPoint(
                    x: CGFloat(max(-60, min(60, enemy.position.x - snapshot.player.position.x))),
                    y: CGFloat(max(-60, min(60, enemy.position.z - snapshot.player.position.z)))
                )
                let point = CGPoint(x: center.x + offset.x, y: center.y + offset.y)
                context.fill(Path(CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)), with: .color(.red))
            }

            let weatherRect = CGRect(x: size.width - 22, y: 8, width: 12, height: 12)
            context.fill(Path(ellipseIn: weatherRect), with: .color(.orange.opacity(0.2 + (stormIntensity * 0.6))))
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

struct CinematicBackdropView: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.07, green: 0.1, blue: 0.16), Color(red: 0.22, green: 0.25, blue: 0.31), Color(red: 0.08, green: 0.1, blue: 0.14)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Circle()
                .fill(Color(red: 0.76, green: 0.35, blue: 0.18).opacity(0.85))
                .frame(width: 240, height: 240)
                .blur(radius: 8)
                .offset(x: 280, y: -220)
            RoundedRectangle(cornerRadius: 220)
                .fill(Color.white.opacity(0.12))
                .frame(width: 420, height: 110)
                .blur(radius: 8)
                .offset(x: drift ? -280 : -220, y: -190)
            RoundedRectangle(cornerRadius: 220)
                .fill(Color.white.opacity(0.08))
                .frame(width: 520, height: 130)
                .blur(radius: 10)
                .offset(x: drift ? 180 : 230, y: -120)
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.03, green: 0.07, blue: 0.11), Color.black], startPoint: .top, endPoint: .bottom))
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(red: 0.08, green: 0.14, blue: 0.18))
                        .frame(height: 240)
                        .mask(LinearGradient(colors: [.clear, .white], startPoint: .top, endPoint: .bottom))
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                drift = true
            }
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

private extension TransitionTone {
    var color: Color {
        switch self {
        case .black:
            return .black
        case .white:
            return .white
        }
    }
}
