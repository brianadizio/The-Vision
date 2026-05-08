# PROMPT-VISION-002: Nature Environment Backgrounds

## Task
Add immersive Nature environment backgrounds from Sachuest Point as the context behind topological data visualizations.

## Context
The Vision's core concept is viewing mathematical data in a calm, serene environment. The Coastal Design System already uses ocean-themed colors, but the VR environment itself lacks actual Nature imagery. Brian will capture spatial video and photos at Sachuest Point (PHYS-VISION-002, PHYS-VISION-004).

## Requirements
1. Add skybox/environment support to the main ContentView
2. Support multiple environment presets (ocean sunset, morning mist, night sky)
3. Use placeholder gradient environments until real Sachuest captures are available
4. When spatial photos arrive, convert to equirectangular panoramas for skybox
5. Ensure data visualizations remain readable against Nature backgrounds (contrast)

## Physical Task Dependency
Requires PHYS-VISION-002 (spatial video) or PHYS-VISION-004 (photos). Use placeholders until then.

## Files to Modify
- `ContentView.swift` — add ImmersiveSpace with environment
- `CoastalDesignSystem.swift` — add environment presets
- New: `EnvironmentManager.swift` — manage skybox loading

## Claude Code Invocation
```
Enter plan mode. Read CoastalDesignSystem.swift and ContentView.swift. Design an environment system for the Vision Pro app that starts with procedural gradient skyboxes matching the coastal theme, with a clear path to swap in real Sachuest Point spatial photos when they become available.
```
