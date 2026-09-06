function MakeHistSqNorm
close all
methods = DefineMethods;

PrincColor = 1/256*[172 17 20]; 
t = 0.25;
fontsize = 16;
TailColor = 1/256*[64 28 255];
dim = [0.7 0.8 0.2 0.1]; %dimensions for textbox

%% Load In Data
Datasets = ["Plasma_M12_ADCN","Plasma_M12_ADLMCI", "Plasma_M12_CNLMCI",...
            "SOMAscan7k_KNNimputed_AD_CN", "SOMAscan7k_KNNimputed_CN_EMCI",...
            "newAD", "GCM"];
Aliases = ["ADNI (AD vs. CN)", "ADNI (AD vs. LMCI)", "ADNI (CN vs. LMCI)",...
           "CSF (AD vs. CN)", "CSF (CN vs. EMCI)",...
           "newAD", "GCM"];


Evals = cell(size(Datasets));
UEV = cell(size(Datasets));
MAs = nan(size(Datasets));

%% Place subplots in the right place
for j = 1:1
f(j) = figure('Units', 'normalized', 'OuterPosition', [0, 0.10, 1, 0.95]);
for iD = 1:7
    subplot(2,4,iD)
    p = get(gca, 'Position');
    p(4) = 0.7*p(4);
    set(gca, 'Position', p);
    hold on %text(0.5, 0.5, num2str(i));
end
f(j).Children = flipud(f(j).Children);
DistBetweenPlots = f(j).Children(2).Position(1) - (f(j).Children(1).Position(3) + f(j).Children(1).Position(1));
PlotWidth = f(j).Children(1).Position(3); %- f(j).Children(1).Position(1);
CurrentMargin = f(j).Children(1).Position(1);
NewMargin = 0.5 * (1 - 3*PlotWidth - 2*DistBetweenPlots);
MarginDiff = NewMargin - CurrentMargin;
for iD = 5:7
    CurrentLeft = f(j).Children(iD).Position(1); %Get current position of bottom left corner
    NewLeft = CurrentLeft + MarginDiff;
    f(j).Children(iD).Position(1) = NewLeft;
end
end

%% Transform Data
for iD = 1:length(Datasets)
    resultsFolder = fullfile('..','results', 'Manual_Hyperparameter_Selection',...
              'Kfold', Datasets(iD), 'Leave_1_out', 'Unbalanced');
    F = dir(resultsFolder);
    F(matches({F.name}, [".", ".."])) = [];
    load(fullfile(F(1).folder, F(1).name));

    %% Prep Data
    T = Datas.rawdata.T; %[Datas, parameters] = methods.all.readcancerData(parameters, methods);
    AData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeA)));
    BData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeB)));
    Datas.rawdata.AData = AData; Datas.rawdata.BData = BData;
    parameters.data.i = 1; parameters.data.j = 1; 
    parameters.gpuarray.on = false; parameters.data.randomize = false;
    Datas = methods.all.prepdata(Datas, parameters);
    Datas = methods.Multi2.ConstructResidualSubspace(Datas, parameters, methods);
    parameters.multilevel.iMres = parameters.multilevel.Mres(end);
    Datas = methods.Multi2.SepFilter(Datas, parameters, methods);

    %% Plot Data
    xlabArgs = {'$\|P_\mathcal S v^\mathbf A\|_{\mathcal H}^2$'}; 
    AData = sum(Datas.A.CovTraining.^2,2);
    q80 = quantile(AData, 0.8); AData = AData(AData <= q80);
    %BData = sum(Datas.B.CovTraining.^2,2);
    histogram(f.Children(iD), AData, 'FaceColor', PrincColor,...
        'FaceAlpha', 0.7, 'Normalization', 'probability');
    %histogram(f.Children(iD), BData, 'FaceColor', TailColor, 'FaceAlpha', 0.7);
    title(f.Children(iD), Aliases(iD), 'FontSize', fontsize);

    f.Children(iD).YGrid = 'on';
    f.Children(iD).FontSize = fontsize;

    %if ismember(iD, [1,5])
    xlabel(f(j).Children(iD), xlabArgs{:}, 'Interpreter', 'latex', 'FontSize', fontsize);
    %end

    % Add the annotation textbox
    str = sprintf('$M_\\mathbf A = %d$', parameters.snapshots.k1);
    xL = f.Children(iD).XLim(2); 
    yL = f.Children(iD).YLim(2); 
    text(f.Children(iD), ...
    0.95 * xL, 0.5 * yL, ... 
    str, ...
    'HorizontalAlignment', 'right',...
    'VerticalAlignment', 'top',...
    'FontSize', fontsize,...
    'Interpreter', 'latex');

    
end
resultsDir = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
filename = 'Class_A_Histograms';
exportgraphics(f, fullfile(resultsDir, [filename '.pdf']))
    close(f);



% %% Plot the singular values
% 
% for j = 1:2
% for iD = 1:7
% 
%     switch j
%          case 1
%              S = Evals{iD}; 
%              xlab = '$r$';
%              ylabArgs = {'$\widehat{\lambda_r^\mathbf A}$'}; 
%              filename = 'Scree_Plots';
%              yscale = 'linear';
%          case 2
%              S = UEV{iD}; 
%              xlab = 'Truncation';
%              ylabArgs = {["Unexplained","Variance"]}; 
%              filename = 'Unexplained_Variance';
%              yscale = 'linear';
%      end
% 
%     %S = Evals{i}; 
%     MA = MAs(iD);
%     stem(f(j).Children(iD), 1:MA, S(1:MA), 'Color', PrincColor);
%     stem(f(j).Children(iD), MA+1:length(S), S(MA+1:end), 'Color', TailColor);
% 
% 
%     xlabel(f(j).Children(iD), xlab, 'Interpreter', 'latex', 'FontSize', fontsize);
%     lxt = length(f(j).Children(iD).XTickLabel);
%     xtinc = ceil(lxt / 4);
%     ixt = 1:lxt; ixt(xtinc:xtinc:end) = [];
%     %nxt = cxt(xtinc:xtinc:end);
%     f(j).Children(iD).XTickLabel(ixt) = {''};
%     %if i == 2, keyboard, end
% 
% 
% 
% 
%     f(j).Children(iD).YScale = yscale; %set(gca, 'YScale', 'log')
% 
% 
% end
% %if j == 2, keyboard, end
% exportgraphics(f(j), fullfile(resultsDir, [filename '.pdf']))
% close(f(j));
% end
% 
% end