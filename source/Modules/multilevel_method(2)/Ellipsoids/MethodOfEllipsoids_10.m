function parameters = MethodOfEllipsoids_10(Datas, parameters, methods)
%MA is ascending. Mres is descending

if ~parameters.multilevel.chooseTrunc, return, end

%% Write Data in Class A eigenbasis.
% Yin = Datas2Cell(Datas);
% Yout = methods.Multi2.BinarySVD(Datas.A.CovTraining, Yin);
% D1 = Datas2Cell(Yout);
[~, D1.A.CovTraining,...
    D1.A.Machine,...
    D1.B.CovTraining,...
    D1.B.Machine] = methods.Multi2.BinarySVD(Datas.A.CovTraining,...
    Datas.A.CovTraining,...
    Datas.A.Machine,...
    Datas.B.CovTraining,...
    Datas.B.Machine);

% for C = 'AB', for set = ["CovTraining", "Machine"]
%         D1.(C).(set) = methods.Multi2.BinarySVD(Datas.A.CovTraining, ...
%             Datas.(C).(set));
% end, end

%% Find the indices at which the Class A explained variance increases by 5 percentage points
LambdaA = mean(D1.A.CovTraining.^2, 2);
EV = cumsum(LambdaA) / sum(LambdaA);
thresholds = 0.75:0.05:0.95;
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
BestAccuracy = MyClassifier(Datas, parameters, methods);
BaselineAccuracy = BestAccuracy;
PrintAcc(BestMA, BestMres, BestAccuracy, 'Baseline');
%fprintf('Baseline Accuracy: %0.3f \n', BaselineAccuracy);

for m = MA
   
%% Get features belonging in residual eigenspace
for C = 'AB', for set = ["CovTraining", "Machine"]
        D2.(C).(set) = D1.(C).(set)(m+1:end, :);
end, end

XB = D2.B.CovTraining - mean(D2.B.CovTraining, 2);

%% Write Data in Class B eigenspace
% for C = 'AB', for set = ["CovTraining", "Machine"]
%         D3.(C).(set) = methods.Multi2.BinarySVD(XB, D2.(C).(set));
% end, end
if parameters.multilevel.svmonly == 2
% Yin = Datas2Cell(D2);
% Yout = methods.Multi2.BinarySVD(XB, Yin);
% D3 = Datas2Cell(Yout);

[~, D3.A.CovTraining,...
    D3.A.Machine,...
    D3.B.CovTraining,...
    D3.B.Machine] = methods.Multi2.BinarySVD(XB,...
    D2.A.CovTraining,...
    D2.A.Machine,...
    D2.B.CovTraining,...
    D2.B.Machine);
elseif parameters.multilevel.svmonly == 0
D3 = D2;
end

%% Find indices for which class A variance increases by 5 percentage points
XB = D3.B.CovTraining - mean(D3.B.CovTraining,2);
EV1 = mean( cumsum( XB.^2, 1), 2);
EV2 = mean( sum(XB.^2, 1), 2);
EV3 = EV1 / EV2;
% EV1 = mean( cumsum( D3.B.CovTraining.^2, 1), 2);
% EV2 = mean( sum(D3.B.CovTraining.^2, 1), 2);
% EV3 = EV1 / EV2;
thresholds2 = 0.05:0.1:0.95;
optimalComponents = arrayfun(@(t) find(EV3 >= t, 1, 'first'), thresholds2);
Mres = unique(optimalComponents);
if length(Mres) < 0.5*length(thresholds2)
    MresAppend = linspace(Mres(end), size(D3.A.CovTraining,1), length(thresholds2));
    MresAppend = floor(MresAppend);
    Mres = [Mres MresAppend]; 
    Mres = unique(Mres);
end
Mres = Mres(end:-1:1);

%% Cross Validate on an SVM
for M = Mres %Mres(end:-1:1)
    parameters.multilevel.iMres = M;
    D4 = MySepFilter(D3, parameters);
    accuracy = MyClassifier(D4, parameters, methods);
    
    %PrintAcc(m, M, accuracy, '')
    if accuracy >= BestAccuracy
        BestMA = m; 
        BestAccuracy = accuracy;  
        BestMres = M;
    end 
      
    
end


end

PrintAcc(BestMA, BestMres, BestAccuracy, 'Best')
% fprintf('Best MA = %d, Best Mres = %d', BestMA, BestMres);
% fprintf('Best Accuracy: %0.3f \n', BestAccuracy);
if BaselineAccuracy >= BestAccuracy
    warning('Failed to find optimal separating hyperparameters')
end

parameters.snapshots.k1 = BestMA;
%parameters.multilevel.l = 1;
parameters.multilevel.Mres = BestMres;
parameters.multilevel.Mres_auto = BestMres;

end

%==========================================================================
function Datas = MySepFilter(Datas, parameters)

iFeatures = 1:parameters.multilevel.iMres;
residual = size(Datas.A.CovTraining,1) - parameters.multilevel.iMres;

if strcmp(parameters.multilevel.eigentag, 'smallest')
    iFeatures = iFeatures + residual;
end

for C = 'AB', for set = ["CovTraining", "Machine"]
    Datas.(C).(set) = Datas.(C).(set)(iFeatures,:);
end, end


end
%==========================================================================
function accuracy = MyClassifier(Datas, parameters, methods)

Train = [Datas.A.CovTraining' ; Datas.B.CovTraining' ];
labelsTrain = 1:size(Train,1) <= size(Datas.A.CovTraining,2);
Test = [Datas.A.Machine' ; Datas.B.Machine'];
labelsTest = 1:size(Test,1) <= size(Datas.A.Machine,2);

switch parameters.svm.kernal
    case true, SVMfcn = @(X,Y) fitcsvm(X,Y);
    case false, SVMfcn = @(X,Y) fitcsvm(X,Y, 'KernelFunction', 'RBF', 'KernelScale', 'auto');
end 

MdlSVM = SVMfcn(Train, labelsTrain);
[C,~] = predict(MdlSVM, Test);

right = sum(C(:) == labelsTest(:));
accuracy = right / length(C);

end
%==========================================================================
function PrintAcc(MA, Mres, Acc, isBest)

if false
fprintf(['%s MA = %d,' ...
    '%s Mres = %d,' ...
    '%s Accuracy = %0.3f \n'], ...
    isBest, MA, ...
    isBest, Mres, ...
    isBest, Acc)
end

end
%==========================================================================
function Cell = Datas2Cell(Datas)

if isstruct(Datas)
Cell = {Datas.A.CovTraining, Datas.B.CovTraining,...
    Datas.A.Machine, Datas.B.Machine};
elseif iscell(Datas)
    Cell.A.CovTraining = Datas{1};
    Cell.B.CovTraining = Datas{2};
    Cell.A.Machine = Datas{3};
    Cell.B.Machine = Datas{4};
end

end