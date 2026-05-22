import Foundation
import AVFAudio
import AudioToolbox
import Kamikaze

final class AudioDirector {
    enum MixState {
        case menu
        case mission
        case debrief
    }

    enum Effect {
        case guns
        case explosion
        case confirm
    }

    private var musicPlayer: AVAudioPlayer?
    private var ambiencePlayer: AVAudioPlayer?
    private var settings = PlayerSettings()
    private var currentMix: MixState = .menu

    func transition(to state: MixState) {
        currentMix = state
        switch state {
        case .menu:
            playLoop(named: "menu_theme", ambience: "harbor_ambience")
        case .mission:
            playLoop(named: "mission_theme", ambience: "ocean_wind")
        case .debrief:
            playLoop(named: "debrief_theme", ambience: "harbor_ambience")
        }
    }

    func apply(settings: PlayerSettings) {
        self.settings = settings
        musicPlayer?.volume = Float(settings.musicVolume)
        ambiencePlayer?.volume = Float(settings.effectsVolume)
    }

    func playEffect(_ effect: Effect) {
        switch effect {
        case .guns:
            AudioServicesPlaySystemSound(1108)
        case .explosion:
            AudioServicesPlaySystemSound(1322)
        case .confirm:
            AudioServicesPlaySystemSound(1519)
        }
    }

    func updateDynamicMix(altitude: Double, combatIntensity: Double, weatherSeverity: Double, fleetProximity: Double) {
        guard currentMix == .mission else { return }
        let altitudeWeight = min(max(altitude / 180, 0), 1)
        let tension = min(max((combatIntensity * 0.45) + (weatherSeverity * 0.3) + (fleetProximity * 0.25), 0), 1)
        musicPlayer?.volume = Float((settings.musicVolume * 0.45) + (settings.musicVolume * 0.55 * tension))
        ambiencePlayer?.volume = Float((settings.effectsVolume * 0.4) + (settings.effectsVolume * 0.35 * weatherSeverity) + (settings.effectsVolume * 0.2 * altitudeWeight))
        musicPlayer?.rate = 1.0 + Float(tension * 0.06)
    }

    private func playLoop(named music: String, ambience: String) {
        musicPlayer = makePlayer(named: music, volume: settings.musicVolume)
        ambiencePlayer = makePlayer(named: ambience, volume: settings.effectsVolume)
        musicPlayer?.numberOfLoops = -1
        ambiencePlayer?.numberOfLoops = -1
        musicPlayer?.play()
        ambiencePlayer?.play()
    }

    private func makePlayer(named name: String, volume: Double) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else {
            return nil
        }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = Float(volume)
        player?.enableRate = true
        player?.prepareToPlay()
        return player
    }
}
