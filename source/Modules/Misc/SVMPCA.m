function [Datas, parameters] = SVMPCA(Datas, parameters, methods)

if parameters.misc.PCA
V = [Datas.A.CovTraining, Datas.B.CovTraining];
n = size(V,2); m = mean(V,2);
V = (n-1)^(-0.5) * (V - m);
[U,S,~] = svd(V,'econ', 'vector');
EV = cumsum(S.^2) / sum(S.^2);
npc = find(EV >= parameters.multilevel.concentration, 1, 'first');
Up = U(:,1:npc);

for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
    Datas.(C).(set) = Up' * Datas.(C).(set);
end, end
end

end