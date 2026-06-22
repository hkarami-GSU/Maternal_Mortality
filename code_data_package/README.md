# Maternal Mortality Counterfactual Modelling Code and Data

This repository contains code and data supporting the country-level maternal mortality counterfactual modelling workflows for the study:

**Excess maternal deaths and maternal mortality ratios during the COVID-19 pandemic period: a global WHO/UN MMEIG country-level counterfactual modelling study**

The package includes:

- `code/`: MATLAB and Python scripts, including the SubEpiPredict modelling toolbox.
- `data/`: WHO/UN MMEIG-derived input datasets used by the modelling workflows.

The default SubEpiPredict configuration runs the maternal mortality ratio (MMR) workflow. To run the maternal deaths workflow in MATLAB, set:

```matlab
setenv('MMEIG_SUBEPI_WORKFLOW','maternal_deaths')
```

Then run the batch script from the SubEpiPredict toolbox folder:

```matlab
Run_all_cols_par
```

The workflow fits the configured country-level models using the 2000-2019 calibration period and generates 2020-2023 counterfactual forecast outputs. Generated files are written locally when the scripts are run.
