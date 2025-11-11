# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

**"The Vision"** is a Vision Pro (visionOS) application that provides immersive 3D visualization of topological persistence diagrams from MATLAB sonar simulations. It's part of the Golden Enterprise Solutions ecosystem but operates independently as a Swift/visionOS native app.

This Solution is **NOT** deployed via the standard CI/CD pipeline. It is a standalone Xcode project for Vision Pro that consumes data from the Mobius Band sonar simulation project.

## Architecture Overview

### Three-Repository Data Flow

```
Mobius Band Project (MATLAB Simulation)
  ├─ MATLAB GUI simulations
  ├─ Python TDA analysis (fixedComputePerBandTDA.py)
  └─ NumPy persistence diagrams (.npy files)
       ↓
  [export_to_visionpro.py + sync_to_visionpro.sh]
       ↓
The Vision (Vision Pro App)
  ├─ Swift data models (PersistenceModels.swift)
  ├─ SwiftUI views
  ├─ RealityKit 3D visualizations
  └─ JSON data (Data/*.json)
```

**Key Insight**: This app is a **visualization frontend** for MATLAB-generated data, not a deployable Solution in the CI/CD sense.

## Project Structure

```
The Vision/
├── src/core/front_end/Persistence Viewer/PersistenceViewer/
│   ├── PersistenceViewer/
│   │   ├── Models/
│   │   │   └── PersistenceModels.swift          # Data models for TDA results
│   │   ├── Views/
│   │   │   ├── ExperimentListView.swift         # Main navigation
│   │   │   ├── PersistenceDiagramView.swift     # 2D persistence diagrams
│   │   │   ├── PointCloud3DView.swift           # 3D RealityKit point clouds
│   │   │   ├── BettiCurvesView.swift            # Line charts for homology
│   │   │   ├── ManifoldEmbeddingView.swift      # Isomap/LLE/DiffMap
│   │   │   ├── PhaseSpaceTrajectoryView.swift   # 3D phase space
│   │   │   └── FrequencyBandGridView.swift      # Band grid navigator
│   │   ├── DesignSystem/
│   │   │   └── CoastalDesignSystem.swift        # Coastal-themed UI design
│   │   ├── Utilities/
│   │   │   └── SharedViewComponents.swift       # Reusable UI components
│   │   ├── Data/                                 # Synced JSON files
│   │   │   └── *.json                            # Experiment data
│   │   ├── ContentView.swift                     # Root view
│   │   └── PersistenceViewerApp.swift            # App entry point
│   ├── Packages/RealityKitContent/               # RealityKit assets
│   ├── PersistenceViewer.xcodeproj               # Xcode project
│   ├── GUI_ARCHITECTURE.md                       # Complete architecture guide
│   ├── IMPLEMENTATION_STATUS.md                  # Current status tracker
│   ├── SYNC_WORKFLOW.md                          # Data sync documentation
│   ├── QUICKSTART.md                             # Getting started guide
│   └── QUICK_REFERENCE.md                        # Command reference
└── [Standard Golden Solutions directories...]
```

## Directory Structure

**Note**: While "The Vision" is primarily a Vision Pro app, it follows the standard Golden Solutions directory structure for consistency across the ecosystem.

- `assets/raw` - Input data to running the algorithms and GUI's
- `assets/processed` - Results and output data from the algorithms and GUI's
- `documentation` (and subfolders) - Documentation of development research and code improvements
- `src/core/gui` - Back-end MATLAB GUI's (potentially multiple primary GUI's)
- `src/core/data` - Useful, critical information on research and development that might be referred to when adding new features
- `src/core/algorithm` - Main algorithmic code for the Solution that will eventually be ported to C and Python for front-end application engines
- `src/core/config` - Configurations for global Python API's like pysheaf/netlist repository in `/Users/briandizio/Documents/2023-Now/Golden Enterprise Solutions/Solutions/The Golden Core/src/core`. Python geodesics, topological data analysis, and PySheaf/Netlist code that work for all Solutions
- `src/core/testing` - Comprehensive testing for running iterative tests as improvements are made
- `src/core/debugging` - Smaller tests to get things working, functions in between complete GUI's being used to transition between complete functionality
- `src/core/running` - Running various configurations of the algorithm, potentially with many iterations
- `src/core/front_end` - **Vision Pro app lives here** (`Persistence Viewer/PersistenceViewer/`) - Final Swift application based off the algorithm
- `src/core/prompts` - Prompts used to create the Solution
- `src/` (other directories besides `core/`) - Written into by CI/CD scripts and processes
- `logs` - Error log files when debugging the GUI (once error logging is implemented)
- `releases` - Final builds and releases
- `analytics` - **Future**: Analytics after all applications are built and running on the front end
- `research` - **Future**: Research materials (not ready until front end is built)
- `experiments` - **Future**: Experimental work (not ready until front end is built)
- `integration-tests` - Solution-to-solution tests
- `metadata` - Data on the solution for the development process

