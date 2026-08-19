function run_example_country
here = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(here));
run_subepidemic(projectRoot,'mmr','normal',1);
run_subepidemic(projectRoot,'maternal_deaths','normal',1);
end
