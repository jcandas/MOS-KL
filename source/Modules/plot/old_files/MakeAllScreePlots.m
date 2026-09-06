function MakeAllScreePlots
close all

PrincColor = 1/256*[172 17 20]; 
t = 0.25;
fontsize = 16;
TailColor = t*PrincColor + (1-t)*[1 1 1];
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

%% Get Class A Singular Values
for i = 1:length(Datasets)
    resultsFolder = fullfile('..','results', 'Manual_Hyperparameter_Selection',...
              'Kfold', Datasets(i), 'Leave_1_out', 'Unbalanced');
    F = dir(resultsFolder);
    F(matches({F.name}, [".", ".."])) = [];
    load(fullfile(F(1).folder, F(1).name));
    T = Datas.rawdata.T;
    AData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeA)));
    AData = AData - mean(AData,2);
    [~,S,~] = svd(AData, 'vector', 'econ');
    Evals{i} = S.^2;
    UEV{i} = 1 - cumsum(S.^2) ./ sum(S.^2);
    MAs(i) = parameters.snapshots.k1;
end

%% Place subplots in the right place
for j = 1:2
f(j) = figure('Units', 'normalized', 'OuterPosition', [0, 0.10, 1, 0.95]);
for i = 1:7
    subplot(2,4,i)
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
for i = 5:7
    CurrentLeft = f(j).Children(i).Position(1); %Get current position of bottom left corner
    NewLeft = CurrentLeft + MarginDiff;
    f(j).Children(i).Position(1) = NewLeft;
end
end

%% Plot the singular values
resultsDir = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
for j = 1:2
for i = 1:7

    switch j
         case 1
             S = Evals{i}; 
             xlab = '$r$';
             ylabArgs = {'$\widehat{\lambda_r^\mathbf A}$'}; 
             filename = 'Scree_Plots';
             yscale = 'linear';
         case 2
             S = UEV{i}; 
             xlab = 'Truncation';
             ylabArgs = {["Unexplained","Variance"]}; 
             filename = 'Unexplained_Variance';
             yscale = 'linear';
     end
   
    %S = Evals{i}; 
    MA = MAs(i);
    stem(f(j).Children(i), 1:MA, S(1:MA), 'Color', PrincColor);
    stem(f(j).Children(i), MA+1:length(S), S(MA+1:end), 'Color', TailColor);
    title(f(j).Children(i), Aliases(i), 'FontSize', fontsize)

    xlabel(f(j).Children(i), xlab, 'Interpreter', 'latex', 'FontSize', fontsize);
    lxt = length(f(j).Children(i).XTickLabel);
    xtinc = ceil(lxt / 4);
    ixt = 1:lxt; ixt(xtinc:xtinc:end) = [];
    %nxt = cxt(xtinc:xtinc:end);
    f(j).Children(i).XTickLabel(ixt) = {''};
    %if i == 2, keyboard, end



    if ismember(i, [1,5])
    ylabel(f(j).Children(i), ylabArgs{:}, 'Interpreter', 'latex', 'FontSize', fontsize);
    end
    f(j).Children(i).YScale = yscale; %set(gca, 'YScale', 'log')
    f(j).Children(i).YGrid = 'on';
    f(j).Children(i).FontSize = fontsize;

    

    % Add the annotation textbox
    str = sprintf('$M_\\mathbf A = %d$', MA);
    xL = f(j).Children(i).XLim(2); 
    yL = f(j).Children(i).YLim(2); 
    text(f(j).Children(i), ...
    0.95 * xL, 0.5 * yL, ... 
    str, ...
    'HorizontalAlignment', 'right',...
    'VerticalAlignment', 'top',...
    'FontSize', fontsize,...
    'Interpreter', 'latex');

end
%if j == 2, keyboard, end
exportgraphics(f(j), fullfile(resultsDir, [filename '.pdf']))
close(f(j));
end

end