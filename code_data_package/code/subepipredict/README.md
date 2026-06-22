# SubEpiPredict Workflow

This folder contains the SubEpiPredict / ensemble n-sub-epidemic modelling toolbox used to fit country-level counterfactual models and generate forecast outputs.

The toolbox source is located in:

- `SubEpiPredict-Toolbox-main/`

The included `options.m` is configured for the study workflows:

- `yearly-mmr-deaths-world` by default.
- `yearly-maternal-deaths-world` when MATLAB is run with `setenv('MMEIG_SUBEPI_WORKFLOW','maternal_deaths')`.

Both workflows use the 2000-2019 calibration window, a 4-year forecast horizon for 2020-2023, two sub-epidemic patches, GLM growth, least-squares/Normal errors, 60 MultiStart initial points, and 300 bootstrap realizations.

Run `Run_all_cols_par.m` from the toolbox code folder to execute the configured batch workflow.
