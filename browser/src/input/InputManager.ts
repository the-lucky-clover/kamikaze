import { PilotInput } from '../core/types'

export class InputManager {
  private keys = new Set<string>()
  private mouseX = 0
  private mouseY = 0

  constructor(private host: HTMLElement) {
    window.addEventListener('keydown', (event) => this.keys.add(event.key.toLowerCase()))
    window.addEventListener('keyup', (event) => this.keys.delete(event.key.toLowerCase()))
    host.addEventListener('click', () => host.requestPointerLock?.())
    window.addEventListener('mousemove', (event) => {
      if (document.pointerLockElement === host) {
        this.mouseX = event.movementX
        this.mouseY = event.movementY
      }
    })
  }

  getInput(): PilotInput {
    const gamepad = navigator.getGamepads?.()[0]
    const yaw = (this.keys.has('arrowleft') || this.keys.has('a') ? -1 : 0) + (this.keys.has('arrowright') || this.keys.has('d') ? 1 : 0) + (gamepad?.axes[0] ?? 0) + this.mouseX * 0.005
    const pitch = (this.keys.has('arrowup') || this.keys.has('w') ? 1 : 0) + (this.keys.has('arrowdown') || this.keys.has('s') ? -1 : 0) + (-(gamepad?.axes[1] ?? 0)) + this.mouseY * -0.005
    const roll = (this.keys.has('q') ? -1 : 0) + (this.keys.has('e') ? 1 : 0) + (gamepad?.axes[2] ?? 0)
    const throttle = (this.keys.has('+') || this.keys.has('=') ? 0.7 : 0) + (this.keys.has('-') ? -0.7 : 0) + ((gamepad?.buttons[7]?.value ?? 0) - (gamepad?.buttons[6]?.value ?? 0))
    const firing = this.keys.has(' ') || Boolean(gamepad?.buttons[0]?.pressed)
    this.mouseX = 0
    this.mouseY = 0
    return { throttle, pitch, yaw, roll, firing }
  }
}
