# PROMPT-VISION-003: Hand Gesture Interaction

## Task
Implement hand gesture interaction for manipulating persistence diagrams and point clouds in 3D space.

## Requirements
1. Pinch to select individual persistence features (birth-death points)
2. Two-hand drag to rotate 3D point clouds and phase spaces
3. Spread gesture to zoom into regions of persistence diagrams
4. Tap to annotate features with voice/text notes
5. Record all gestures as interaction events for Golden Cipher behavioral data

## Files to Modify
- `PointCloud3DView.swift` — add full gesture suite
- `PersistenceDiagramView.swift` — add selection and zoom
- `PhaseSpaceTrajectoryView.swift` — add rotation and slicing
- New: `GestureRecorder.swift` — capture gestures for restriction maps

## Claude Code Invocation
```
Enter plan mode. Read PointCloud3DView.swift and the RealityKit gesture APIs for visionOS. Design a gesture interaction system that enables pinch-select, drag-rotate, spread-zoom on 3D topological visualizations, while recording all interactions as time-stamped events for export to The Golden Cipher.
```
