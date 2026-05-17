# PersistenceViewer Quick Start Guide

Welcome to PersistenceViewer - a Vision Pro app for visualizing topological persistence diagrams from the Mobius Band sonar simulation project.

## What This App Does

This app provides an immersive 3D interface to explore:
- **Persistence Diagrams**: Topological features (H0, H1, H2) with birth/death times
- **Betti Curves**: Evolution of homology over filtration
- **Point Clouds**: Original 3D PCA spaces from frequency band analysis
- **Statistics**: Per-band topological metrics

## Initial Setup

### 1. First-Time Sync

The app needs data from your Mobius Band simulation project. Here's how to get it:

```bash
# Navigate to your Mobius Band project
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"

# Test that everything is ready
./test_sync.sh

# If tests pass, sync your data
./sync_to_visionpro.sh
```

This will:
1. Find your most recent experiment
2. Convert NumPy arrays to JSON
3. Copy data to this Vision Pro project's `Data/` directory

### 2. Add Data to Xcode

After syncing, you need to add the Data folder to your Xcode project:

1. Open `PersistenceViewer.xcodeproj` in Xcode
2. Right-click on `PersistenceViewer` folder in Project Navigator
3. Select "Add Files to PersistenceViewer..."
4. Navigate to `PersistenceViewer/Data/`
5. Check "Create folder references" (blue folder icon)
6. Check "Copy items if needed"
7. Make sure target "PersistenceViewer" is selected
8. Click "Add"

### 3. Build and Run

1. Select your Vision Pro device or simulator
2. Press Cmd+R to build and run
3. The app will automatically load all experiments from the Data folder

## Using the App

### Navigation Hierarchy

```
Experiments
  └─ Configurations (e.g., config_1, config_2)
      └─ Frequency Bands (e.g., band_01, band_02)
          └─ Detailed View
              ├─ Persistence Diagram
              ├─ Homology Statistics
              └─ 3D Point Cloud
```

### What You'll See

**Experiment List**
- All synced experiments
- Configuration and band counts
- Export timestamps

**Band Detail View**
- **H0 (Blue)**: Connected components
- **H1 (Green)**: Loops/holes
- **H2 (Red)**: Voids
- Statistics: count, mean/max lifetime, total persistence

## Regular Workflow

### After Running New Simulations

1. **In Mobius Band project**, run your simulation and TDA:
   ```bash
   # Your MATLAB simulation creates experiment_YYYY-MM-DD_HHMMSS/

   # Compute persistence diagrams
   python3 fixedComputePerBandTDA.py

   # Sync to Vision Pro
   ./sync_to_visionpro.sh
   ```

2. **In Vision Pro app**, tap the refresh button (↻) to reload data

That's it! The new experiment will appear in the list.

## File Structure

```
PersistenceViewer/
├── PersistenceViewer/
│   ├── Models/
│   │   └── PersistenceModels.swift    # Data models
│   ├── Views/
│   │   └── ExperimentListView.swift   # UI views
│   ├── Data/                           # Synced JSON files
│   │   └── experiment_*.json
│   ├── ContentView.swift
│   └── PersistenceViewerApp.swift
├── SYNC_WORKFLOW.md                    # Detailed sync docs
└── QUICKSTART.md                       # This file
```

## Troubleshooting

### "No Experiments Found"
- Check that Data/ folder contains `.json` files
- Verify Data/ folder is added to Xcode project (blue folder icon)
- Run sync script again from Mobius Band project

### "Error Loading Data"
- Check JSON file integrity
- Try deleting and re-syncing a specific experiment
- Check Xcode console for detailed error messages

### Sync Script Fails
- Run `./test_sync.sh` to diagnose issues
- Ensure Python dependencies are installed: `pip3 install numpy h5py`
- Check that experiment has `python_exports/` directory

## Next Steps

### Future Features (To Be Implemented)

1. **Interactive Persistence Diagrams**
   - Tap points to see birth/death times
   - Filter by homology dimension
   - Zoom and pan

2. **3D Point Cloud Visualization**
   - RealityKit rendering
   - Rotate and explore in space
   - Color by topological features

3. **Comparative Analysis**
   - View multiple bands side-by-side
   - Animation through frequency spectrum
   - Statistical comparisons

4. **Export and Sharing**
   - Save screenshots
   - Export filtered data
   - Share findings

## Development

### Adding New Visualizations

All views are in `Views/ExperimentListView.swift`. To add new visualizations:

1. Create a new SwiftUI View
2. Access band data via `Band` model
3. Use RealityKit for 3D content
4. Add to navigation hierarchy

### Data Model Reference

See `Models/PersistenceModels.swift` for:
- `PersistenceExperiment`: Root container
- `Configuration`: Scatterer config
- `Band`: Frequency band + TDA results
- `PersistenceFeature`: Individual persistence point

## Support

For issues or questions:
- Check `SYNC_WORKFLOW.md` for detailed pipeline documentation
- Review error messages in Xcode console
- Verify source data in Mobius Band project

---

**Happy Exploring!** 🎉

Your persistence diagrams are now viewable in immersive 3D on Vision Pro!
