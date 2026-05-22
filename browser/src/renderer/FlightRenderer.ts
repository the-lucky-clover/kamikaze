import * as THREE from 'three'
import { CombatEvent, CombatantState, EnvironmentTone, MissionSnapshot, Vector3, WeatherProfile } from '../core/types'

export class FlightRenderer {
  scene = new THREE.Scene()
  camera = new THREE.PerspectiveCamera(70, 1, 0.1, 5000)
  renderer = new THREE.WebGLRenderer({ antialias: true })
  private aircraftNodes = new Map<string, THREE.Object3D>()
  private cloudNodes: THREE.Mesh[] = []
  private directional = new THREE.DirectionalLight(0xffe0ba, 1.5)
  private ocean!: THREE.Mesh
  private sky!: THREE.Mesh

  constructor(private host: HTMLElement) {
    // WebGPU could be added later; WebGL is used as the stable fallback.
    this.renderer.setPixelRatio(window.devicePixelRatio)
    this.renderer.setSize(host.clientWidth || window.innerWidth, host.clientHeight || window.innerHeight)
    host.appendChild(this.renderer.domElement)
    this.buildScene()
    window.addEventListener('resize', () => this.resize())
    this.animate()
  }

  applyEnvironment(weather: WeatherProfile, tone: EnvironmentTone): void {
    this.scene.fog = new THREE.Fog(0x20252d, 600 * weather.visibility, 2000 * weather.visibility)
    const skyColor = tone === EnvironmentTone.earlyWar ? new THREE.Color(0x4a5d78) : new THREE.Color(0x2a313a)
    this.scene.background = skyColor
    this.directional.color = tone === EnvironmentTone.earlyWar ? new THREE.Color(1, 0.88, 0.68) : new THREE.Color(0.72, 0.74, 0.78)
    ;(this.ocean.material as THREE.MeshStandardMaterial).roughness = Math.min(1, 0.4 + weather.oceanRoughness * 0.4)
    const visible = Math.max(1, Math.round(weather.cloudDensity * 9))
    this.cloudNodes.forEach((cloud, index) => {
      cloud.visible = index < visible
      ;(cloud.material as THREE.MeshBasicMaterial).opacity = 0.15 + weather.cloudDensity * 0.45
    })
  }

  update(snapshot: MissionSnapshot, cameraMode: 'chase' | 'cockpit'): void {
    const combatants = [snapshot.player, ...snapshot.enemies].filter((combatant) => combatant.isActive && combatant.health > 0)
    const liveIDs = new Set(combatants.map((combatant) => combatant.id))
    for (const [id, node] of this.aircraftNodes.entries()) {
      if (!liveIDs.has(id)) {
        this.scene.remove(node)
        this.aircraftNodes.delete(id)
      }
    }
    combatants.forEach((combatant) => {
      let node = this.aircraftNodes.get(combatant.id)
      if (!node) {
        node = this.makeAircraftNode(combatant)
        this.aircraftNodes.set(combatant.id, node)
        this.scene.add(node)
      }
      node.position.set(combatant.position.x, combatant.position.y, combatant.position.z)
      node.rotation.set(-combatant.pitch, -combatant.heading, combatant.roll * 0.45)
    })
    this.updateCamera(snapshot.player, cameraMode)
    this.renderEvents(snapshot.events)
  }

