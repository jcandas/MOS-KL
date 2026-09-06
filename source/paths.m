% Record the source root so the pipeline can build portable paths (read via
% getenv('PNAS_ROOT')). This file lives in source/, so its own folder IS the root.
srcdir = fileparts(mfilename('fullpath'));
setenv('PNAS_ROOT', srcdir);

d = fileparts(srcdir);       % submission root (parent of source/)
a = genpath(d);
path(path,a);

x = dir(pwd);
pattern = "." + ("e"|"o") + digitsPattern(7);
isML_Features = arrayfun(@(y) contains(y.name, pattern), x);
ML_FeatureFiles = x(isML_Features);
arrayfun(@(y) delete(y.name), ML_FeatureFiles);

p = pwd;
