function ScreePlots

close all

%==========================================================================
colors = [hex2rgb('#0172aa');  %blue
          hex2rgb('#eb8513')]; %orange
figPos = [0.1, 0.1, 0.3, 0.3];
LW = 3;
mk = 'o';
NTerms = 15;

tFS = 17;
aFS = 15;
lFS = 13;
%==========================================================================

methods = DefineMethods;
parameters = InitializeParameters3();
parameters = methods.data.GetCommonParameters(parameters, methods);
[Datas, parameters] = methods.all.readcancerData(parameters, methods);   


%==========================================================================
figure('Units', 'normalized', 'Position', figPos);
ax = axes; hold on

for C = ["A", "B"]
    X = Datas.rawdata.(C + "Data");
    N = size(X,2); m = mean(X,2); Z = (N-1)^(-0.5)*(X - m);
    [~,S,~] = svd(Z, 'econ', 'vector');
    EV = 1 - cumsum(S.^2) / sum(S.^2); EV = EV(1:NTerms);
    plot(EV, ...
        'LineWidth', LW, ...
        'Color', colors(["A", "B"] == C, :), ...
        'Marker', mk);
end

xlabel('Truncation', 'Interpreter', 'latex');
ylabel('Tail Sum', 'Interpreter', 'latex');
title('Normalized Eigenvalue Tail Sum', 'Interpreter', 'latex', 'FontSize', tFS);
for a = ["X", "Y"]
    ax.(a + "Axis").FontSize = aFS-2;
    ax.(a + "Label").FontSize = aFS; 
end
legend(["A", "B"], 'Interpreter', 'latex', 'FontSize', lFS);
ax.YGrid = 'on';
ax.YScale = 'log';

folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Graphs');
name = 'Eigenvalue_Tail_Sum.pdf';

exportgraphics(gcf, fullfile(folder, name));

end