  private buildScene(): void {
    this.scene.add(new THREE.AmbientLight(0xffffff, 0.55))
    this.directional.position.set(200, 240, 160)
    this.scene.add(this.directional)

    this.ocean = new THREE.Mesh(
      new THREE.PlaneGeometry(4000, 4000, 10, 10),
      new THREE.MeshStandardMaterial({ color: 0x15304d, roughness: 0.55, metalness: 0.1 }),
    )
    this.ocean.rotation.x = -Math.PI / 2
    this.scene.add(this.ocean)

    this.sky = new THREE.Mesh(
      new THREE.SphereGeometry(1800, 24, 24),
      new THREE.MeshBasicMaterial({ color: 0x304466, side: THREE.BackSide }),
    )
    this.scene.add(this.sky)

    const cloudGeometry = new THREE.PlaneGeometry(180, 72)
    for (let index = 0; index < 9; index += 1) {
      const cloud = new THREE.Mesh(cloudGeometry, new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.28, depthWrite: false }))
      cloud.rotation.x = -Math.PI / 2.7
      this.cloudNodes.push(cloud)
      this.scene.add(cloud)
    }
  }

  private makeAircraftNode(combatant: CombatantState): THREE.Object3D {
    const group = new THREE.Group()
    const allied = new THREE.Color(0x7d8ea5)
    const alliedWing = new THREE.Color(0x63758b)
    const japanese = new THREE.Color(0x6a5944)
    const japaneseWing = new THREE.Color(0x574837)
    const material = (color: THREE.Color) => new THREE.MeshStandardMaterial({ color, metalness: 0.3, roughness: 0.6 })
    const isAllied = ['f4f_wildcat', 'f6f_hellcat', 'sbd_dauntless', 'f4u_corsair'].includes(combatant.aircraft.id)

    const fuselage = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.32, combatant.aircraft.id === 'f4u_corsair' ? 2.9 : 2.6), material(isAllied ? allied : japanese))
    group.add(fuselage)

    if (combatant.aircraft.id === 'f4u_corsair') {
      for (const side of [-1, 1]) {
        const inner = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.05, 0.6), material(alliedWing))
        inner.position.set(side * 0.55, 0.06, -0.08)
        inner.rotation.z = side * -0.25
        group.add(inner)
        const tip = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.05, 0.56), material(alliedWing))
        tip.position.set(side * 1.25, -0.1, -0.08)
        tip.rotation.z = side * 0.22
        group.add(tip)
      }
    } else if (['a6m_zero', 'n1k2j_shinden'].includes(combatant.aircraft.id)) {
      const wings = new THREE.Mesh(new THREE.CapsuleGeometry(0.08, 3.1, 4, 8), material(japaneseWing))
      wings.rotation.z = Math.PI / 2
      wings.scale.set(1, 0.3, 1)
      group.add(wings)
    } else {
      const wings = new THREE.Mesh(new THREE.BoxGeometry(combatant.aircraft.id === 'f6f_hellcat' ? 3.8 : 3.4, 0.05, 0.62), material(isAllied ? alliedWing : japaneseWing))
      wings.position.z = -0.08
      group.add(wings)
    }

    const tail = new THREE.Mesh(new THREE.BoxGeometry(1.1, 0.05, 0.4), material(isAllied ? alliedWing : japaneseWing))
    tail.position.set(0, 0.28, 0.9)
    group.add(tail)
    const fin = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.42, 0.28), material(isAllied ? alliedWing : japaneseWing))
    fin.position.set(0, 0.3, 1.06)
    group.add(fin)

    return group
  }

  private updateCamera(player: CombatantState, mode: 'chase' | 'cockpit'): void {
    const playerPosition = new THREE.Vector3(player.position.x, player.position.y, player.position.z)
    const forward = new THREE.Vector3(Math.sin(player.heading) * Math.cos(player.pitch), Math.sin(player.pitch), -Math.cos(player.heading) * Math.cos(player.pitch)).normalize()
    if (mode === 'cockpit') {
      this.camera.position.copy(playerPosition.clone().add(forward.clone().multiplyScalar(0.8)).add(new THREE.Vector3(0, 0.3, 0)))
      this.camera.lookAt(playerPosition.clone().add(forward.clone().multiplyScalar(10)))
    } else {
      this.camera.position.copy(playerPosition.clone().add(forward.clone().multiplyScalar(-18)).add(new THREE.Vector3(0, 7, 0)))
      this.camera.lookAt(playerPosition)
    }
    this.sky.position.copy(playerPosition)
    this.cloudNodes.forEach((cloud, index) => {
      cloud.position.set(player.position.x + index * 120 - 300, 120 + (index % 3) * 25, player.position.z - (220 + index * 55))
    })
  }

  private renderEvents(events: CombatEvent[]): void {
    events.forEach((event) => {
      if (event.kind === 'shotFired') {
        const tracer = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 16), new THREE.MeshBasicMaterial({ color: 0xffdd55 }))
        const origin = new THREE.Vector3(event.origin.x, event.origin.y, event.origin.z)
        const direction = new THREE.Vector3(event.direction.x, event.direction.y, event.direction.z).normalize()
        tracer.position.copy(origin.clone().add(direction.clone().multiplyScalar(8)))
        tracer.lookAt(origin.clone().add(direction.clone().multiplyScalar(16)))
        this.scene.add(tracer)
        setTimeout(() => this.scene.remove(tracer), 120)
      }
    })
  }

  animate(): void {
    requestAnimationFrame(() => this.animate())
    this.renderer.render(this.scene, this.camera)
  }

  resize(): void {
    const width = this.host.clientWidth || window.innerWidth
    const height = this.host.clientHeight || window.innerHeight
    this.camera.aspect = width / Math.max(height, 1)
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(width, height)
  }
}
