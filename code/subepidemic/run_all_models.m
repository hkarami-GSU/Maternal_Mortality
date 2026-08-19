function run_all_models
here = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(here));
run_subepidemic(projectRoot,'mmr','normal','all');
run_subepidemic(projectRoot,'mmr','poisson','all');
run_subepidemic(projectRoot,'maternal_deaths','normal','all');
run_subepidemic(projectRoot,'maternal_deaths','poisson','all');
collect_forecasts(projectRoot);
end
