function parameters = MethodOfEllipsoids_2(Datas, parameters, methods)
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
maxMA = find(DP < 0.01, 1, 'first');
DP2 = DP(1:maxMA);
p = 0:0.2:1;
%q = quantile(DP2, p(2:end));
if length(DP2) <= 5
    MAs = 1:maxMA;
else
    MAs = arrayfun(@(x) sum(DP2 <= x), p);
    MAs = unique(MAs);
end

MAs(MAs == 0) = [];

for iMA = 1:length(MAs)
    MA = MAs(iMA);
    parameters.snapshots.k1 = MA;

    D2 = methods.Multi2.ConstructResidualSubspace(D, parameters, methods); %Construct Filter
   
    %% Get List of Mres to try
    SB = cumsum(D2.B.CovTraining.^2,1) ./ sum(D2.B.CovTraining.^2,1); 
    EVB = mean(SB,2);
    p = 0.2:0.2:1;
    Mress = [1 arrayfun(@(x) sum(EVB <= x), p)];
    Mress = unique(Mress);

    figure(), axes, hold on, C = lines(length(Mress));
    for iMres = 2:length(Mress)
        Mres = Mress(iMres);
        
        x = Mress(iMres-1):Mress(iMres);
        y = EVB(x);
        stem(x(:)',y(:)','Color', C(iMres,:));
        

        parameters2 = parameters;
        parameters2.multilevel.iMres = Mres;
        D3 = methods.Multi2.SepFilter(D2, parameters2, methods);
        wrong = methods.Ellipsoids.IdentifyMisplaced(D3, parameters2);
        
        if wrong < BestMisplaced
            BestMA = MA; 
            BestMisplaced = wrong;
            if wrong <= BestMisplaced
                BestMres = Mres;
            end
        end


    end
    close(gcf)




 end


parameters.snapshots.k1 = MA; parameters.multilevel.Mres = Mres;




