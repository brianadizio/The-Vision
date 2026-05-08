# PROMPT-VISION-001: Generalize Data Import

## Task
Expand PersistenceViewer to accept TDA data from ALL Solutions, not just the Mobius Band sonar project.

## Context
Currently, PersistenceModels.swift is tightly coupled to the Mobius Band experiment format (configurations with frequency bands, sonar-specific metadata). We need a generalized import layer that can accept persistence diagrams, point clouds, and Betti curves from any Solution that produces TDA output.

## Requirements
1. Create a `UniversalTDAImport` protocol/struct that accepts any Solution's TDA JSON
2. Map common fields: persistence features (birth, death, dimension), point clouds (coordinates), Betti curves (filtration bins)
3. Preserve Solution-specific metadata in an extensible dictionary
4. Update ExperimentListView to show experiments grouped by source Solution
5. Keep backward compatibility with existing Mobius Band data format

## Files to Modify
- `PersistenceModels.swift` — add universal import layer
- `ExperimentListView.swift` — add Solution-based grouping
- `ContentView.swift` — update navigation

## Test
- Existing Enhanced_Export_Test.json must still load correctly
- Create a minimal test JSON from a different Solution format
- Verify all 8 visualization views render correctly with generalized data

## Claude Code Invocation
```
Enter plan mode. Read the current PersistenceModels.swift and propose a generalized data import architecture that preserves the existing Mobius Band format while adding support for TDA output from The Golden Core, SSEUQFT, and other computational Solutions. The key is a common persistence diagram format with Solution-specific metadata extensions.
```
