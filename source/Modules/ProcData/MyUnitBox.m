function T = MyUnitBox(T)

A = table2array(T);
M = max(A, [], 2); m = min(A, [], 2);
midpoint = 0.5 * (m + M);
width = (M - m)/2;
A = A - midpoint;
A = A ./ width;
T = array2table(A, ...
    "RowNames", T.Properties.RowNames, ...
    "VariableNames", T.Properties.VariableNames);



end