**Current State**: Most development is happening in `src/core/front_end/Persistence Viewer/PersistenceViewer/` as this is primarily a Vision Pro visualization app consuming data from the Mobius Band project.

## Essential Commands

### Building and Running

**Build and run on Vision Pro simulator**:
```bash
cd "src/core/front_end/Persistence Viewer/PersistenceViewer"
open PersistenceViewer.xcodeproj
# In Xcode: Cmd+R to build and run
```

**Build for device** (requires Vision Pro hardware):
- Select Vision Pro device in Xcode
- Ensure signing and capabilities are configured
- Cmd+R to build and deploy

### Data Sync from Mobius Band Project

**Location**: `/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/`

**One-command sync**:
```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"
./sync_to_visionpro.sh
```

**Manual sync steps**:
```bash
# 1. Run MATLAB simulation (creates experiment_YYYY-MM-DD_HHMMSS/)
# 2. Compute TDA for all bands
python3 fixedComputePerBandTDA.py

# 3. Export to Vision Pro format
python3 export_to_visionpro.py

# 4. Files are automatically copied to:
# .../The Vision/src/core/front_end/Persistence Viewer/PersistenceViewer/Data/
```

**Test sync pipeline**:
```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"
./test_sync.sh
```

### Adding Data to Xcode

After syncing, you must add the Data folder to the Xcode project:

1. Open `PersistenceViewer.xcodeproj`
2. Right-click `PersistenceViewer` folder → "Add Files to PersistenceViewer..."
3. Navigate to `PersistenceViewer/Data/`
4. ✅ Check "Create folder references" (blue folder icon)
5. ✅ Check "Copy items if needed"
6. ✅ Select target "PersistenceViewer"
7. Click "Add"

## Data Models

### Hierarchy

```
PersistenceExperiment (root)
├── globalVisualizations: GlobalVisualizations?
│   ├── globalPCA: VisualizationData?        # 100 points, 3D
│   ├── phaseSpace: VisualizationData?       # 2000 points, 3D
│   ├── manifoldEmbeddings: ManifoldEmbeddings?
│   │   ├── isomap: VisualizationData?
│   │   ├── lle: VisualizationData?
│   │   └── diffusionMap: VisualizationData?
│   └── scattererLabels: LabelData?
└── configurations: [Configuration]
    └── bands: [Band]
        ├── persistenceDiagram: [PersistenceFeature]
        │   └── (birth, death, lifetime, dimension, homologyClass)
        ├── statistics: Statistics
        │   ├── H0: HomologyStatistics
        │   ├── H1: HomologyStatistics
        │   └── H2: HomologyStatistics
        ├── bettiCurves: BettiCurves?        # 100 bins × 3 dimensions
        ├── persistenceLandscape: PersistenceLandscape?  # 5 layers × 100 bins
        └── pointCloud: PointCloudData?       # 100 points, 3D PCA
```

### Key Model Properties

**PersistenceFeature**: Individual topological feature
- `birth`, `death`: Double (filtration times)
- `lifetime`: Double (persistence = death - birth)
- `dimension`: Int (0, 1, 2)
- `homologyClass`: String ("H0", "H1", "H2")

**VisualizationData**: Generic 3D point cloud
- `points`: [[Double]] (x,y,z coordinates)
- `simd3Points`: [SIMD3<Float>] (computed property for RealityKit)

**Color Conventions** (match MATLAB):
- H0 (connected components): Blue
- H1 (loops/holes): Green
- H2 (voids): Red

## Navigation Hierarchy

Mirrors the three-level MATLAB GUI structure:

```
Level 1: Global Scale (ExperimentListView)
  └─ List of experiments with metadata
     └─ Tap to drill down

Level 2: Medium Scale (ConfigurationListView)
  └─ 4 scatterer configurations
     └─ 20 frequency bands per config
        └─ Tap to drill down

Level 3: Local Scale (BandDetailView)
  └─ Detailed visualizations for single band
     ├─ Persistence Diagram (2D scatter)
     ├─ Point Cloud (3D RealityKit)
     ├─ Betti Curves (line chart)
     ├─ Phase Space (3D trajectory)
     ├─ Manifold Embeddings (Isomap/LLE/DiffMap)
     └─ Statistics (cards)
```

## Development Workflow

### Adding New Visualizations

1. **Verify data availability**: Check `IMPLEMENTATION_STATUS.md` → "Data Completeness Matrix"
2. **Create SwiftUI View**: Add to `Views/` directory
3. **Access data**: Use models from `PersistenceModels.swift`
4. **Use RealityKit for 3D**: Create `RealityView` with `ModelEntity`
5. **Match MATLAB aesthetics**: Use same colors, layouts, labels
6. **Test with sample data**: Use `Enhanced_Export_Test.json` (6.2 MB, 80 bands)

### Typical View Structure

```swift
struct MyVisualizationView: View {
    let band: Band  // or other data model

    var body: some View {
        VStack {
            // Header
            Text("My Visualization")

            // Main content
            RealityView { content in
                // Create RealityKit entities
                let mesh = createMesh(band.someData)
                let entity = ModelEntity(mesh: mesh)
                content.add(entity)
            }

            // Controls/legend
            HStack {
                // Interactive elements
            }
        }
    }
}
```

