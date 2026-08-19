root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root,'code')));
run_all_models;
build_outputs(root);
run_regression_outputs(root);
fprintf('All model, table, and figure outputs were written to %s\n',fullfile(root,'outputs'));
