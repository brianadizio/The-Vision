# Vision Pro GUI Architecture
## Mirroring MATLAB Multi-Scale Analysis

This document describes how the Vision Pro PersistenceViewer mirrors your MATLAB GUI hierarchy.

## MATLAB GUI Hierarchy

### 1. Local Scale GUI (`SonarSimulationGUI.m`)
**Purpose**: Detailed analysis of a single configuration

**Key Features**:
- Configuration selector (point scatterer count)
- Frequency band slider (1-20)
- Visualization types:
  - PCA Space (3D scatter with PC1/PC2/PC3)
  - Phase Space (3D trajectory with start/end markers)
  - Frequency Signature (2D heatmap: rotation × frequency)
  - ISOMAP/LLE/Diffusion Maps (manifold embeddings)
  - Betti Numbers (H0, H1, H2 curves)
  - Persistence Diagram (birth/death scatter)
  - Persistence Landscape (multi-layer functions)
  - Distance Matrices (4 types: phase, isomap, lle, diffmap)

**Right Panel Metrics**:
- Topological Features: β₀, β₁, β₂, χ (Euler characteristic)
- Manifold Metrics: ISOMAP/LLE/DiffMap quality scores
- Computational Metrics: timing, config info

### 2. Medium Scale GUI (`MediumScaleGUI.m`)
**Purpose**: Cross-frequency band analysis

**Key Features**:
- Frequency band comparison
- Per-band TDA analysis
- Band-to-band transitions
- Topological feature evolution across spectrum

### 3. Global Scale GUI (`GlobalScaleGUI.m`)
**Purpose**: Multi-experiment parameter space exploration

**Key Features**:
- Multi-experiment loading
- Parameter space mapping (X/Y parameter selection)
- Analysis types:
  - Parameter Map (scatter in 2D parameter space)
  - Feature Evolution (entropy/stability trends)
  - Cross-Experiment Comparison (similarity matrix)
  - Clustering View (k-means on feature space)
  - Statistical Summary (distributions, correlations)
  - Correlation Matrix (feature relationships)
- 3D parameter view
- Experiment details table

## Vision Pro Architecture

### Navigation Hierarchy

```
Experiments (Global Scale)
  └─ Configurations (4 scatterer configs)
      └─ Frequency Bands (20 bands per config)
          └─ Visualizations (Local Scale)
              ├─ Persistence Diagram
              ├─ Point Cloud (3D PCA)
              ├─ Betti Curves
              ├─ Phase Space
              ├─ Manifold Embeddings (Isomap/LLE/DiffMap)
              └─ Frequency Signature
```

### SwiftUI View Structure

#### Level 1: Global Scale
**`ExperimentListView`** - Main entry point
- Lists all experiments
- Shows config/band counts
- Tap to drill down

**`CrossExperimentView`** (Future)
- Parameter space scatter plots
- Similarity matrix heatmap
- Statistical summaries

#### Level 2: Medium Scale
**`ConfigurationListView`**
- Shows 4 configurations per experiment
- Band counts per config
- Statistics summary (H0/H1/H2 counts)

**`FrequencyBandGridView`** (Future)
- Visual grid of all 20 bands
- Color-coded by topological complexity
- Scrubber for animation through spectrum

#### Level 3: Local Scale
**`BandDetailView`** - Currently implemented
- Statistics cards (H0, H1, H2)
- Placeholders for visualizations

**`PersistenceDiagramView`** (To Build)
- Interactive 2D scatter (birth vs death)
- Tap points for details
- Color by homology dimension
- Diagonal reference line

**`PointCloud3DView`** (To Build)
- RealityKit 3D visualization
- Rotate/zoom gestures
- Color by 4th PC or labels
- Toggle PCA vs Phase Space

**`BettiCurvesView`** (To Build)
- Line chart: distance threshold vs Betti numbers
- H0/H1/H2 traces with colors
- Interactive threshold scrubber

**`ManifoldEmbeddingView`** (To Build)
- Tabs for Isomap/LLE/DiffMap
- 3D scatter visualization
- Comparison mode

**`FrequencySignatureView`** (To Build)
- 2D heatmap (rotation × frequency)
- Pinch to zoom
- Color scale controls

## Data Flow

### Export Pipeline

```
MATLAB Simulation
  ↓
fixedComputePerBandTDA.py
  ↓
experiment_*/python_exports/
  ├─ global_pca_spaces.csv
  ├─ circular_phase_spaces.csv
  ├─ isomap_embedding.csv
  ├─ lle_embedding.csv
  ├─ diffmap_embedding.csv
  ├─ scatterer_labels.csv
  └─ config_*/band_*/
      ├─ persistence_diagram.npy
      ├─ betti_curves.npy
      ├─ persistence_landscape.npy
      ├─ persistence_images.npy
      └─ point_cloud.npy
  ↓
export_to_visionpro.py
  ↓
PersistenceViewer/Data/*.json
  ↓
Swift PersistenceDataLoader
  ↓
SwiftUI Views
```

