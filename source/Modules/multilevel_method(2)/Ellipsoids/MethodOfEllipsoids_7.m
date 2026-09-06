function parameters = MethodOfEllipsoids_7(Datas, parameters, methods)
%MA and Mres are ascending

if ~parameters.multilevel.chooseTrunc, return, end

%% Write Data in Class A eigenbasis.
D1 = methods.Multi2.EigenbasisA(Datas, parameters, methods);

%% Find the indices at which the Class A explained variance increases by 5 percentage points
LambdaA = mean(D1.A.CovTraining.^2, 2);
EV = cumsum(LambdaA) / sum(LambdaA);
thresholds = 0.75:0.025:0.95;
% Determine the optimal number of components based on the thresholds
optimalComponents = arrayfun(@(t) find(EV >= t, 1, 'first'), thresholds);
MA = unique(optimalComponents);

%MA = MA(end:-1:1);
if length(MA) < 0.5*length(thresholds)
    MA = [MA MA(end)+1:length(thresholds)]; 
    MA = unique(MA);
end

%% Obtain baseline values
BestMA = MA(1);
BestMres = parameters.data.numofgene - BestMA;
BestAUC = 0;
BestAccuracy = 0;

%fprintf('Baseline Accuracy: %0.3f \n', BaselineAccuracy);


for m = MA
   
%% Get features belonging in residual eigenspace
for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
        D2.(C).(set) = D1.(C).(set)(m+1:end, :);
end, end

D3 = methods.Multi2.EigenbasisB(D2, parameters, methods);

%% Find indices for which class A variance increases by 5 percentage points

N = arrayfun( @(C) size(D3.(C).Machine,2), 'AB');
sumN = sum(N); PA = N(1)/sumN;
F = size(D3.A.Machine,1);
D4 = [cumsum(D3.A.Machine.^2,1) , cumsum(D3.B.Machine.^2,1)];
isA = 1:sumN; isA = isA <= N(1);

AUCs = nan(F,1);
OPTs = nan(F,2);

for Mres = 1:F
    [~,~,~,...
     AUCs(Mres), ...
    OPTs(Mres,:)] = ...
    perfcurve(isA, D4(Mres,:), true);
end
Accuracies = OPTs  * [PA;1-PA];

maxAUC = max(AUCs);
stdDevAUC = std(AUCs);
Mress = find(AUCs > quantile(AUCs, parameters.multilevel.concentration));
OPT2 = Accuracies(Mress,1);
[max2, ismax2] = max(OPT2);
Mres = Mress(ismax2);

if max2 > BestAccuracy + eps
    BestAccuracy = max2;
    BestMA = m;
    BestMres = Mres;
    BestAUC = maxAUC;
end

fprintf(['Best MA = %d. Best Mres = %d.\n' ...
    'Best AUC = %0.3f. Best Accuracy = %0.3f.\n'], ...
    BestMA, BestMres, BestAUC, BestAccuracy);
fprintf('---------------------------------\n');

end

fprintf('\n');

if BestMA == 0, keyboard, end
parameters.snapshots.k1 = BestMA;
parameters.multilevel.Mres = BestMres;
parameters.multilevel.Mres_auto = BestMres;

end

%==========================================================================
