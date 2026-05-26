import * as THREE from 'three'
import { CombatEvent, CombatantState, EnvironmentTone, MissionSnapshot, Vector3, WeatherProfile } from '../core/types'

export class FlightRenderer {
  scene = new THREE.Scene()
  camera = new THREE.PerspectiveCamera(70, 1, 0.1, 5000)
  renderer = new THREE.WebGLRenderer({ antialias: true })
  private aircraftNodes = new Map<string, THREE.Object3D>()
  private cloudNodes: THREE.Mesh[] = []
  private directional = new THREE.DirectionalLight(0xffe0ba, 1.5)
  private hemisphere = new THREE.HemisphereLight(0x9bb7ff, 0x1c2733, 0.85)
  private ocean!: THREE.Mesh
  private sky!: THREE.Mesh
  private oceanWaveIntensity = 1
  private oceanWaveSpeed = 1
  private oceanBaseHeights!: Float32Array
  private wavePhase = 0
  private lastRenderTime = performance.now()
  private cameraLookTarget = new THREE.Vector3(0, 0, -1)
  private combatFX: { mesh: THREE.Mesh; life: number; maxLife: number; growth: number }[] = []

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
    ;(this.sky.material as THREE.MeshBasicMaterial).color = skyColor.clone().offsetHSL(0, 0.08, 0.06)
    this.directional.color = tone === EnvironmentTone.earlyWar ? new THREE.Color(1, 0.88, 0.68) : new THREE.Color(0.72, 0.74, 0.78)
    this.hemisphere.intensity = 0.7 + weather.visibility * 0.35
    ;(this.ocean.material as THREE.MeshStandardMaterial).roughness = Math.min(1, 0.4 + weather.oceanRoughness * 0.4)
    ;(this.ocean.material as THREE.MeshStandardMaterial).metalness = 0.18 + weather.visibility * 0.12
    this.oceanWaveIntensity = 0.8 + weather.oceanRoughness * 4
    this.oceanWaveSpeed = 0.6 + weather.windIntensity * 2.2
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
    this.scene.add(this.hemisphere)
    this.directional.position.set(200, 240, 160)
    this.scene.add(this.directional)

    const oceanGeometry = new THREE.PlaneGeometry(4000, 4000, 72, 72)
    const oceanPositions = oceanGeometry.attributes.position as THREE.BufferAttribute
    this.oceanBaseHeights = new Float32Array(oceanPositions.count)
    for (let index = 0; index < oceanPositions.count; index += 1) this.oceanBaseHeights[index] = oceanPositions.getZ(index)
    this.ocean = new THREE.Mesh(
      oceanGeometry,
      new THREE.MeshStandardMaterial({ color: 0x15304d, roughness: 0.55, metalness: 0.1, emissive: 0x08131f, emissiveIntensity: 0.25 }),
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
    const desiredPosition = new THREE.Vector3()
    const desiredLook = playerPosition.clone().add(forward.clone().multiplyScalar(10))
    if (mode === 'cockpit') {
      desiredPosition.copy(playerPosition.clone().add(forward.clone().multiplyScalar(0.8)).add(new THREE.Vector3(0, 0.3, 0)))
    } else {
      desiredPosition.copy(playerPosition.clone().add(forward.clone().multiplyScalar(-18)).add(new THREE.Vector3(0, 7, 0)))
      desiredLook.copy(playerPosition.clone().add(forward.clone().multiplyScalar(7)))
    }
    const smoothing = mode === 'cockpit' ? 0.28 : 0.15
    this.camera.position.lerp(desiredPosition, smoothing)
    this.cameraLookTarget.lerp(desiredLook, smoothing + 0.04)
    this.camera.lookAt(this.cameraLookTarget)
    this.sky.position.copy(playerPosition)
    const cloudDrift = this.wavePhase * 45
    this.cloudNodes.forEach((cloud, index) => {
      cloud.position.set(
        player.position.x + index * 120 - 300 + cloudDrift * (0.2 + index * 0.04),
        120 + (index % 3) * 25 + Math.sin(this.wavePhase * 0.9 + index) * 5,
        player.position.z - (220 + index * 55),
      )
    })
  }

