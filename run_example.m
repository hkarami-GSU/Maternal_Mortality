root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root,'code')));
run_example_country;
fprintf('Afghanistan model outputs were written to %s\n',fullfile(root,'code','subepidemic','toolbox','output'));
