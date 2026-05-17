# Universal TDA Data Format for PersistenceViewer

## Overview

PersistenceViewer accepts TDA data from **any** Golden Enterprise Solution via the Universal TDA Format. This format generalizes the original Mobius Band sonar-specific schema into a Solution-agnostic container.

## Format Specification

```json
{
  "name": "Human-readable experiment name",
  "source": {
    "solution_id": "GES-XXX",
    "solution_name": "Solution Name",
    "export_version": "1.0",
    "export_timestamp": "2026-05-11T01:30:00Z"
  },
  "description": "Optional description of this experiment",
  "datasets": [
    {
      "name": "Dataset display name",
      "group_name": "Optional grouping label",
      "group_id": 1,
      "dataset_id": 1,
      "persistence_diagram": [
        {
          "id": 1,
          "birth": 0.0,
          "death": 0.95,
          "lifetime": 0.95,
          "dimension": 0,
          "homology_class": "H0"
        }
      ],
      "statistics": {
        "H0": {"count": 3, "mean_lifetime": 0.38, "max_lifetime": 0.95, "total_persistence": 1.15},
        "H1": {"count": 2, "mean_lifetime": 0.22, "max_lifetime": 0.30, "total_persistence": 0.45},
        "H2": {"count": 1, "mean_lifetime": 0.50, "max_lifetime": 0.50, "total_persistence": 0.50}
      },
      "betti_curves": {
        "values": [[3, 2, 1], [2, 1, 0]],
        "n_bins": 2,
        "dimensions": ["H0", "H1", "H2"]
      },
      "persistence_landscape": {
        "values": [[0.1, 0.2, 0.3], [0.05, 0.1, 0.15]],
        "shape": [2, 3]
      },
      "point_cloud": {
        "points": [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]],
        "n_points": 2,
        "dimensions": 3
      },
      "metadata": {
        "any_key": "any_value"
      }
    }
  ],
  "global_visualizations": {
    "global_pca": {"points": [[...]], "n_points": 100, "dimensions": 3},
    "phase_space": {"points": [[...]], "n_points": 2000, "dimensions": 3},
    "manifold_embeddings": {
      "isomap": {"points": [[...]], "n_points": 100, "dimensions": 3},
      "diffusion_map": {"points": [[...]], "n_points": 100, "dimensions": 3},
      "lle": {"points": [[...]], "n_points": 100, "dimensions": 3}
    },
    "scatterer_labels": {"labels": [1, 2, 3], "n_labels": 3}
  },
  "metadata": {
    "any_key": "any_value"
  }
}
```

## Required Fields

- `name` (string): Experiment name
- `source` (object): Solution identification
  - `solution_id` (string): GES ID
  - `solution_name` (string): Human-readable name
- `datasets` (array): At least one dataset
  - Each dataset requires `name` (string)

## Optional Fields

All other fields are optional. Include what your Solution produces:
- `persistence_diagram`: Birth-death pairs with homology dimension
- `statistics`: Per-homology-class summary stats
- `betti_curves`: Betti numbers across filtration values
- `persistence_landscape`: Layered landscape functions
- `point_cloud`: 3D point coordinates for RealityKit rendering
- `metadata`: Arbitrary key-value pairs for Solution-specific data

## Backward Compatibility

The original Mobius Band format (with `configurations` → `bands`) is still fully supported. The loader auto-detects the format and converts legacy data to the universal schema transparently.

## Exporting from Your Solution

### Python

```python
import json
from datetime import datetime

def export_tda_for_vision(persistence_features, solution_name, solution_id):
    """Export TDA results in Universal TDA Format for PersistenceViewer."""
    experiment = {
        "name": f"{solution_name} TDA Export",
        "source": {
            "solution_id": solution_id,
            "solution_name": solution_name,
            "export_version": "1.0",
            "export_timestamp": datetime.utcnow().isoformat() + "Z"
        },
        "datasets": [
            {
                "name": "Dataset 1",
                "persistence_diagram": [
                    {
                        "id": i,
                        "birth": float(f["birth"]),
                        "death": float(f["death"]),
                        "lifetime": float(f["death"] - f["birth"]),
                        "dimension": int(f["dimension"]),
                        "homology_class": f"H{f['dimension']}"
                    }
                    for i, f in enumerate(persistence_features, 1)
                ]
            }
        ]
    }
    return json.dumps(experiment, indent=2)
```

### MATLAB

```matlab
function export_tda_for_vision(diagrams, solution_name, solution_id, output_path)
    experiment.name = [solution_name ' TDA Export'];
    experiment.source.solution_id = solution_id;
    experiment.source.solution_name = solution_name;
    experiment.source.export_version = '1.0';
    experiment.source.export_timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SSZ');
    
    for i = 1:length(diagrams)
        dataset.name = sprintf('Dataset %d', i);
        dataset.persistence_diagram = diagrams{i};
        experiment.datasets{i} = dataset;
    end
    
    jsonStr = jsonencode(experiment);
    fid = fopen(output_path, 'w');
    fprintf(fid, '%s', jsonStr);
    fclose(fid);
end
```

## Connected Solutions

Solutions that can export to this format:
- **SSEUQFT**: Sonar TDA results (sonar_tda_results)
- **Pendulum Solver**: MPC trajectory persistence (PS-07 pipeline)
- **Data Phi Sheaf**: Sheaf category classification (DPS-03 classifier)
- **Maze Generation**: Homotopy persistence from maze structures
- **Golden Core**: PCA embeddings and general TDA relay
- **BBATHCS**: Behavioral biometric persistence diagrams
