# Architecture

## Product stance

The implemented vertical slice remains a **native iOS game target** because that is the original concrete deliverable, but the repository is arranged around portable systems and content manifests so additional runtimes can be layered on later. Browser/WebGPU/WebGL requirements are represented in the architecture and asset/data boundaries, not as a second runnable target in this PR.

## Runtime layers

### Native presentation layer
- SwiftUI shell for menu, briefing, HUD, archive, hangar, settings, and debrief
- SceneKit renderer for the current 3D flight slice
- AVFoundation/AudioToolbox wrapper for music state and responsive effects

### Shared gameplay layer
- `KamikazeCore` — content models, geometry, save/progression, weather/damage system types
- `KamikazeGame` — simulation stepping, AI pursuit, combat resolution, mission outcome logic
- `Kamikaze` — convenience export target consumed by the app

## System boundaries

- **Rendering engine:** SceneKit renderer now; shader/material manifests kept in `/shaders`; repository architecture leaves room for a future WebGPU renderer with WebGL fallback through shared content manifests.
- **Input system:** current touch controls emulate throttle, climb, dive, bank, and fire. Accessibility/control manifests define keyboard, mouse, controller, and HOTAS mappings for later runtimes.
- **Mission system:** mission data is scriptable JSON in `/missions`; cinematic beats are embedded as timed narrative overlays.
- **Weather system:** `/weather/presets.json` defines storm visibility, cloud density, wind, ocean state, and AA pressure tuning.
- **AI system:** shared simulation currently supports enemy pursuit/firing; `/ai/behavior_manifest.json` captures layered naval AA, CAP, retreat, and detection expansion.
- **Replay system:** current runtime exposes deterministic snapshots/events suitable for later replay recording; `/replay/replay_format.json` defines the future editor format.
- **Save/load manager:** `PlayerProgression` and `UserDefaultsSaveStore` persist progression/settings.
- **Cinematic subsystem:** mission beats, debrief framing, and camera-state planning live in `/cinematics`.
- **Localization support:** `/localization/en.json` centralizes player-facing language keys for future string extraction.
- **Shader pipeline:** SceneKit shader modifiers for ocean/sky/cloud tone live in `/shaders`.
- **Damage model:** subsystem degradation affects steering, visibility, engine output, fuel drain, and stability.

## Experience goals translated to systems

- **Fragile flight:** aircraft feel underpowered, heavier in dives, and increasingly unstable under damage.
- **Historically grounded progression:** upgrades improve survival, navigation, maintenance, clarity, and weather-readiness rather than granting heroic power fantasy boosts.
- **Anti-war framing:** memorial archive, reflective debriefing, and restrained copy prevent the combat loop from reading as triumphalist.
- **Performance discipline:** current code prioritizes clean state transitions and lightweight placeholder geometry; manifests outline future GPU instancing, LOD, culling, async loading, and compressed texture pipelines.
