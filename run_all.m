root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root,'code')));
build_outputs(root);
run_regression_outputs(root);
fprintf('Tables and figures were written to %s\n',fullfile(root,'outputs'));
