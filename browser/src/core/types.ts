export class Vector3 {
  constructor(public x = 0, public y = 0, public z = 0) {}

  get length(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z)
  }

  get normalized(): Vector3 {
    const magnitude = Math.max(this.length, 0.0001)
    return this.scale(1 / magnitude)
  }

  add(rhs: Vector3): Vector3 { return new Vector3(this.x + rhs.x, this.y + rhs.y, this.z + rhs.z) }
  sub(rhs: Vector3): Vector3 { return new Vector3(this.x - rhs.x, this.y - rhs.y, this.z - rhs.z) }
  scale(rhs: number): Vector3 { return new Vector3(this.x * rhs, this.y * rhs, this.z * rhs) }
  static dot(lhs: Vector3, rhs: Vector3): number { return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z }
  static from(obj: { x: number; y: number; z: number }): Vector3 { return new Vector3(obj.x, obj.y, obj.z) }
}

export enum Team { player = 'player', enemy = 'enemy' }
export enum EnvironmentTone { earlyWar = 'earlyWar', lateWar = 'lateWar' }
export enum AIRole { intercept = 'intercept', patrol = 'patrol', formationWing = 'formationWing', retreat = 'retreat' }
export enum UpgradeEffectType { fuelLeakReduction = 'fuelLeakReduction', steeringAuthority = 'steeringAuthority', engineCeiling = 'engineCeiling', stabilityDamping = 'stabilityDamping', aimAssist = 'aimAssist' }

export interface Armament { ammoCapacity: number; fireCooldown: number; damagePerHit: number; effectiveRange: number }
export interface AircraftBlueprint { id: string; displayName: string; cruiseSpeed: number; maxSpeed: number; throttleResponse: number; turnRate: number; climbRate: number; durability: number; armament: Armament; unlockedByDefault: boolean }
export interface NavalAAEmitter { position: { x: number; y: number; z: number }; range: number; fireRate: number; damagePerRound: number }
export interface SpawnDefinition { id: string; aircraftID: string; team: Team; position: { x: number; y: number; z: number }; heading: number; pitch: number; cinematicIntroDelay: number; aiRole: AIRole }
export type ObjectiveDefinition = { type: 'destroyAllEnemies' } | { type: 'survive'; seconds: number } | { type: 'escort'; timeLimit: number }
export interface CinematicBeat { id: string; triggerTime: number; title: string; body: string }
export interface MissionDefinition { id: string; title: string; subtitle: string; briefing: string; debrief: string; recommendedAircraftID: string; missionDuration: number; archiveRewardID: string; aircraftRewardID: string | null; weatherProfileID: string; environmentTone: EnvironmentTone; upgradeRewardID: string | null; objectives: ObjectiveDefinition[]; playerSpawn: SpawnDefinition; enemySpawns: SpawnDefinition[]; cinematicBeats: CinematicBeat[]; navalAAEmitters: NavalAAEmitter[] }
export interface ArchiveEntry { id: string; title: string; category: string; unlockedByDefault: boolean; body: string }
export interface WeatherProfile { id: string; displayName: string; visibility: number; windIntensity: number; stormIntensity: number; cloudDensity: number; oceanRoughness: number; antiAircraftPressure: number }
export interface UpgradeDefinition { id: string; displayName: string; effectType: UpgradeEffectType; magnitude: number }

export class DamageState {
  constructor(
    public steeringLoss = 0,
    public visibilityLoss = 0,
    public engineLoss = 0,
    public fuelLeak = 0,
    public stabilityLoss = 0,
  ) {}

  applyHit(normalizedSeverity: number): void {
    const severity = clamp(normalizedSeverity, 0.03, 0.35)
    this.steeringLoss = clamp(this.steeringLoss + severity * 0.75, 0, 1)
    this.visibilityLoss = clamp(this.visibilityLoss + severity * 0.45, 0, 1)
    this.engineLoss = clamp(this.engineLoss + severity * 0.65, 0, 1)
    this.fuelLeak = clamp(this.fuelLeak + severity * 0.55, 0, 1)
    this.stabilityLoss = clamp(this.stabilityLoss + severity * 0.8, 0, 1)
  }
}

export interface PilotInput { throttle: number; pitch: number; yaw: number; roll: number; firing: boolean }
export interface CombatantState { id: string; aircraft: AircraftBlueprint; team: Team; position: Vector3; heading: number; pitch: number; roll: number; throttle: number; health: number; ammo: number; fuelRemaining: number; damageState: DamageState; weaponCooldownRemaining: number; isPlayer: boolean; isActive: boolean }
export type CombatEvent =
  | { id: string; time: number; kind: 'shotFired'; origin: Vector3; direction: Vector3 }
  | { id: string; time: number; kind: 'hit'; targetID: string }
  | { id: string; time: number; kind: 'destroyed'; targetID: string }
  | { id: string; time: number; kind: 'cinematicBeat'; beatID: string; title: string; body: string }
export type MissionOutcome = 'inProgress' | 'success' | 'failure'
export interface MissionSnapshot { time: number; outcome: MissionOutcome; player: CombatantState; enemies: CombatantState[]; events: CombatEvent[]; objectiveSummary: string[] }

export const clamp = (value: number, lower: number, upper: number): number => Math.min(Math.max(value, lower), upper)
export const pristineDamageState = (): DamageState => new DamageState()
export const defaultPilotInput = (): PilotInput => ({ throttle: 0, pitch: 0, yaw: 0, roll: 0, firing: false })
