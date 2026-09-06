function parameters = MethodOfEllipsoids_5(Datas, parameters, methods)
%Finds the number of Class A points lying inside the 0.95-Ellipsoid
%determined by Class B plut the number of Class B points lying inside the
%0.95-Ellipsoid determined by Class A;

close all
if ~parameters.multilevel.chooseTrunc, return, end

%% Copy over Training Portion of Data and eliminate testing data
for C = 'AB', D.(C).rawdata = Datas.(C).Training; end
for Set = ["CovTraining", "Machine", "Testing"], D.B.(Set) = D.B.rawdata; end


BestMA = []; BestMres = []; BestMisplaced = Inf;
BestRelChangeMSD = Inf; 

CompMSD0 = @(X)  ((sum(X.^2,1) + sum(X'.^2,2)) - 2*X'*X );
CompMSD = @(X) 1 / (size(X,2)^2 - size(X,2)) * sum(CompMSD0(X),'all');

%% Separate Testing Cohort from Class A and Class B Training
switch parameters.data.validationType
    case 'Synthetic' 
        NATest = parameters.synthetic.NTest;
        NBTest = parameters.synthetic.NTest;
    case 'Cross'
        NATest = parameters.cross.NTestA;
        NBTest = parameters.cross.NTestB;
    case 'Kfold'
        NATest = parameters.Kfold;
        NBTest = parameters.Kfold;
end
Testsize.A = NATest; Testsize.B = NBTest;

for C = 'AB'
D.(C).CovTraining = D.(C).rawdata;
%D.(C).CovTraining(:,Testsize.(C)) = [];
D.(C).CovTraining(:,end) = [];
D.(C).Machine = D.(C).CovTraining;
NC = size(D.(C).CovTraining,2);
%D.(C).Testing = D.(C).rawdata(:,Testsize.(C));
D.(C).Testing = D.(C).rawdata(:,end);
MC = mean(D.(C).CovTraining,2);
XC = (NC - 1)^(-0.5)*(D.(C).CovTraining - MC);
[U.(C), S.(C), ~] = svd(XC, 'econ', 'vector');
end


%% Create List of Admissible Truncation Parameters

%Dot Products represents the amount of overlap between the mth truncate of
%vA and all of vB
DotProductsAB = ((U.A .* S.A')' * (U.B .* S.B')).^2; 
DotProductsAB = sum(DotProductsAB,2) ; 
EvalProd = ( S.A .* [S.B ;  zeros( max(length(S.A) - length(S.B), 0), 1)] ).^2; 
DotProducts = cumsum(DotProductsAB) ./ cumsum(EvalProd); 
 
%Finds the MAs at which the Value of DotProducts changes rapidly
DP = abs(diff(DotProducts)); DP = DP/max(DP); DP = movmax(DP, [0 length(DP)]);
maxMA = find(log10(DP) < -4.5, 1, 'first'); DotProducts = DotProducts(1:maxMA);
Nq = 15; T1 = linspace(min(DotProducts), max(DotProducts), Nq); 
trunc = sum(DotProducts >= T1, 1); uTrunc = unique(trunc);
% MA(1) = find(DP < 0.01, 1, 'first');
% 
% B = size(Datas.rawdata.BData, 2);
% A = size(Datas.rawdata.AData, 2);
% parameters.data.A = A;
% parameters.data.B = B;

% minTrainingA = A - NATest;
% maxTrainingB = B - mod(B, NBTest);
% MA(2) = minTrainingA - maxTrainingB;

%if min(MA) > 37, keyboard, end

for ima = uTrunc

    parameters.snapshots.k1 = ima; %min(MA);
    D2 = methods.Multi2.ConstructResidualSubspace(D, parameters, methods); %Construct Filter
    SB = cumsum(D2.B.CovTraining.^2,1) ./ sum(D2.B.CovTraining.^2,1); 
    EVB = mean(SB,2);
    %q = quantile(EVB,20);
    q = 0.05:0.05:1;
    Mres = arrayfun( @(x) find(EVB < x, 1, 'last'), q);

    for imres = 1:length(Mres)
        parameters.multilevel.iMres = Mres(imres);
        D3 = methods.Multi2.SepFilter(D2, parameters, methods); 

        MSDTrain = CompMSD(D3.A.Machine) + CompMSD(D3.B.Machine);
        MSDTest = CompMSD([D3.A.Machine, D3.A.Testing]) + ...
            CompMSD([D3.B.Machine, D3.B.Testing]);

        relMSDChange = abs(MSDTest - MSDTrain) / MSDTrain;

        if relMSDChange < BestRelChangeMSD
            BestMA = ima;
            BestMres = Mres(imres);
            BestRelChangeMSD = relMSDChange;
        end

    end
    
    
end

parameters.snapshots.k1 = BestMA;

if parameters.multilevel.splitTraining 
    parameters.snapshots.k1 = min(BestMA, size(Datas.A.CovTraining,2));
end

parameters.multilevel.Mres = BestMres;


   
%% Get List of Mres to try


%fprintf('MA = %d, Mres = %d \n', parameters.snapshots.k1, parameters.multilevel.Mres);
end







