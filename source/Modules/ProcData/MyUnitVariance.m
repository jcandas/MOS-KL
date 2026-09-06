function T = MyUnitVariance(T)

A = table2array(T);
mu = mean(A,2);
sigma = std(A,[],2);
A = (A - mu) ./ sigma;
T = array2table(A, ...
    "RowNames", T.Properties.RowNames, ...
    "VariableNames", T.Properties.VariableNames);



end