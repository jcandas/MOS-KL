function MakeAllScreePlots
close all

PrincColor = 1/256*[172 17 20]; 
t = 0.25;
fontsize = 16;
TailColor = 0.875*[1 1 1]; %t*PrincColor + (1-t)*[1 1 1];
dim = [0.7 0.8 0.2 0.1]; %dimensions for textbox

%% Load In Data
Datasets = ["Plasma_M12_ADCN","Plasma_M12_ADLMCI", "Plasma_M12_CNLMCI",...
            "SOMAscan7k_KNNimputed_AD_CN", "SOMAscan7k_KNNimputed_CN_EMCI",...
            "newAD", "GCM"];
Aliases = ["ADNI (AD vs. CN)", "ADNI (AD vs. LMCI)", "ADNI (CN vs. LMCI)",...
           "CSF (AD vs. CN)", "CSF (CN vs. EMCI)",...
           "newAD", "GCM"];


cm = cell(size(Datasets));

%% Get Class A Singular Values
for i = 1:length(Datasets)
    resultsFolder = fullfile('..','results', 'Manual_Hyperparameter_Selection',...
              'Kfold', Datasets(i), 'Leave_1_out', 'Unbalanced');
    F = dir(resultsFolder);
    F(matches({F.name}, [".", ".."])) = [];
    load(fullfile(F(1).folder, F(1).name));
    T = Datas.rawdata.T;
    AData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeA)));
    BData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeB)));
    AData = (size(AData,2)-1)^(-0.5) * (AData - mean(AData,2));
    BData = (size(BData,2)-1)^(-0.5) * (BData - mean(BData,2));
    [UA,SA,~] = svd(AData, 'vector', 'econ');
    [UB,SB,~] = svd(BData, 'vector', 'econ');
        
    DotProductsAB = ((UA .* SA')' * (UB .* SB')).^2; %DotProductsDenom = (SB.^2) * (SA(:).^2);
    DotProductsAB = sum(DotProductsAB,2) ; 
    EvalProd = ( SA .* [SB ;  zeros( max(length(SA) - length(SB), 0), 1)] ).^2; 
    DotProducts = cumsum(DotProductsAB) ./ cumsum(EvalProd); 

    cm{i} = DotProducts;
end

%% Place subplots in the right place
for j = 1
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
for j = 1
for i = 1:7

    
        
              
             xlab = '$M$';
             ylabArgs = {'$c_M$'}; 
             filename = 'Admissible Truncations';
             yscale = 'log';
 
   
    DotProducts = cm{i}(1:41);
    DP = abs(diff(DotProducts)); DP = DP/max(DP); DP = movmax(DP, [0 length(DP)]);
    MA = find(DP < 0.01, 1, 'first');
    DP2 = DP(1:MA);
    %if i == 5, keyboard, end
    %stem(f(j).Children(i), DP, 'Color', PrincColor);
    % stem(f(j).Children(i), 1:MA, DP(1:MA), 'Color', PrincColor);
    p = 0:0.2:1;
    q = [0 quantile(DP2, p(2:end))];
    C = lines(length(q)-1);
    for k = 2:length(q)
        iDP = DP2 >= q(k-1) & DP2 < q(k);
        y = DP2(DP2 >= q(k-1) & DP2 < q(k));
        x = find(iDP);
        stem(f(j).Children(i),x,y,'Color', C(k-1,:));
    end

    stem(f(j).Children(i), MA+1:40, DP(MA+1:40), 'Color', TailColor);
    

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
    % str = sprintf('$M_\\mathbf A = %d$', MA);
    % xL = f(j).Children(i).XLim(2); 
    % yL = f(j).Children(i).YLim(2); 
    % text(f(j).Children(i), ...
    % 0.95 * xL, 0.5 * yL, ... 
    % str, ...
    % 'HorizontalAlignment', 'right',...
    % 'VerticalAlignment', 'top',...
    % 'FontSize', fontsize,...
    % 'Interpreter', 'latex');

end
%if j == 2, keyboard, end
exportgraphics(f(j), fullfile(resultsDir, [filename '.pdf']))
close(f(j));
end

end