# Quick Reference - Persistence Data Sync

## ✅ Setup Complete!

Your repositories are now linked. You successfully synced:
- **4 configurations** × **20 frequency bands** = **80 total bands**
- **6.6 MB** of persistence diagram data
- From: `experiment_2025-10-06_220239`

## One-Command Sync

```bash
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/" && ./sync_to_visionpro.sh
```

## File Locations

### Source Repository (Mobius Band)
```
/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/
├── experiment_*/                      # Your simulation results
│   └── python_exports/                # TDA computations (.npy files)
├── export_to_visionpro.py            # Export script
├── sync_to_visionpro.sh              # One-command sync
└── test_sync.sh                       # Pre-flight checks
```

### Vision Pro Project (This Repo)
```
PersistenceViewer/
├── Data/
│   └── experiment_2025-10-06_220239.json  # ✅ Synced data (6.6 MB)
├── Models/
│   └── PersistenceModels.swift            # Swift data models
├── Views/
│   └── ExperimentListView.swift           # UI views
└── ContentView.swift                      # Main view (updated)
```

## What Was Synced

✅ **4 Configurations** with **20 Bands Each**
- Persistence diagrams (H0, H1, H2 homology)
- Betti curves
- Persistence landscapes
- Point clouds (3D PCA spaces)
- Statistics (feature counts, lifetimes)

## Next Steps for Xcode

1. **Open Xcode**: `PersistenceViewer.xcodeproj`

2. **Add Data Folder**:
   - Right-click `PersistenceViewer` folder in Project Navigator
   - "Add Files to PersistenceViewer..."
   - Select `Data/` folder
   - ✓ "Create folder references" (blue folder)
   - ✓ "Copy items if needed"
   - ✓ Target: PersistenceViewer
   - Click "Add"

3. **Build and Run** (Cmd+R)

## Swift Files Created

All code is ready to use:

- ✅ `PersistenceModels.swift` - Data models with JSON decoding
- ✅ `ExperimentListView.swift` - Complete navigation UI
- ✅ `ContentView.swift` - Updated to use ExperimentListView

## Future Syncs

After running new simulations:

```bash
# In Mobius Band repo
cd "/Users/briandizio/Documents/2023-Now/Personal/Social/Mobius Band/Fall Orange Flowers 2025/"

# 1. Run simulation (MATLAB)

# 2. Compute TDA
python fixedComputePerBandTDA.py

# 3. Sync to Vision Pro
./sync_to_visionpro.sh

# 4. In Vision Pro app, tap refresh button (↻)
```

## Data Structure

Your exported JSON contains:

```json
{
  "name": "experiment_2025-10-06_220239",
  "configurations": [
    {
      "config_id": 1,
      "bands": [
        {
          "band_id": 1,
          "persistence_diagram": [
            {
              "birth": 0.0,
              "death": 10.12,
              "lifetime": 10.12,
              "dimension": 0,
              "homology_class": "H0"
            }
          ],
          "statistics": {...},
          "betti_curves": {...},
          "point_cloud": {...}
        }
      ]
    }
  ]
}
```

## Color Coding

- 🔵 **H0** (Blue): Connected components
- 🟢 **H1** (Green): Loops/holes
- 🔴 **H2** (Red): Voids

## Troubleshooting

### Python Issues
- Use `python` (conda), not `python3`
- Test with: `python -c "import numpy; print('OK')"`

### Sync Issues
- Run `./test_sync.sh` first
- Check for `python_exports/` in experiment

### Vision Pro App Issues
- Ensure Data/ folder is in Xcode (blue folder icon)
- Check JSON files exist in Data/
- View Xcode console for error messages

## Documentation

- 📘 `QUICKSTART.md` - Getting started guide
- 📗 `SYNC_WORKFLOW.md` - Detailed pipeline docs
- 📙 `QUICK_REFERENCE.md` - This file

---

**Status**: ✅ Ready to build and run on Vision Pro!
