import SwiftUI
import SceneKit
import Kamikaze

@MainActor
final class FlightSceneRenderer: ObservableObject {
    let scene: SCNScene
    let cameraNode = SCNNode()

    private let oceanNode = SCNNode()
    private let skyNode = SCNNode()
    private var cloudNodes: [SCNNode] = []
    private var aircraftNodes: [String: SCNNode] = [:]

    init() {
        scene = SCNScene()
        buildScene()
    }

    func update(with snapshot: MissionSnapshot) {
        syncAircraft(for: [snapshot.player] + snapshot.enemies)
        updateCamera(for: snapshot.player)
        render(events: snapshot.events)
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
        let sunNode = SCNNode()
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
            node.removeFromParentNode()
            aircraftNodes.removeValue(forKey: id)
        }

        for combatant in combatants where combatant.isAlive && combatant.isActive {
            let node = aircraftNodes[combatant.id] ?? makeAircraftNode(for: combatant)
            node.position = combatant.position.scnVector
            node.eulerAngles = SCNVector3(Float(-combatant.pitch), Float(-combatant.heading), 0)
            if aircraftNodes[combatant.id] == nil {
                scene.rootNode.addChildNode(node)
                aircraftNodes[combatant.id] = node
            }
        }
    }

    private func updateCamera(for player: CombatantState) {
        let offset = (player.forward * -18) + Vector3(x: 0, y: 7, z: 0)
        cameraNode.position = (player.position + offset).scnVector
        cameraNode.look(at: player.position.scnVector)
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
            case .destroyed:
                let burst = SCNNode(geometry: SCNSphere(radius: 1.6))
                burst.geometry?.firstMaterial?.emission.contents = UIColor(red: 1, green: 0.46, blue: 0.18, alpha: 1)
                burst.geometry?.firstMaterial?.lightingModel = .constant
                burst.scale = SCNVector3(0.01, 0.01, 0.01)
                scene.rootNode.addChildNode(burst)
                let scale = SCNAction.scale(to: 2.6, duration: 0.25)
                let fade = SCNAction.fadeOut(duration: 0.35)
                let group = SCNAction.group([scale, fade])
                burst.runAction(.sequence([group, .removeFromParentNode()]))
            case .hit, .cinematicBeat:
                break
            }
        }
    }

    private func makeAircraftNode(for combatant: CombatantState) -> SCNNode {
        let root = SCNNode()

        let fuselage = SCNNode(geometry: SCNBox(width: 0.75, height: 0.35, length: 2.6, chamferRadius: 0.1))
        fuselage.geometry?.firstMaterial?.diffuse.contents = combatant.isPlayer ? UIColor(red: 0.63, green: 0.73, blue: 0.8, alpha: 1) : UIColor(red: 0.63, green: 0.25, blue: 0.18, alpha: 1)
        root.addChildNode(fuselage)

        let wings = SCNNode(geometry: SCNBox(width: 3.3, height: 0.05, length: 0.6, chamferRadius: 0.04))
        wings.position = SCNVector3(0, 0, -0.1)
        wings.geometry?.firstMaterial?.diffuse.contents = combatant.isPlayer ? UIColor(red: 0.47, green: 0.57, blue: 0.63, alpha: 1) : UIColor(red: 0.46, green: 0.17, blue: 0.12, alpha: 1)
        root.addChildNode(wings)

        let tail = SCNNode(geometry: SCNBox(width: 1.1, height: 0.05, length: 0.4, chamferRadius: 0.02))
        tail.position = SCNVector3(0, 0.3, 0.9)
        tail.geometry?.firstMaterial?.diffuse.contents = wings.geometry?.firstMaterial?.diffuse.contents
        root.addChildNode(tail)

        let prop = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.9))
        prop.position = SCNVector3(0, 0, -1.4)
        prop.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        prop.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.9, alpha: 0.4)
        root.addChildNode(prop)

        return root
    }

    private func buildCloudLayer() {
        for index in 0..<9 {
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
            _ = index
        }
    }

    private static func shader(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "shader") else {
            return nil
        }
        return try? String(contentsOf: url)
    }
}

private extension Vector3 {
    var scnVector: SCNVector3 {
        SCNVector3(Float(x), Float(y), Float(z))
    }
}
