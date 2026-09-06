function plotSemisyntheticBaselines
close all

%% Define Iterators
Accs = ["AUC", "accuracy"];
[DS, DS2] = DefineDatasets;
t0 = 5*10.^[-3,-2,-1];
transforms = arrayfun(@(x) replace(sprintf("Noise_%0.g", x),'.', '_'),t0);
transforms = ["id", transforms];
transforms2 = ["0", arrayfun(@(x) sprintf("%0.0e",x), t0)];
LineSpecs = DefineLineSpecs;

folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', 'Graphs');
if ~isfolder(folder), mkdir(folder); end


for acc = Accs
    f(Accs == acc) = figure('Name', acc, 'Units', 'Normalized', ...
        'Position', [0.1, 0.1 + 0.1*(acc == "AUC"), 1.7, 0.4]);

for iDS = 1:length(DS)
    ds = DS(iDS); ds2 = DS2(iDS);
    X = GetFiles(ds, transforms);
    LineData = GetLineData(X, acc);
    ax(iDS) = subplot(2,4,iDS); FixAxes(ax(iDS), acc, transforms2);
    title(ds2, 'FontSize', 14, 'Interpreter', 'latex');
    for iL = 1:size(LineData,1)
        plot(LineData(iL,:), LineSpecs{iL,:});
    end
end

l = AddLegend(X(1).parameters.misc.MachineList);
 
name = "Synthetic_Baseline_" + acc + ".pdf";
exportgraphics(gcf, fullfile(folder, name));

end

end
%==========================================================================

%==========================================================================
function [DS, DS2] = DefineDatasets


A = ["AD", "AD", "CN"]; B = ["CN", "LMCI", "LMCI"];
DS(1:2) = ["GCM", "newAD"]; DS2 = DS(1:2);

DS(3:5) = "Plasma_M12_" + A + B;
DS2(3:5) = "ADNI (" + A + " vs. " + B + ")";

DS(6:8) = "SOMAscan7k_KNNimputed_" + A + "_" + B;
DS2(6:8) = replace(DS2(3:5), "ADNI", "CSF");
end
%==========================================================================

%==========================================================================
function LineSpecs = DefineLineSpecs

gold = [0.85, 0.67, 0.2]; 
violet = [0.5, 0.1, 0.8]; 
white = [1, 1, 1];

t0 = [0.3;0.7];
t1 = [0.4;0.8];
t2 = [0.4;0.7;1];

Colors = [t1 .* violet ; t0 .* white + (1-t0) .* violet; t2 .* gold];
Colors = arrayfun(@(i) Colors(i,:), [1:size(Colors,1)]', 'UniformOutput', false );

Markers = {'s','s','^','^','o','s','^'}'; 
LineStyles = {'-', '--', '-', '--', '-', '-', '--'}';
LineWidths = repmat({2}, size(LineStyles));

LineArgs = [Markers, Colors, LineWidths, LineStyles];

LineNames = {'Marker', 'Color', 'LineWidth', 'LineStyle'};
LineSpecs = cell(length(Markers), length(LineNames)*2);

LineSpecs(:,1:2:end) = repmat(LineNames, size(Markers));
LineSpecs(:,2:2:end) = LineArgs;
end
%==========================================================================

%==========================================================================
function X = GetFiles(DS,transforms)

ClassSize = sprintf('%d_TrainingA_%d_TrainingB_%d_Testing', 600, 200, 10000);

X = [];
for Noise = transforms
folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', DS, ClassSize, Noise,'Unbalanced');
files = dir(fullfile(folder, '*.mat'));
isBench = contains({files.name}, 'Benchmark'); Bench = files(isBench);
f = load(fullfile(Bench.folder, Bench.name));
X = [X, f];
end

end
%==========================================================================

%==========================================================================
function LineData = GetLineData(X, acc)
results = [X.results];
LineData = vertcat(results.(acc));
LineData = LineData';
end
%==========================================================================

%==========================================================================
function FixAxes(ax, acc, noise)
capitalize = @(str) upper(extractBefore(str,2)) + extractAfter(str,1);
hold on 
grid on
ax.Position(1) = ax.Position(1) - 0.075;

ax.XTickLabel = "";

if ax.Position(2) >= 0.58
    ax.Position(2) = ax.Position(2) + 0.02;
elseif ax.Position(2) <= 0.12 & acc == "accuracy"
    xlabel('Noise', 'FontSize',13, 'Interpreter', 'latex');
    ax.XTickLabel = replace(noise, "id", "0");

end
ax.FontSize = 13;
if ax.Position(1) <= 0.08
    ylabel(capitalize(acc), 'FontSize',12, 'Interpreter', 'latex');
end
end
%==========================================================================

%==========================================================================
function l = AddLegend(str)

old = ["Linear","Radial", "_"];
new = ["Lin","RBF", "-"];
str = replace(str, old, new);

l = legend(str,'Interpreter', 'latex', 'FontSize', 12);
l.Position = [0.85, 0.20, 0.12, 0.6];
end