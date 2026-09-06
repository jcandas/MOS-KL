function Datas = SelectSVMFeatures(Datas, parameters, methods)
close all

%% Plot Parameters
Nscores = 20;
TrimThresh = 0.1;
blue = hex2rgb('#0172aa');
orange = hex2rgb('#eb8513');
LW = 2; FA = 0.1;

%% Express each sample in the Class A Eigenbasis
Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);


%% Compute the middle 95% interval for each Class A feature (empirical)
alpha = (1 - parameters.multilevel.concentration)/2;
IA = quantile(Datas.A.CovTraining, [alpha, 1 - alpha], 2);
meanA = mean(Datas.A.CovTraining,2);

%% Compute the middle 95% interval for each Class A feature (Chebyshev)
% z = 1/sqrt(1 - parameters.multilevel.concentration);
% stdevA = std(Datas.A.CovTraining,0,2); 
% IA = meanA + [-z z].*stdevA;

%% For each feature, find the proportion of Class B not within the Class A 95% interval
NB0 = Datas.B.CovTraining <= IA(:, 1) | Datas.B.CovTraining >= IA(:, 2); 
NB1 = sum(NB0,2);
propB = NB1 / size(Datas.B.CovTraining,2);

%% Find the average sign of each Class B feature
SignB = sign(Datas.B.CovTraining - meanA);
meanSignB = abs(mean(SignB, 2));

%% Compute the SVM separability score for each feature. 
SLin = propB .* meanSignB;
SRBF = propB .* (1 - meanSignB);

%% Rank each feature according to its SVM separability score
[~, RILin] = sort(SLin, 'descend'); SLinsort = SLin(RILin);
[~, RIRBF] = sort(SRBF, 'descend'); SRBFsort = SRBF(RIRBF);

%Discard features whose scores are too low (less than one-tenth the maximum
%score)

% LinTrim = SLin >= TrimThresh * max(SLin); 
% RBFTrim = SRBF >= TrimThresh * max(SRBF);
% 
% RILin = RILin(LinTrim);
% RIRBF = RIRBF(RBFTrim);

switch parameters.svm.kernal
    case true, isort = RIRBF;
    case false, isort = RILin;
end

for C = 'AB', for set = ["Machine", "Testing"]
        Datas.(C).(set) = Datas.(C).(set)(isort, :);
end, end

% T = [RILin, SLinsort, RIRBF, SRBFsort];
% T = array2table(T'); 
% T.Properties.RowNames = {'Lin_Features', 'Lin_Score', 'RBF_Features', 'RBF_Score'}; 
% disp(T);

    if false 
    %%
    fprintf('SVM Linear Separability (First 20): \n');
    fprintf('% 5d ', RILin(1:Nscores)); fprintf('\n');
    fprintf('%0.3f ', SLinsort(1:Nscores)); fprintf('\n');
    fprintf('\nSVM Radial Separability (First 20): \n');
    fprintf('% 5d ', RIRBF(1:Nscores)); fprintf('\n');
    fprintf('%0.3f ', SRBFsort(1:Nscores)); fprintf('\n');
    
    
    %% Construct a plot with interval information
    
    %Copy Interval info for Class B
    %IB = quantile(Datas.B.CovTraining, [alpha, 1 - alpha], 2);
    stdevB = std(Datas.B.CovTraining,0,2);
    meanB = mean(Datas.B.CovTraining,2);
    IB = meanB + [-z z].*stdevB;
    %IA = flipud(IA); IB = flipud(IB);
    
    %Create patch coordinates for Class A
    X0 = 1:parameters.data.numofgene;
    XA = [X0, fliplr(X0)];
    YA = [IA(:,1)' fliplr(IA(:,2)')];
    
    %Create patch coordinates for Class B
    YB = [IB(:,1)' fliplr(IB(:,2)')];
    
    figure(); axes(); hold on
    %plot 95 CIs
    patch(XA, YB, orange, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    patch(XA, YA, blue, 'FaceAlpha', 0.6, 'EdgeColor', 'none');
    
    
    %plot means
    plot(X0, meanA, 'Color', blue, 'LineWidth', LW);
    plot(X0, meanB, 'Color', orange, 'LineWidth', LW);
    end

end