# Asset Pipeline

## Placeholder-first production model

This repository intentionally ships with data manifests and shader placeholders instead of proprietary content so contributors can extend the game without licensing blockers.

## Content folders

- `/gameplay/aircraft.json` — aircraft tuning and unlock state
- `/missions/missions.json` — playable mission scripts and campaign metadata
- `/historical_data/archive.json` — unlockable museum/archive entries
- `/weather/presets.json` — storm, visibility, sea-state, and late-war escalation tuning
- `/audio/audio_manifest.json` — music and ambience behavior rules
- `/textures/texture_manifest.json` — PBR texture categories, mipmapping, compression, and LOD expectations
- `/spritesheets/atlas_manifest.json` — UI atlases, cockpit indicators, radar icons, smoke/explosion/fire sheets
- `/effects/effects_manifest.json` — tracer, splash, foam, fire, smoke, and explosion timing specs
- `/cinematics/embers_over_midway_intro.json` — cinematic beats and replay-editor expectations
- `/localization/en.json` — string table seed data

## Shader workflow

The iOS renderer uses SceneKit shader modifiers from `/shaders`. Those files should remain small, stylized, and portable so equivalent logic can later be reauthored in Metal or WebGPU shader stages.

## Texture guidance

Author textures with:
- restrained saturation
- filmic contrast
- support for mipmapping
- compressed delivery formats
- clean LOD fallback behavior
- PBR-friendly albedo/normal/roughness/metalness grouping

## Sprite sheet guidance

Required atlas families already represented in manifests:
- cockpit indicators
- radar/minimap icons
- damage decals
- smoke / explosion / fire loops
- ocean foam and splash animation frames
- UI atlases for plotting-room overlays

## Historical and ethical content guidance

Archive entries should be educational, academically grounded, and reflective. Replace placeholder copy with sourced material, not sensationalized dialogue.
