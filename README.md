# Kamikaze

Kamikaze is a native iOS vertical slice for an anti-war Pacific flight game: a playable memorial framed as a high-intensity arcade sortie. The repository is structured so the current runnable deliverable is an iOS app while the shared data, content, and architecture remain portable enough for future render/runtime targets.

## Current deliverable

- Native iOS SwiftUI + SceneKit app target in `/Apps/iOS/KamikazeApp.xcodeproj`
- Portable Swift gameplay modules in Swift Package Manager
- One playable mission (`Embers Over Midway`) with combat, cinematic beats, progression, save/load, archive unlocks, audio state management, and tactical overlay UI
- Data-driven content manifests for missions, archive, weather, shaders, replay, AI, effects, and accessibility-oriented UX planning

## Repository layout

- `/engine` — engine/runtime architecture notes and renderer system manifests
- `/gameplay` — aircraft data, progression, grounded upgrade planning
- `/missions` — mission scripts and campaign progression data
- `/historical_data` — archive content, timelines, and ethical framing material
- `/audio` — dynamic music/SFX/ambience manifests
- `/textures` — texture production targets and PBR authoring requirements
- `/spritesheets` — UI atlas and VFX sheet manifests
- `/cinematics` — intro/outro and replay-editor sequencing data
- `/ui` — HUD, tactical overlay, and visual language manifests
- `/shaders` — sky/ocean/cloud shader modifiers for the iOS renderer
- `/localization` — string tables
- `/weather` — procedural weather presets and tuning data
- `/ai` — interception, CAP, AA, and retreat behavior design data
- `/effects` — tracers, splashes, smoke, explosions, and fire loops
- `/save_data` — persistence schema notes
- `/replay` — replay format and editor planning
- `/Sources` + `/Tests` — portable Swift modules and validation

## Getting started

### Validate shared gameplay logic

```bash
swift test
```

### Open the iOS app

1. Open `/home/runner/work/kamikaze/kamikaze/Apps/iOS/KamikazeApp.xcodeproj` in Xcode 16+
2. Select an iPhone or iPad simulator running iOS 17+
3. Build and run `KamikazeApp`

## Play loop in the vertical slice

1. Memorial-toned main menu
2. Briefing
3. Launch into transit and intercept
4. Tactical flight/combat with arcade aim assist and subsystem damage
5. Debrief and archive unlock
6. Review memorial archive and hangar progression

## Documentation

- `/docs/ARCHITECTURE.md`
- `/docs/ASSET_PIPELINE.md`
