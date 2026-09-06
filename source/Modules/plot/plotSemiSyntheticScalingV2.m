function plotSemiSyntheticScalingV2(svmCsv, restCsv, outdir)
% plotSemiSyntheticScalingV2  Sample-size scaling curves (v2, 5 sizes) for the
% semisynthetic GCM experiment. One figure per sin (15/18/20); each has two
% subplots -- Accuracy (left) and Precision (right) vs. the number of generated
% Tumor training samples (log x-axis). Six curves: SVM / MLP / ResNet-3, each in
% the MLS representation (solid) and on the original features (dashed). The SVM
% curves come from the RADIAL run; MLP/ResNet-3 (kernel-independent) from the
% linear per-sample v2 run. A dotted horizontal line marks the best ensemble
% baseline (the RF/GB/RUS model with the highest mean accuracy), drawn at its mean
% value across the five sizes.
%
%   plotSemiSyntheticScalingV2   % defaults: radial SVM + v2 rest -> results/figures

root = getenv('PNAS_ROOT');
if nargin < 1 || isempty(svmCsv)
    svmCsv = fullfile(root, 'results', 'acc_semisyn_v2_radial.csv');
end
if nargin < 2 || isempty(restCsv)
    restCsv = fullfile(root, 'results', 'acc_semisyn_v2.csv');
end
if nargin < 3 || isempty(outdir)
    outdir = fullfile(root, 'results', 'figures');
end
if ~isfolder(outdir), mkdir(outdir); end

Tsvm  = readtable(svmCsv,  'TextType','string');   % SVM (radial)
Trest = readtable(restCsv, 'TextType','string');   % MLP/ResNet/baselines (v2)

sample_sizes = [150 450 1500 10000 50000];
sins = [15 18 20];
models  = ["SVM","MLP","ResNet-3"];
srcSVM  = [true false false];                      % which model comes from Tsvm
colors  = { [0 114 178]/255, [230 159 0]/255, [0 158 115]/255 };  % Okabe-Ito
reps    = [1 0];                                   % 1 = MLS (solid), 0 = Orig (dashed)
styles  = {'-','--'};
repname = {"Orig","MOS-KL"};                        % index by rep+1
bases   = ["Random Forest","Gradient Boosting","RUS Boost"];

for s = sins
    fig = figure('Position',[100 100 1200 500], 'Color','white');
    for sp = 1:2
        if sp==1, metric = 'Accuracy'; ylab = 'Overall Accuracy';
        else,     metric = 'Precision'; ylab = 'Precision'; end
        subplot(1,2,sp); hold on;

        % ---- best baseline (by mean accuracy across sizes), horizontal dotted line ----
        bestMeanAcc = -inf; bestBase = bases(1);
        for b = bases
            accv = baseSeries(Trest, s, b, 'Accuracy', sample_sizes);
            if mean(accv,'omitnan') > bestMeanAcc, bestMeanAcc = mean(accv,'omitnan'); bestBase = b; end
        end
        hval = mean(baseSeries(Trest, s, bestBase, metric, sample_sizes), 'omitnan');
        yline(hval, ':', 'Color',[0.35 0.35 0.35], 'LineWidth',2, ...
            'HandleVisibility','off');

        % ---- model curves ----
        for mi = 1:numel(models)
            T = Tsvm; if ~srcSVM(mi), T = Trest; end
            for ri = 1:numel(reps)
                y = modelSeries(T, s, models(mi), reps(ri), metric, sample_sizes);
                plot(sample_sizes, y, [styles{ri} 'o'], ...
                    'Color', colors{mi}, 'LineWidth', 2, 'MarkerSize', 5, ...
                    'MarkerEdgeColor', colors{mi}, 'MarkerFaceColor', [1 1 1], ...
                    'DisplayName', sprintf('%s (%s)', models(mi), repname{reps(ri)+1}));
            end
        end
        % proxy for the baseline legend entry
        plot(nan, nan, ':', 'Color',[0.35 0.35 0.35], 'LineWidth',2, ...
            'DisplayName', sprintf('best baseline (%s)', shortBase(bestBase)));

        ylim([0.45 1]); axis square; grid on;
        set(gca, 'XScale','log', 'Box','off', 'TickDir','out', ...
            'TickLength',[.025 .025], 'XMinorTick','on', 'YMinorTick','on', ...
            'XGrid','off', 'YGrid','on', 'XColor',[.3 .3 .3], 'YColor',[.3 .3 .3], ...
            'YTick',0.45:0.05:1, 'LineWidth',1, 'FontSize',11);
        xlim([min(sample_sizes)*0.8, max(sample_sizes)*1.3]);
        set(gca, 'XTick', sample_sizes, 'XTickLabel', compose('%d', sample_sizes));
        xtickangle(30);
        xlabel('Tumor training samples', 'Interpreter','latex', 'FontSize',16);
        ylabel(ylab, 'Interpreter','latex', 'FontSize',16);
        if sp==1
            legend('Location','southwest', 'Interpreter','latex', 'FontSize',10, 'Box','off');
        end
    end
    fn = fullfile(outdir, sprintf('semisyn_v2_sin%d_scaling', s));
    exportgraphics(fig, [fn '.pdf'], 'ContentType','vector');
    exportgraphics(fig, [fn '.png'], 'Resolution',180);
    fprintf('saved %s.pdf\n', fn);
    close(fig);
end
end

% ------------------------------------------------------------------
function v = modelSeries(T, sinv, model, mls, metric, sizes)
v = nan(1, numel(sizes));
for zi = 1:numel(sizes)
    row = T(T.Sin==sinv & T.Size==sizes(zi) & T.Model==model & T.WithMLS==mls, :);
    if ~isempty(row), v(zi) = row.(metric)(1); end
end
end

function v = baseSeries(T, sinv, model, metric, sizes)
v = nan(1, numel(sizes));
for zi = 1:numel(sizes)
    row = T(T.Sin==sinv & T.Size==sizes(zi) & T.Model==model & T.WithMLS==0, :);
    if ~isempty(row), v(zi) = row.(metric)(1); end
end
end

function s = shortBase(name)
switch name
    case "Random Forest",     s = "RF";
    case "Gradient Boosting", s = "GB";
    case "RUS Boost",         s = "RUS";
    otherwise,                s = name;
end
end
