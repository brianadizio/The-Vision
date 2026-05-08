# PROMPT-VISION-005: Spatial Audio Integration

## Task
Map topological features to spatial audio using Shepard tones (Data Y Sheaf connection).

## Requirements
1. Generate Shepard tone sequences from Betti curve data
2. Higher Betti numbers → higher perceived pitch
3. Persistent features (long lifetimes) → sustained tones
4. Birth events → attack transients, death events → release
5. Spatial positioning: place sounds at the 3D location of their corresponding features
6. Nature ambient background: ocean waves from Sachuest (or synthesized)

## Depends On
PROMPT-VISION-001 (generalized data for Betti curves)

## Files to Modify
- New: `SpatialAudioEngine.swift` — Shepard tone synthesis
- `BettiCurvesView.swift` — toggle audio sonification
- `PointCloud3DView.swift` — spatial audio positioning

## Claude Code Invocation
```
Enter plan mode. Research AVAudioEngine and spatial audio in visionOS. Design a sonification system that maps Betti curves to Shepard tones, placing sounds spatially at the 3D locations of their corresponding topological features. Include ambient Nature audio background.
```
