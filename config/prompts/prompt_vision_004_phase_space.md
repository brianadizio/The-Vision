# PROMPT-VISION-004: Phase Space Manipulation

## Task
Add interactive phase space manipulation from SSEUQFT data — rotate, zoom, slice through phase spaces with real-time cross-section display.

## Requirements
1. Import phase space trajectories from SSEUQFT sonar data
2. Enable free rotation via hand gestures (mapped to SO(3))
3. Add slicing plane that user can position to see cross-sections
4. Display real-time Poincare section as the slice plane moves
5. Animate trajectory playback with speed controls

## Depends On
PROMPT-VISION-001 (generalized import for SSEUQFT data format)

## Files to Modify
- `PhaseSpaceTrajectoryView.swift` — add slicing and Poincare sections
- `PersistenceModels.swift` — add phase space slice model

## Claude Code Invocation
```
Enter plan mode. Read PhaseSpaceTrajectoryView.swift. Design an interactive phase space viewer that adds a movable slicing plane, computes and displays real-time Poincare cross-sections, and records the user's exploration path through the phase space for export to restriction maps.
```