### JSON Structure

```json
{
  "name": "experiment_2025-10-06_220239",
  "export_timestamp": "2025-10-11T...",
  "global_visualizations": {
    "global_pca": {
      "points": [[x,y,z], ...],
      "n_points": 100,
      "dimensions": 3
    },
    "phase_space": {
      "points": [[x,y,z], ...],
      "n_points": 2000
    },
    "manifold_embeddings": {
      "isomap": {"points": [...], "n_points": 2000},
      "lle": {"points": [...], "n_points": 2000},
      "diffusion_map": {"points": [...], "n_points": 2000}
    },
    "scatterer_labels": {
      "labels": [1,1,1,2,2,2,...],
      "n_labels": 2000
    }
  },
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
              "death": 10.12,
              "lifetime": 10.12,
              "dimension": 0,
              "homology_class": "H0"
            }
          ],
          "statistics": {
            "H0": {"count": 2, "mean_lifetime": 12.1, ...},
            "H1": {"count": 1, "mean_lifetime": 0.0, ...},
            "H2": {"count": 1, "mean_lifetime": 0.0, ...}
          },
          "betti_curves": {
            "values": [[...], [...], [...]],
            "n_bins": 100,
            "dimensions": ["H0", "H1", "H2"]
          },
          "persistence_landscape": {
            "values": [[...]],
            "shape": [5, 100]
          },
          "point_cloud": {
            "points": [[x,y,z], ...],
            "n_points": 100,
            "dimensions": 3
          }
        }
      ]
    }
  ]
}
```

## Visualization Mapping

| MATLAB GUI | Data File | Vision Pro View | Status |
|------------|-----------|-----------------|--------|
| PCA Space | point_cloud.npy | PointCloud3DView | Planned |
| Phase Space | circular_phase_spaces.csv | PhaseSpace3DView | Planned |
| Frequency Signature | frequency_signatures.csv | FrequencyHeatmapView | Planned |
| ISOMAP | isomap_embedding.csv | ManifoldView(isomap) | Planned |
| LLE | lle_embedding.csv | ManifoldView(lle) | Planned |
| Diffusion Maps | diffmap_embedding.csv | ManifoldView(diffmap) | Planned |
| Betti Numbers | betti_curves.npy | BettiCurvesView | Planned |
| Persistence Diagram | persistence_diagram.npy | PersistenceDiagramView | Planned |
| Persistence Landscape | persistence_landscape.npy | LandscapeView | Planned |
| Distance Matrices | distance_matrix_*.csv | DistanceMatrixView | Planned |

## Implementation Priority

### Phase 1: Core Visualization (Current Sprint)
1. ✅ Data export pipeline
2. ✅ Swift data models
3. ✅ Navigation hierarchy
4. ✅ Statistics display
5. ⏳ Persistence diagram view
6. ⏳ 3D point cloud view

### Phase 2: Advanced Visualizations
7. Betti curves (line charts)
8. Phase space trajectories
9. Manifold embeddings (3 types)
10. Frequency signature heatmaps

### Phase 3: Interactive Features
11. Band-to-band animation
12. Cross-experiment comparison
13. Parameter space exploration
14. Export/sharing capabilities

### Phase 4: Advanced Analytics
15. Real-time filtering
16. Statistical comparisons
17. Clustering visualization
18. Correlation matrices

## RealityKit Integration

### 3D Visualizations
- **Point Clouds**: Use `ModelEntity` with custom geometry
- **Persistence Diagrams**: 2D chart in immersive space
- **Phase Space**: Animated trajectory with ModelEntity
- **Manifolds**: Multi-colored scatter plots

### Interaction Patterns
- **Pinch to zoom**: Scale ModelEntity transform
- **Rotate**: Apply rotation transform
- **Tap to select**: Ray casting for point selection
- **Two-hand gestures**: Multi-select, filtering

## Color Schemes

Match MATLAB color conventions:
- **H0 (Components)**: Blue (`#0000FF`)
- **H1 (Loops)**: Red (`#FF0000`)
- **H2 (Voids)**: Green (`#00FF00`)
- **Gradients**: Jet colormap for continuous data
- **Labels**: Distinct colors per scatterer config

## Performance Considerations

### Data Loading
- Lazy load visualizations on demand
- Cache rendered views
- Progressive loading for large datasets

### Rendering
- LOD (Level of Detail) for point clouds
- Simplified geometry for distant objects
- Asynchronous data processing

### Memory
- Release unused experiment data
- Compress JSON with gzip
- Stream large arrays

## Next Steps

1. Complete persistence diagram visualization
2. Implement RealityKit point cloud renderer
3. Add Betti curve line charts
4. Build frequency band scrubber/animator
5. Create cross-experiment comparison view

---

**Vision Pro = Immersive MATLAB GUI** 🚀
