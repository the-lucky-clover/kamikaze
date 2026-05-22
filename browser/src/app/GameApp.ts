import { GameSimulation, BrowserAimAssistLevel } from '../core/simulation'
import { AIRole, AircraftBlueprint, EnvironmentTone, MissionDefinition, Team, UpgradeDefinition, WeatherProfile } from '../core/types'
import { InputManager } from '../input/InputManager'
import { FlightRenderer } from '../renderer/FlightRenderer'
import { HUD } from '../ui/HUD'

const fallbackAircraft: AircraftBlueprint[] = [
  { id: 'f4f_wildcat', displayName: 'F4F Wildcat', cruiseSpeed: 90, maxSpeed: 155, throttleResponse: 0.95, turnRate: 0.8, climbRate: 22, durability: 120, armament: { ammoCapacity: 480, fireCooldown: 0.15, damagePerHit: 18, effectiveRange: 240 }, unlockedByDefault: true },
  { id: 'a6m_zero', displayName: 'A6M Zero', cruiseSpeed: 98, maxSpeed: 165, throttleResponse: 1.05, turnRate: 0.92, climbRate: 26, durability: 100, armament: { ammoCapacity: 420, fireCooldown: 0.14, damagePerHit: 16, effectiveRange: 230 }, unlockedByDefault: false },
]
const fallbackWeather: WeatherProfile[] = [
  { id: 'golden_pacific', displayName: 'Golden Pacific', visibility: 0.9, windIntensity: 0.2, stormIntensity: 0.1, cloudDensity: 0.3, oceanRoughness: 0.22, antiAircraftPressure: 0.35 },
]
const fallbackUpgrades: UpgradeDefinition[] = []
const fallbackMissions: MissionDefinition[] = [{
  id: 'embers_over_midway', title: 'Embers Over Midway', subtitle: 'Hold the dawn long enough for the fleet to breathe.', briefing: 'Fallback mission briefing.', debrief: 'Fallback debrief.', recommendedAircraftID: 'f4f_wildcat', missionDuration: 240, archiveRewardID: 'midway_letters', aircraftRewardID: null, weatherProfileID: 'golden_pacific', environmentTone: EnvironmentTone.earlyWar, upgradeRewardID: null,
  objectives: [{ type: 'destroyAllEnemies' }, { type: 'survive', seconds: 90 }],
  playerSpawn: { id: 'player', aircraftID: 'f4f_wildcat', team: Team.player, position: { x: 0, y: 40, z: 0 }, heading: 0, pitch: 0, cinematicIntroDelay: 0, aiRole: AIRole.intercept },
  enemySpawns: [{ id: 'zero_lead', aircraftID: 'a6m_zero', team: Team.enemy, position: { x: -120, y: 55, z: -360 }, heading: 0.35, pitch: 0, cinematicIntroDelay: 4, aiRole: AIRole.intercept }],
  cinematicBeats: [{ id: 'fallback', triggerTime: 1, title: 'Fallback', body: 'Loaded inline fallback data.' }],
  navalAAEmitters: [],
}]

async function loadJSON<T>(candidates: string[], fallback: T): Promise<T> {
  for (const candidate of candidates) {
    try {
      const response = await fetch(candidate)
      if (response.ok) return await response.json() as T
    } catch {}
  }
  return fallback
}

export class GameApp {
  private renderer!: FlightRenderer
  private hud!: HUD
  private input!: InputManager
  private simulation!: GameSimulation
  private weather!: WeatherProfile
  private cameraMode: 'chase' | 'cockpit' = 'chase'
  private lastFrame = performance.now()

  constructor(private host: HTMLElement) {
    this.host.style.position = 'relative'
    this.host.style.width = '100%'
    this.host.style.height = '100%'
  }

  async start(): Promise<void> {
    const [missions, aircraft, weather, upgrades] = await Promise.all([
      loadJSON<MissionDefinition[]>(['../missions/missions.json', '../../missions/missions.json'], fallbackMissions),
      loadJSON<AircraftBlueprint[]>(['../gameplay/aircraft.json', '../../gameplay/aircraft.json'], fallbackAircraft),
      loadJSON<WeatherProfile[]>(['../weather/presets.json', '../../weather/presets.json'], fallbackWeather),
      loadJSON<UpgradeDefinition[]>(['../gameplay/upgrades.json', '../../gameplay/upgrades.json'], fallbackUpgrades),
    ])
    const mission = missions[0]
    const selectedAircraft = aircraft.find((candidate) => candidate.id === mission.recommendedAircraftID) ?? aircraft[0]
    this.weather = weather.find((candidate) => candidate.id === mission.weatherProfileID) ?? weather[0]
    this.renderer = new FlightRenderer(this.host)
    this.hud = new HUD(this.host)
    this.input = new InputManager(this.renderer.renderer.domElement)
    this.simulation = new GameSimulation(mission, selectedAircraft, aircraft, weather, upgrades, [], 'standard' satisfies BrowserAimAssistLevel)
    this.renderer.applyEnvironment(this.weather, mission.environmentTone)
    window.addEventListener('keydown', (event) => {
      if (event.key.toLowerCase() === 'c') this.cameraMode = this.cameraMode === 'chase' ? 'cockpit' : 'chase'
    })
    requestAnimationFrame((time) => this.loop(time))
  }

  private loop(time: number): void {
    const deltaTime = Math.min(0.1, (time - this.lastFrame) / 1000)
    this.lastFrame = time
    const input = this.input.getInput()
    this.simulation.advance(input, deltaTime)
    const snapshot = this.simulation.snapshot
    this.renderer.update(snapshot, this.cameraMode)
    this.hud.update(snapshot, this.weather.stormIntensity)
    snapshot.events.forEach((event) => this.hud.showEvent(event))
    requestAnimationFrame((next) => this.loop(next))
  }
}