  private renderEvents(events: CombatEvent[]): void {
    events.forEach((event) => {
      if (event.kind === 'shotFired') {
        const tracer = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.08, 16), new THREE.MeshBasicMaterial({ color: 0xffdd55, transparent: true, opacity: 0.95 }))
        const origin = new THREE.Vector3(event.origin.x, event.origin.y, event.origin.z)
        const direction = new THREE.Vector3(event.direction.x, event.direction.y, event.direction.z).normalize()
        tracer.position.copy(origin.clone().add(direction.clone().multiplyScalar(8)))
        tracer.lookAt(origin.clone().add(direction.clone().multiplyScalar(16)))
        this.scene.add(tracer)
        this.combatFX.push({ mesh: tracer, life: 0.12, maxLife: 0.12, growth: 0.2 })
      }
      if (event.kind === 'hit') {
        const node = this.aircraftNodes.get(event.targetID)
        if (!node) return
        const impact = new THREE.Mesh(new THREE.SphereGeometry(0.45, 8, 8), new THREE.MeshBasicMaterial({ color: 0xff7a45, transparent: true, opacity: 0.9 }))
        impact.position.copy(node.position)
        this.scene.add(impact)
        this.combatFX.push({ mesh: impact, life: 0.22, maxLife: 0.22, growth: 3.8 })
      }
      if (event.kind === 'destroyed') {
        const node = this.aircraftNodes.get(event.targetID)
        if (!node) return
        const blast = new THREE.Mesh(new THREE.SphereGeometry(1.2, 10, 10), new THREE.MeshBasicMaterial({ color: 0xffc87b, transparent: true, opacity: 0.95 }))
        blast.position.copy(node.position)
        this.scene.add(blast)
        this.combatFX.push({ mesh: blast, life: 0.5, maxLife: 0.5, growth: 8 })
      }
    })
  }

  animate(): void {
    requestAnimationFrame(() => this.animate())
    const now = performance.now()
    const deltaTime = Math.min(0.05, (now - this.lastRenderTime) / 1000)
    this.lastRenderTime = now
    this.wavePhase += deltaTime * this.oceanWaveSpeed
    this.animateOcean()
    this.updateCombatFX(deltaTime)
    this.renderer.render(this.scene, this.camera)
  }

  resize(): void {
    const width = this.host.clientWidth || window.innerWidth
    const height = this.host.clientHeight || window.innerHeight
    this.camera.aspect = width / Math.max(height, 1)
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(width, height)
  }

  private animateOcean(): void {
    const positions = (this.ocean.geometry as THREE.PlaneGeometry).attributes.position as THREE.BufferAttribute
    for (let index = 0; index < positions.count; index += 1) {
      const x = positions.getX(index)
      const y = positions.getY(index)
      const wave = Math.sin((x * 0.009) + this.wavePhase) * 0.6 + Math.cos((y * 0.012) - this.wavePhase * 0.8) * 0.4
      positions.setZ(index, this.oceanBaseHeights[index] + wave * this.oceanWaveIntensity)
    }
    positions.needsUpdate = true
  }

  private updateCombatFX(deltaTime: number): void {
    for (let index = this.combatFX.length - 1; index >= 0; index -= 1) {
      const fx = this.combatFX[index]
      fx.life -= deltaTime
      fx.mesh.scale.multiplyScalar(1 + fx.growth * deltaTime)
      const material = fx.mesh.material as THREE.MeshBasicMaterial
      material.opacity = Math.max(0, fx.life / fx.maxLife)
      if (fx.life <= 0) {
        this.scene.remove(fx.mesh)
        this.combatFX.splice(index, 1)
      }
    }
  }
}
