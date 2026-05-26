import { CombatEvent, MissionOutcome, MissionSnapshot } from '../core/types'

export class HUD {
  private root = document.createElement('div')
  private stats = document.createElement('div')
  private cinematic = document.createElement('div')
  private objectives = document.createElement('div')
  private outcome = document.createElement('div')
  private alerts = document.createElement('div')
  private reticle = document.createElement('div')
  private tactical = document.createElement('canvas')
  private typingTimer: number | undefined

  constructor(host: HTMLElement) {
    Object.assign(this.root.style, { position: 'absolute', inset: '0', pointerEvents: 'none', color: '#fff', padding: '16px' })
    Object.assign(this.stats.style, { position: 'absolute', left: '16px', top: '16px', background: 'rgba(0,0,0,0.5)', padding: '12px', borderRadius: '12px' })
    Object.assign(this.cinematic.style, { position: 'absolute', top: '64px', left: '50%', transform: 'translateX(-50%)', maxWidth: '560px', background: 'rgba(0,0,0,0.45)', padding: '12px 16px', borderRadius: '16px', textAlign: 'center' })
    Object.assign(this.objectives.style, { position: 'absolute', left: '16px', bottom: '16px', background: 'rgba(0,0,0,0.5)', padding: '12px', borderRadius: '12px' })
    Object.assign(this.outcome.style, { position: 'absolute', inset: '0', display: 'none', placeItems: 'center', fontSize: '32px', fontWeight: '700', background: 'rgba(0,0,0,0.55)' })
    Object.assign(this.alerts.style, { position: 'absolute', right: '16px', top: '16px', textAlign: 'right', fontWeight: '700', fontSize: '14px', textShadow: '0 0 8px rgba(0,0,0,0.8)' })
    Object.assign(this.reticle.style, {
      position: 'absolute',
      left: '50%',
      top: '50%',
      width: '28px',
      height: '28px',
      marginLeft: '-14px',
      marginTop: '-14px',
      border: '2px solid rgba(255,255,255,0.75)',
      borderRadius: '50%',
      boxShadow: '0 0 16px rgba(255,255,255,0.32)',
    })
    Object.assign(this.tactical.style, { position: 'absolute', right: '16px', bottom: '16px', width: '180px', height: '180px', background: 'rgba(3,12,10,0.82)', borderRadius: '16px' })
    this.tactical.width = 180
    this.tactical.height = 180
    this.root.append(this.stats, this.cinematic, this.objectives, this.outcome, this.alerts, this.reticle, this.tactical)
    host.appendChild(this.root)
  }

  update(snapshot: MissionSnapshot, stormIntensity: number): void {
    this.stats.innerHTML = `Integrity ${Math.round(snapshot.player.health)}<br>Ammo ${snapshot.player.ammo}<br>Altitude ${Math.round(snapshot.player.position.y)}m<br>Fuel ${Math.round(snapshot.player.fuelRemaining)}%<br>Throttle ${Math.round(snapshot.player.throttle * 100)}%`
    this.objectives.innerHTML = snapshot.objectiveSummary.join('<br>')
    this.outcome.style.display = snapshot.outcome === 'inProgress' ? 'none' : 'grid'
    this.outcome.textContent = snapshot.outcome === 'success' ? 'MISSION COMPLETE' : 'MISSION LOST'
    const warnings: string[] = []
    if (snapshot.player.health < 40) warnings.push('<span style="color:#ff6f6f">HULL CRITICAL</span>')
    if (snapshot.player.fuelRemaining < 30) warnings.push('<span style="color:#ffd66f">LOW FUEL</span>')
    if (stormIntensity > 0.65) warnings.push('<span style="color:#ff9c54">SEVERE WEATHER</span>')
    this.alerts.innerHTML = warnings.join('<br>')
    this.drawTactical(snapshot, stormIntensity)
  }

  showEvent(event: CombatEvent): void {
    if (event.kind === 'cinematicBeat') this.typewrite(`<strong>${event.title}</strong><br>${event.body}`)
  }

  private typewrite(html: string): void {
    window.clearInterval(this.typingTimer)
    this.cinematic.textContent = ''
    const text = html.replace(/<br>/g, '\n').replace(/<[^>]+>/g, '')
    let index = 0
    this.typingTimer = window.setInterval(() => {
      this.cinematic.textContent = text.slice(0, index)
      index += 1
      if (index > text.length) window.clearInterval(this.typingTimer)
    }, 40)
  }

  private drawTactical(snapshot: MissionSnapshot, stormIntensity: number): void {
    const context = this.tactical.getContext('2d')!
    context.clearRect(0, 0, this.tactical.width, this.tactical.height)
    context.strokeStyle = 'rgba(80,255,120,0.6)'
    context.beginPath()
    context.arc(90, 90, 78, 0, Math.PI * 2)
    context.stroke()
    context.strokeStyle = 'rgba(98,255,138,0.22)'
    context.beginPath()
    context.arc(90, 90, 52, 0, Math.PI * 2)
    context.stroke()
    const altitudeHeight = Math.max(0, Math.min(0.95, snapshot.player.position.y / 200)) * this.tactical.height
    context.fillStyle = '#62ff8a'
    context.fillRect(8, this.tactical.height - altitudeHeight - 8, 6, altitudeHeight)
    const sweepAngle = snapshot.time * 1.7
    context.strokeStyle = 'rgba(98,255,138,0.4)'
    context.beginPath()
    context.moveTo(90, 90)
    context.lineTo(90 + Math.cos(sweepAngle) * 76, 90 + Math.sin(sweepAngle) * 76)
    context.stroke()
    context.fillStyle = `rgba(255,165,0,${0.2 + stormIntensity * 0.6})`
    context.beginPath()
    context.arc(162, 18, 6, 0, Math.PI * 2)
    context.fill()
    context.fillStyle = '#62ff8a'
    context.beginPath()
    context.arc(90, 90, 4, 0, Math.PI * 2)
    context.fill()
    context.fillStyle = '#ff6161'
    snapshot.enemies.filter((enemy) => enemy.health > 0).forEach((enemy) => {
      const offsetX = enemy.position.x - snapshot.player.position.x
      const offsetY = enemy.position.z - snapshot.player.position.z
      const radarRange = 320
      const scaledX = Math.max(-74, Math.min(74, (offsetX / radarRange) * 74))
      const scaledY = Math.max(-74, Math.min(74, (offsetY / radarRange) * 74))
      context.fillRect(90 + scaledX - 3, 90 + scaledY - 3, 6, 6)
    })
  }
}
