# PROMPT-VISION-006: Restriction Map Exporters

## Task
Build exporters that capture VR interaction data and export to Golden Cipher (behavioral biometrics) and The Witness (audit trail).

## Requirements
1. SessionRecorder: capture all interaction events during VR sessions
   - Gaze trajectory (direction on S2, timestamps)
   - Hand positions (3D coordinates, timestamps)
   - Gesture types and durations
   - Navigation path through experiments/bands
   - Feature annotations
2. RestrictionMapExporter: format and export data
   - Golden Cipher format: behavioral trajectory as jsonl
   - Witness format: session log as jsonl
   - Data Phi Sheaf format: annotated persistence diagrams as json
3. Auto-export on session end
4. Manual export trigger for partial sessions

## Depends On
PROMPT-VISION-003 (gesture recording system)

## Files to Modify
- New: `SessionRecorder.swift` — capture all interaction events
- New: `RestrictionMapExporter.swift` — format and write exports
- `PersistenceViewerApp.swift` — hook session lifecycle

## Claude Code Invocation
```
Enter plan mode. Design a session recording and restriction map export system for the Vision Pro app. The recorder captures gaze (S2), hands (R3), gestures, and navigation. The exporter writes to three formats: Golden Cipher behavioral trajectory (jsonl), Witness session log (jsonl), and Data Phi Sheaf annotated diagrams (json).
```
