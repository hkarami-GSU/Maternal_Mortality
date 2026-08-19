# Maternal mortality replication package

This package contains the MATLAB code and data used for the manuscript:

**Global Excess Maternal Mortality During COVID-19: Country-Level Counterfactual Estimates and Associated Factors**

No manuscript figures, PDFs, or publication tables are included. The package starts with the source data, processed model inputs, compact numerical model results, and MATLAB code needed to reproduce the analysis.

## Requirements

- MATLAB R2021a or later
- Statistics and Machine Learning Toolbox
- Global Optimization Toolbox
- Parallel Computing Toolbox is optional

## Quick reproduction

Open MATLAB, set the Current Folder to this directory, and run:

```matlab
run_all
```

This uses the compact country-level numerical results in `outputs/model_results` and reproduces the analysis outputs locally.

## Fit one example country

Run:

```matlab
run_example
```

This fits the MMR and maternal-death models for Afghanistan using the same model settings used in the study.

## Refit every country

Run:

```matlab
run_models
```

This refits the normal and Poisson versions of both outcomes for all 195 countries and then rebuilds the derived analysis outputs. This is the slowest option because it uses 30 starting points and 300 bootstrap samples for the country-level models.

## Main folders

- `code/subepidemic`: model fitting and forecast collection
- `code/regression`: regression and sensitivity analyses
- `code/figures_tables`: MATLAB routines that can recreate manuscript outputs when needed
- `data/source`: source data files
- `data/processed`: model inputs and the regression dataset
- `outputs/model_results`: compact numerical country-year model results used by `run_all`
- `outputs/regression/full_model_analysis_data.csv`: analysis dataset used by the regression scripts

## Model settings

The main settings are in `code/subepidemic/toolbox/options.m` and `options_forecast.m`:

- calibration period: 2000-2019
- forecast period: 2020-2023
- one or two logistic components
- 30 optimization starting points
- 300 bootstrap samples
- four top models retained for the ensemble
- AICc weights
- normal and Poisson error structures

## Data sources

The analysis uses WHO/UN MMEIG maternal mortality estimates, WHO maternal health service disruption data, UNICEF antenatal care data, and UNICEF skilled birth attendance data. Full source details are listed in `DATA_SOURCES.md`.
