function parameters = MethodOfEllipsoids_4(Datas, parameters, methods)
%Finds the number of Class A points lying inside the 0.95-Ellipsoid
%determined by Class B plut the number of Class B points lying inside the
%0.95-Ellipsoid determined by Class A;

close all
if ~parameters.multilevel.chooseTrunc, return, end

%% Copy over Training Portion of Data and eliminate testing data
for C = 'AB', D.(C).rawdata = Datas.(C).Training; end
for Set = ["CovTraining", "Machine", "Testing"], D.B.(Set) = D.B.rawdata; end


BestMA = []; BestMres = []; BestMisplaced = Inf;

%% Separate Testing Cohort from Class A and Class B Training
for C = 'AB'
D.(C).CovTraining = D.(C).rawdata;
D.(C).CovTraining(:,end) = [];
D.(C).Machine = D.(C).CovTraining;
NC = size(D.(C).CovTraining,2);
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
MA(1) = find(DP < 0.01, 1, 'first');

B = size(Datas.rawdata.BData, 2);
A = size(Datas.rawdata.AData, 2);
parameters.data.A = A;
parameters.data.B = B;
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
minTrainingA = A - NATest;
maxTrainingB = B - mod(B, NBTest);
MA(2) = minTrainingA - maxTrainingB;

%if min(MA) > 37, keyboard, end

parameters.snapshots.k1 = min(MA);
if parameters.multilevel.splitTraining 
    parameters.snapshots.k1 = min(BestMA, size(Datas.A.CovTraining,2));
end

D2 = methods.Multi2.ConstructResidualSubspace(D, parameters, methods); %Construct Filter
   
%% Get List of Mres to try
SB = cumsum(D2.B.CovTraining.^2,1) ./ sum(D2.B.CovTraining.^2,1); 
EVB = mean(SB,2);
parameters.multilevel.Mres = sum(EVB <= 0.5);

%fprintf('MA = %d, Mres = %d \n', parameters.snapshots.k1, parameters.multilevel.Mres);
end







