# SubEpiPredict Toolbox

SubEpiPredict is a MATLAB toolbox for fitting and forecasting trajectories using the ensemble n-sub-epidemic modelling framework. In this repository, the toolbox is configured for country-level maternal mortality ratio and maternal deaths counterfactual modelling workflows.

## Requirements

- MATLAB
- Optimization Toolbox
- Global Optimization Toolbox
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox is recommended for batch runs

## Study Configuration

The study-specific settings are defined in:

- `ensemble n-subepidemic code v1.0/options.m`
- `ensemble n-subepidemic code v1.0/options_forecast.m`

Default workflow:

```matlab
Run_all_cols_par
```

Maternal deaths workflow:

```matlab
setenv('MMEIG_SUBEPI_WORKFLOW','maternal_deaths')
Run_all_cols_par
```

The batch runner copies the relevant data from `data/raw/`, creates local `input/` and `output/` folders inside the toolbox directory, fits each country column, and writes generated MATLAB and CSV outputs to `output/`.

## Model Settings

The configured study workflows use:

- 2000-2019 calibration period
- 2020-2023 forecast horizon
- yearly time step
- two sub-epidemic patches
- GLM growth model
- least-squares estimation with Normal errors
- 60 MultiStart initial points
- 300 bootstrap realizations

## Main Entry Points

- `Run_all_cols_par.m`: batch country-level run for the configured workflow.
- `Run_Fit_subepidemicFramework.m`: model fitting for a selected country column.
- `plotForecast_subepidemicFramework.m`: forecast generation for a selected fitted model.
- `plotFit_subepidemicFramework.m`: fitted-model summaries and diagnostics.
- `plotRankings_subepidemicFramework.m`: ranked-model summaries.

## Reference

Chowell, G., Dahal, S., Bleichrodt, A., Tariq, A., Hyman, J. M., & Luo, R. (2024). SubEpiPredict: A tutorial-based primer and toolbox for fitting and forecasting growth trajectories using the ensemble n-sub-epidemic modeling framework. *Infectious Disease Modelling*, 9(2), 411-436.
