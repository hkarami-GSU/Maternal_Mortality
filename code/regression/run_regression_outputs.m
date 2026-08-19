function run_regression_outputs(projectRoot)
if nargin < 1 || isempty(projectRoot)
    here = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(here));
end
build_regression_input(projectRoot);
full_model_figure(projectRoot);
country_influence_figure(projectRoot);
backward_aic_tables(projectRoot);
single_disruption_outputs(projectRoot);
end