### RealityKit Best Practices

- Use `ModelEntity` with custom geometry for point clouds
- Apply gestures: `.gesture(RotateGesture3D())`, `.gesture(MagnifyGesture())`
- Use LOD (Level of Detail) for distant objects
- Cache rendered entities in `@State` variables
- Profile memory usage with Instruments

## Key Documentation

**Start Here:**
- `QUICKSTART.md` - First-time setup (5 min)
- `GUI_ARCHITECTURE.md` - Complete architecture reference
- `IMPLEMENTATION_STATUS.md` - Current feature status

**Technical Reference:**
- `SYNC_WORKFLOW.md` - Data pipeline details
- `QUICK_REFERENCE.md` - Command cheat sheet
- `PersistenceModels.swift` - Source of truth for data structures

**MATLAB Source Project:**
- Location: `/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/`
- Key scripts: `fixedComputePerBandTDA.py`, `export_to_visionpro.py`, `sync_to_visionpro.sh`

## Relationship to Golden Solutions CI/CD

**This Solution is DIFFERENT** from standard Golden Solutions:

| Standard Solution | The Vision |
|------------------|-----------|
| MATLAB GUI → .mlapp | Swift/SwiftUI → .app |
| Web App Server deployment | Vision Pro device/simulator |
| Python API via MATLAB SDK | No API (data consumer only) |
| CI/CD via add_cicd.sh | Manual Xcode builds |
| Cloud Run deployment | Local/TestFlight deployment |

**DO NOT**:
- Run `add_cicd.sh` on this Solution
- Attempt to compile MATLAB code here (none exists)
- Deploy to Web App Server or Cloud Run
- Generate Python/C bindings

**DO**:
- Build with Xcode for Vision Pro
- Sync data from Mobius Band project
- Develop SwiftUI/RealityKit visualizations
- Test on Vision Pro simulator or device

## Current Implementation Status

### ✅ Completed
- Data export pipeline (Python → JSON)
- Swift data models (PersistenceModels.swift)
- Navigation hierarchy (ExperimentListView)
- Statistics display (text-based)
- Documentation suite

### 🚧 In Progress
- Persistence diagram view (PersistenceDiagramView.swift)
- Point cloud 3D rendering (PointCloud3DView.swift)
- Betti curves chart (BettiCurvesView.swift)

### 📋 Planned
- Manifold embedding tabs (ManifoldEmbeddingView.swift)
- Phase space trajectory animation (PhaseSpaceTrajectoryView.swift)
- Frequency band grid navigator (FrequencyBandGridView.swift)
- Cross-experiment comparison
- Export/sharing features

## Common Issues

### "No Experiments Found"
- Verify Data/ folder contains .json files
- Check that Data/ is added to Xcode as folder reference (blue icon)
- Re-run sync script from Mobius Band project

### "Error Loading Data"
- Check JSON file integrity (valid JSON format)
- Verify all required fields are present
- Check Xcode console for detailed error messages

### Sync Script Fails
- Run `./test_sync.sh` to diagnose
- Ensure Python dependencies installed: `pip3 install numpy h5py`
- Verify experiment has `python_exports/` directory

### Build Errors
- Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)
- Delete DerivedData: `~/Library/Developer/Xcode/DerivedData/`
- Verify Xcode version supports visionOS SDK

## Design System

**Theme**: Coastal-inspired (see `CoastalDesignSystem.swift`)
- Ocean blues, sandy beiges, sunset oranges
- Spacious, immersive layouts
- High contrast for readability in VR

**Typography**:
- Headers: SF Pro Display, bold
- Body: SF Pro Text, regular
- Monospace: SF Mono (for data values)

**Color Palette** (topological features):
- H0: `.blue` (#0000FF) - Connected components
- H1: `.green` (#00FF00) - Loops/holes
- H2: `.red` (#FF0000) - Voids
- Background: `.black` or `.darkGray` for immersive space

## Performance Considerations

- **Lazy loading**: Don't render all 80 bands at once
- **Caching**: Store rendered views in memory
- **Downsampling**: Consider LOD for preview mode
- **Profiling**: Use Instruments to monitor memory/GPU usage
- **Progressive loading**: Load data incrementally for large experiments

## Testing

**Sample Data**:
- `experiment_2025-10-06_220239.json` (6.6 MB, real data)
- `Enhanced_Export_Test.json` (6.2 MB, test data)

**Test Strategy**:
1. Start with single band visualization
2. Verify all data loads without errors
3. Test gestures (rotate, zoom, tap)
4. Profile memory with 80 bands loaded
5. Test on both simulator and device

## Future Enhancements

1. **Real-time sync**: Auto-reload when new experiments appear
2. **AR integration**: Place persistence diagrams in physical space
3. **Collaborative viewing**: Multi-user immersive sessions
4. **Voice commands**: "Show me band 5 of config 2"
5. **Export to PDF/image**: Share visualizations externally
