# Persistence Data Sync Workflow

This document describes how to sync persistence diagram data from the Mobius Band simulation repository to this Vision Pro viewer project.

## Overview

The data pipeline connects two repositories:

1. **Source**: `/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/`
   - MATLAB simulations and TDA computations
   - Giotto-TDA persistence diagrams in NumPy format

2. **Destination**: This Vision Pro project
   - Swift-native data models
   - RealityKit visualization
   - JSON-based data format

## Workflow Steps

### 1. Run Simulation and TDA Analysis (in source repository)

```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"

# Run your MATLAB simulation
# This creates experiment_YYYY-MM-DD_HHMMSS/ directories

# Compute persistence diagrams for all frequency bands
python3 fixedComputePerBandTDA.py
```

This creates the following structure:
```
experiment_2025-XX-XX_XXXXXX/
└── python_exports/
    ├── config_1/
    │   ├── band_01/
    │   │   ├── persistence_diagram.npy
    │   │   ├── betti_curves.npy
    │   │   ├── persistence_landscape.npy
    │   │   └── ...
    │   ├── band_02/
    │   └── ...
    └── config_2/
        └── ...
```

### 2. Sync to Vision Pro (automated)

Simply run the sync script:

```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"
./sync_to_visionpro.sh
```

This will:
- Find the most recent experiment
- Convert all `.npy` files to JSON
- Export to `PersistenceViewer/Data/`
- Report success and file sizes

### 3. Manual Export (if needed)

You can also manually export specific experiments:

```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"

# Export specific experiment
python3 export_to_visionpro.py \
  --experiment experiment_2025-09-20_102020 \
  --output "/path/to/PersistenceViewer/Data" \
  --name "My Custom Name"

# Export most recent (default)
python3 export_to_visionpro.py
```

## Data Format

The exported JSON has this structure:

```json
{
  "name": "experiment_2025-09-20_102020",
  "source_path": "/path/to/source",
  "export_timestamp": "2025-10-11T12:00:00",
  "configurations": [
    {
      "config_id": 1,
      "bands": [
        {
          "band_id": 1,
          "persistence_diagram": [
            {
              "id": 0,
              "birth": 0.0,
              "death": 1.5,
              "lifetime": 1.5,
              "dimension": 0,
              "homology_class": "H0"
            }
          ],
          "statistics": {
            "H0": {
              "count": 2,
              "mean_lifetime": 12.1,
              "max_lifetime": 14.08,
              "total_persistence": 24.2
            }
          },
          "point_cloud": {
            "points": [[x, y, z], ...],
            "n_points": 100,
            "dimensions": 3
          }
        }
      ]
    }
  ]
}
```

## Swift Models

The Vision Pro app uses these Swift models (see `Models/PersistenceModels.swift`):

- `PersistenceExperiment`: Top-level container
- `Configuration`: Scatterer configuration
- `Band`: Frequency band with TDA results
- `PersistenceFeature`: Individual persistence point (birth/death)
- `PointCloudData`: 3D point cloud for RealityKit

## Loading Data in Vision Pro

The `PersistenceDataLoader` class automatically loads all JSON files from the `Data/` directory:

```swift
@StateObject var dataLoader = PersistenceDataLoader()

var body: some View {
    VStack {
        if dataLoader.isLoading {
            ProgressView("Loading experiments...")
        } else {
            List(dataLoader.experiments) { experiment in
                Text(experiment.name)
            }
        }
    }
    .onAppear {
        dataLoader.loadExperiments()
    }
}
```

## Quick Reference

### One-Line Sync
```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/" && ./sync_to_visionpro.sh
```

### File Locations
- **Export Script**: `export_to_visionpro.py`
- **Sync Script**: `sync_to_visionpro.sh`
- **Swift Models**: `PersistenceViewer/Models/PersistenceModels.swift`
- **Data Directory**: `PersistenceViewer/Data/`

## Troubleshooting

### "No experiment directories found"
Run a MATLAB simulation first to create `experiment_*` directories.

### "No python_exports directory"
Run `python3 fixedComputePerBandTDA.py` to compute TDA results.

### "Module not found: numpy"
Install required Python packages:
```bash
pip3 install numpy giotto-tda h5py
```

### Vision Pro app can't find data
Ensure the `Data/` directory is included in Xcode:
1. Add folder to Xcode project
2. Make sure "Copy items if needed" is checked
3. Target membership includes PersistenceViewer

## Next Steps

1. Build visualization views for persistence diagrams
2. Add RealityKit rendering for point clouds
3. Implement interactive filtering by homology dimension
4. Add animation between different frequency bands
