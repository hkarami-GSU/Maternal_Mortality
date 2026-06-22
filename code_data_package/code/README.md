# Code

This folder contains the analysis scripts and modelling toolbox used for the maternal mortality counterfactual modelling workflows.

Contents:

- `matlab/`: MATLAB scripts for data preparation, workflow-specific summaries, and figure generation.
- `python/`: Python utilities for table-generation and summary checks.
- `subepipredict/`: SubEpiPredict toolbox code configured for the MMR and maternal deaths workflows.

The SubEpiPredict batch runner creates local `input/` and `output/` folders inside the toolbox directory when executed. Generated model files, forecast files, tables, and figures should be reviewed against the manuscript outputs before public archival use.
