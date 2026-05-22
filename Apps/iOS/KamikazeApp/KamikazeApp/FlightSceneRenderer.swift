import SwiftUI
import SceneKit
import Kamikaze

@MainActor
final class FlightSceneRenderer: ObservableObject {
    let scene: SCNScene
    let cameraNode = SCNNode()
    var cameraMode: CameraMode = .chase

    private let oceanNode = SCNNode()
    private let skyNode = SCNNode()
    private let sunNode = SCNNode()
    private var cloudNodes: [SCNNode] = []
    private var aircraftNodes: [String: SCNNode] = [:]
    private var smokeEmitters: [String: SCNNode] = [:]

    init() {
        scene = SCNScene()
        buildScene()
    }

    func update(with snapshot: MissionSnapshot) {
        syncAircraft(for: [snapshot.player] + snapshot.enemies)
        syncDamageFeedback(for: snapshot.player)
        updateCamera(for: snapshot.player, mode: cameraMode)
        render(events: snapshot.events)
    }

    func applyEnvironment(weather: WeatherProfile, tone: EnvironmentTone) {
        scene.fogStartDistance = 600 * weather.visibility
        scene.fogEndDistance = 2_000 * weather.visibility
        let clear = SIMD3<Double>(0.19, 0.21, 0.24)
        let storm = SIMD3<Double>(0.12, 0.14, 0.16)
        let mixAmount = weather.stormIntensity
        let fog = mix(clear, storm, t: mixAmount)
        scene.fogColor = UIColor(red: fog.x, green: fog.y, blue: fog.z, alpha: 1)
        let sun: UIColor
        switch tone {
        case .earlyWar:
            sun = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        case .lateWar:
            sun = UIColor(red: 0.72, green: 0.74, blue: 0.78, alpha: 1)
        }
        sunNode.light?.color = sun
        skyNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: fog.x * 0.95, green: fog.y * 1.05, blue: fog.z * 1.25, alpha: 1)
        oceanNode.geometry?.firstMaterial?.roughness.contents = max(0.25, weather.oceanRoughness)
        let visibleClouds = max(1, Int(round(weather.cloudDensity * 9)))
        for (index, cloud) in cloudNodes.enumerated() {
            cloud.isHidden = index >= visibleClouds
            cloud.opacity = CGFloat(0.15 + (weather.cloudDensity * 0.6))
        }
    }

    private func buildScene() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.35, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let sun = SCNLight()
        sun.type = .directional
        sun.color = UIColor(red: 1, green: 0.88, blue: 0.68, alpha: 1)
        sunNode.light = sun
        sunNode.eulerAngles = SCNVector3(-0.7, 0.4, 0)
        scene.rootNode.addChildNode(sunNode)

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 70
        cameraNode.camera?.zFar = 5_000
        cameraNode.camera?.wantsHDR = true
        scene.rootNode.addChildNode(cameraNode)
        scene.fogColor = UIColor(red: 0.19, green: 0.21, blue: 0.24, alpha: 1)
        scene.fogStartDistance = 250
        scene.fogEndDistance = 1_400

        let ocean = SCNFloor()
        ocean.reflectivity = 0.02
        let oceanMaterial = SCNMaterial()
        oceanMaterial.diffuse.contents = UIColor(red: 0.06, green: 0.14, blue: 0.26, alpha: 1)
        oceanMaterial.metalness.contents = 0.1
        oceanMaterial.roughness.contents = 0.55
        if let shader = Self.shader(named: "ocean") {
            oceanMaterial.shaderModifiers = [.surface: shader]
        }
        ocean.materials = [oceanMaterial]
        oceanNode.geometry = ocean
        scene.rootNode.addChildNode(oceanNode)

        let sky = SCNSphere(radius: 1_600)
        let skyMaterial = SCNMaterial()
        skyMaterial.isDoubleSided = true
        skyMaterial.cullMode = .front
        skyMaterial.lightingModel = .constant
        skyMaterial.diffuse.contents = UIColor(red: 0.18, green: 0.22, blue: 0.35, alpha: 1)
        if let shader = Self.shader(named: "sky") {
            skyMaterial.shaderModifiers = [.surface: shader]
        }
        sky.materials = [skyMaterial]
        skyNode.geometry = sky
        scene.rootNode.addChildNode(skyNode)
        buildCloudLayer()
    }

    private func syncAircraft(for combatants: [CombatantState]) {
        let liveIDs = Set(combatants.filter(\.isAlive).map(\.id))
        for (id, node) in aircraftNodes where !liveIDs.contains(id) {
            smokeEmitters[id]?.removeFromParentNode()
            smokeEmitters.removeValue(forKey: id)
            node.removeFromParentNode()
            aircraftNodes.removeValue(forKey: id)
        }

        for combatant in combatants where combatant.isAlive && combatant.isActive {
            let node = aircraftNodes[combatant.id] ?? makeAircraftNode(for: combatant)
            node.position = combatant.position.scnVector
            node.eulerAngles = SCNVector3(Float(-combatant.pitch), Float(-combatant.heading), Float(combatant.roll * 0.45))
            if aircraftNodes[combatant.id] == nil {
                scene.rootNode.addChildNode(node)
                aircraftNodes[combatant.id] = node
            }
        }
    }

    private func syncDamageFeedback(for player: CombatantState) {
        guard let playerNode = aircraftNodes[player.id] else { return }
        if player.damageState.engineLoss > 0.4 {
            if smokeEmitters[player.id] == nil {
                let smoke = SCNNode(geometry: SCNSphere(radius: 0.18))
                smoke.position = SCNVector3(0, 0.15, 1.1)
                smoke.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.3, alpha: 0.8)
                smoke.geometry?.firstMaterial?.lightingModel = .constant
                let pulse = SCNAction.sequence([
                    .fadeOpacity(to: 0.2, duration: 0.15),
                    .fadeOpacity(to: 0.65, duration: 0.3)
                ])
                smoke.runAction(.repeatForever(pulse))
                playerNode.addChildNode(smoke)
                smokeEmitters[player.id] = smoke
            }
        } else if let smoke = smokeEmitters[player.id] {
            smoke.removeFromParentNode()
            smokeEmitters.removeValue(forKey: player.id)
        }
    }

    func updateCamera(for player: CombatantState, mode: CameraMode) {
        switch mode {
        case .chase:
            let offset = (player.forward * -18) + Vector3(x: 0, y: 7, z: 0)
            cameraNode.position = (player.position + offset).scnVector
            cameraNode.look(at: player.position.scnVector)
        case .cockpit:
            let cameraPosition = player.position + (player.forward * 0.8) + Vector3(x: 0, y: 0.3, z: 0)
            let lookTarget = player.position + (player.forward * 10)
            cameraNode.position = cameraPosition.scnVector
            cameraNode.look(at: lookTarget.scnVector)
        }
        skyNode.position = player.position.scnVector
        for (index, cloud) in cloudNodes.enumerated() {
            cloud.position = SCNVector3(
                Float(player.position.x + Double((index * 120) - 300)),
                Float(120 + (index % 3) * 25),
                Float(player.position.z - Double(220 + (index * 55)))
            )
        }
    }

    private func render(events: [CombatEvent]) {
        for event in events {
            switch event.kind {
            case let .shotFired(origin, direction):
                let tracer = SCNNode(geometry: SCNBox(width: 0.08, height: 0.08, length: 16, chamferRadius: 0))
                tracer.geometry?.firstMaterial?.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
                tracer.geometry?.firstMaterial?.lightingModel = .constant
                let end = origin + (direction * 16)
                tracer.position = ((origin + end) / 2).scnVector
                tracer.look(at: end.scnVector)
                tracer.eulerAngles.x += .pi / 2
                scene.rootNode.addChildNode(tracer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    tracer.removeFromParentNode()
                }
            case let .destroyed(targetID):
                let burst = SCNNode(geometry: SCNSphere(radius: 1.6))
                burst.geometry?.firstMaterial?.emission.contents = UIColor(red: 1, green: 0.46, blue: 0.18, alpha: 1)
                burst.geometry?.firstMaterial?.lightingModel = .constant
                burst.position = aircraftNodes[targetID]?.position ?? .zero
                burst.scale = SCNVector3(0.01, 0.01, 0.01)
                scene.rootNode.addChildNode(burst)
                let scale = SCNAction.scale(to: 2.6, duration: 0.25)
                let fade = SCNAction.fadeOut(duration: 0.35)
                let group = SCNAction.group([scale, fade])
                burst.runAction(.sequence([group, .removeFromParentNode()]))
            case let .hit(targetID):
                if let node = aircraftNodes[targetID] {
                    flashHit(on: node)
                }
            case .cinematicBeat:
                break
            }
        }
    }

    private func flashHit(on node: SCNNode) {
        let white = UIColor(red: 1, green: 0.9, blue: 0.8, alpha: 1)
        node.enumerateChildNodes { child, _ in
            guard let material = child.geometry?.firstMaterial else { return }
            let original = material.emission.contents
            let on = SCNAction.run { _ in material.emission.contents = white }
            let off = SCNAction.run { _ in material.emission.contents = original }
            child.runAction(.sequence([on, .wait(duration: 0.08), off]))
        }
    }

    private func makeAircraftNode(for combatant: CombatantState) -> SCNNode {
        let root = SCNNode()
        let id = combatant.aircraft.id
        let alliedBody = UIColor(red: 0.52, green: 0.60, blue: 0.68, alpha: 1)
        let alliedWing = UIColor(red: 0.38, green: 0.48, blue: 0.58, alpha: 1)
        let japaneseBody = UIColor(red: 0.42, green: 0.34, blue: 0.24, alpha: 1)
        let japaneseWing = UIColor(red: 0.33, green: 0.28, blue: 0.2, alpha: 1)

        let fuselageLength: CGFloat
        let wingWidth: CGFloat
        let bodyColor: UIColor
        let wingColor: UIColor
        switch id {
        case "f4f_wildcat", "f6f_hellcat", "sbd_dauntless":
            fuselageLength = id == "sbd_dauntless" ? 2.9 : 2.6
            wingWidth = id == "f6f_hellcat" ? 3.7 : 3.4
            bodyColor = alliedBody
            wingColor = alliedWing
        case "a6m_zero", "n1k2j_shinden":
            fuselageLength = id == "n1k2j_shinden" ? 2.8 : 2.55
            wingWidth = 3.45
            bodyColor = japaneseBody
            wingColor = japaneseWing
        case "ki84_hayate":
            fuselageLength = 2.75
            wingWidth = 3.3
            bodyColor = japaneseBody
            wingColor = japaneseWing
        case "f4u_corsair":
            fuselageLength = 2.9
            wingWidth = 3.8
            bodyColor = alliedBody
            wingColor = alliedWing
        default:
            fuselageLength = 2.6
            wingWidth = 3.3
            bodyColor = alliedBody
            wingColor = alliedWing
        }

        let fuselage = SCNNode(geometry: SCNCapsule(capRadius: 0.18, height: fuselageLength))
        fuselage.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        fuselage.geometry?.materials = [makeMaterial(color: bodyColor)]
        root.addChildNode(fuselage)

        if id == "a6m_zero" || id == "n1k2j_shinden" {
            let wings = SCNNode(geometry: SCNCapsule(capRadius: 0.08, height: wingWidth))
            wings.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            wings.scale = SCNVector3(1.0, 0.3, 1.0)
            wings.position = SCNVector3(0, 0, -0.05)
            wings.geometry?.materials = [makeMaterial(color: wingColor)]
            root.addChildNode(wings)
        } else if id == "f4u_corsair" {
            for side in [-1.0, 1.0] {
                let innerWing = SCNNode(geometry: SCNBox(width: wingWidth * 0.28, height: 0.06, length: 0.65, chamferRadius: 0.03))
                innerWing.position = SCNVector3(Float(side * 0.55), 0.05, -0.08)
                innerWing.eulerAngles = SCNVector3(0, 0, Float(side * -0.25))
                innerWing.geometry?.materials = [makeMaterial(color: wingColor)]
                root.addChildNode(innerWing)

                let tipWing = SCNNode(geometry: SCNBox(width: wingWidth * 0.26, height: 0.06, length: 0.55, chamferRadius: 0.03))
                tipWing.position = SCNVector3(Float(side * 1.25), -0.12, -0.08)
                tipWing.eulerAngles = SCNVector3(0, 0, Float(side * 0.22))
                tipWing.geometry?.materials = [makeMaterial(color: wingColor)]
                root.addChildNode(tipWing)
            }
        } else {
            let wings = SCNNode(geometry: SCNBox(width: wingWidth, height: 0.06, length: 0.62, chamferRadius: 0.04))
            wings.position = SCNVector3(0, 0, -0.08)
            wings.geometry?.materials = [makeMaterial(color: wingColor)]
            root.addChildNode(wings)
        }

        let tail = SCNNode(geometry: SCNBox(width: 1.1, height: 0.05, length: 0.4, chamferRadius: 0.02))
        tail.position = SCNVector3(0, 0.28, Float(fuselageLength * 0.34))
        tail.geometry?.materials = [makeMaterial(color: wingColor)]
        root.addChildNode(tail)

        let fin = SCNNode(geometry: SCNBox(width: 0.08, height: 0.42, length: 0.28, chamferRadius: 0.02))
        fin.position = SCNVector3(0, 0.28, Float(fuselageLength * 0.43))
        fin.geometry?.materials = [makeMaterial(color: wingColor)]
        root.addChildNode(fin)

        let noseRadius: CGFloat = id == "ki84_hayate" ? 0.24 : 0.2
        let nose = SCNNode(geometry: SCNSphere(radius: noseRadius))
        nose.position = SCNVector3(0, 0, Float(-fuselageLength * 0.5))
        nose.scale = SCNVector3(1, 0.7, 1.1)
        nose.geometry?.materials = [makeMaterial(color: bodyColor)]
        root.addChildNode(nose)

        let prop = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.9))
        prop.position = SCNVector3(0, 0, Float(-fuselageLength * 0.58))
        prop.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        prop.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.9, alpha: 0.4)
        root.addChildNode(prop)

        return root
    }

    private func makeMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.metalness.contents = 0.3
        material.roughness.contents = 0.6
        material.lightingModel = .physicallyBased
        return material
    }

    private func buildCloudLayer() {
        for _ in 0..<9 {
            let cloud = SCNNode(geometry: SCNPlane(width: 180, height: 72))
            cloud.geometry?.firstMaterial?.isDoubleSided = true
            cloud.geometry?.firstMaterial?.diffuse.contents = UIColor(white: 0.82, alpha: 0.22)
            cloud.geometry?.firstMaterial?.lightingModel = .constant
            if let shader = Self.shader(named: "clouds") {
                cloud.geometry?.firstMaterial?.shaderModifiers = [.surface: shader]
            }
            cloud.eulerAngles.x = -.pi / 2.7
            cloud.opacity = 0.72
            cloudNodes.append(cloud)
            scene.rootNode.addChildNode(cloud)
        }
    }

    private static func shader(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "shader") else {
            return nil
        }
        return try? String(contentsOf: url)
    }

    private func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, t: Double) -> SIMD3<Double> {
        a + ((b - a) * t)
    }
}

private extension Vector3 {
    var scnVector: SCNVector3 {
        SCNVector3(Float(x), Float(y), Float(z))
    }
}
