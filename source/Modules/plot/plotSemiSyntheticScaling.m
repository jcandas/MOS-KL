function plotSemiSyntheticScaling(csvfile, outdir)
% plotSemiSyntheticScaling  Sample-size scaling curves for the semisynthetic GCM
% experiment. One figure per sin transformation (15/18/20); each figure has two
% subplots -- Accuracy (left) and Precision (right) vs. the number of generated
% Tumor training samples (log x-axis). Each subplot draws six curves: SVM / MLP /
% ResNet-3, each in the MLS representation (solid) and on the original features
% (dashed).
%
%   plotSemiSyntheticScaling   % uses paper_tables/acc_semisyn.csv, writes to results/figures
%
% Data comes from acc_semisyn.csv (produced by summ_semisyn.m), which reports, for
% each (sin, size, model), the accuracy-maximising MLS level and the matching
% original-feature benchmark.

root = getenv('PNAS_ROOT');
if nargin < 1 || isempty(csvfile)
    csvfile = fullfile(root, 'results', 'acc_semisyn.csv');
end
if nargin < 2 || isempty(outdir)
    outdir = fullfile(root, 'results', 'figures');
end
if ~isfolder(outdir), mkdir(outdir); end

T = readtable(csvfile, 'TextType','string');
sample_sizes = [150 450 1500 10000];
sins = [15 18 20];

models = ["SVM","MLP","ResNet-3"];
colors = { [0 114 178]/255, [230 159 0]/255, [0 158 115]/255 };   % Okabe-Ito: blue, orange, green
reps   = [1 0];                    % 1 = MLS (solid), 0 = Original (dashed)
styles = {'-','--'};
repname = {"Orig","MLS"};          % index by rep+1

    function v = series(sinv, model, mls, metric)
        v = nan(1, numel(sample_sizes));
        for zi = 1:numel(sample_sizes)
            row = T(T.Sin==sinv & T.Size==sample_sizes(zi) & ...
                    T.Model==model & T.WithMLS==mls, :);
            if ~isempty(row), v(zi) = row.(metric)(1); end
        end
    end

    function drawPanel(sinv, metric, ylab)
        hold on;
        for mi = 1:numel(models)
            for ri = 1:numel(reps)
                y = series(sinv, models(mi), reps(ri), metric);
                plot(sample_sizes, y, [styles{ri} 'o'], ...
                    'Color', colors{mi}, 'LineWidth', 2, 'MarkerSize', 5, ...
                    'MarkerEdgeColor', colors{mi}, 'MarkerFaceColor', [1 1 1], ...
                    'DisplayName', sprintf('%s (%s)', models(mi), repname{reps(ri)+1}));
            end
        end
        ylim([0.45 1]); axis square; grid on;
        set(gca, 'XScale','log', 'Box','off', 'TickDir','out', ...
            'TickLength',[.025 .025], 'XMinorTick','on', 'YMinorTick','on', ...
            'XGrid','off', 'YGrid','on', 'XColor',[.3 .3 .3], 'YColor',[.3 .3 .3], ...
            'YTick',0.45:0.05:1, 'LineWidth',1, 'FontSize',11);
        xlim([min(sample_sizes)*0.8, max(sample_sizes)*1.25]);
        set(gca, 'XTick', sample_sizes, 'XTickLabel', compose('%d', sample_sizes));
        xlabel('Tumor training samples', 'Interpreter','latex', 'FontSize',16);
        ylabel(ylab, 'Interpreter','latex', 'FontSize',16);
    end

for s = sins
    fig = figure('Position',[100 100 1200 500], 'Color','white');
    subplot(1,2,1); drawPanel(s, 'Accuracy', 'Overall Accuracy');
    legend('Location','northwest', 'Interpreter','latex', 'FontSize',12, 'Box','off');
    subplot(1,2,2); drawPanel(s, 'Precision', 'Precision');

    fn = fullfile(outdir, sprintf('semisyn_sin%d_scaling', s));
    exportgraphics(fig, [fn '.pdf'], 'ContentType','vector');
    exportgraphics(fig, [fn '.png'], 'Resolution',180);
    fprintf('saved %s.pdf\n', fn);
    close(fig);
end
end
