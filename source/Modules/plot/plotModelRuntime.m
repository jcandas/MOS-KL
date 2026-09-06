function plotModelRuntime(family, bare)
% plotModelRuntime  Per-model fit+predict runtime charts for one dataset family,
% from the CSV written by MeasureModelTime. Produces ONE figure per task (label)
% in the family -- e.g. ADNI yields AD vs CN / AD vs LMCI / CN vs LMCI -- plus a
% pooled family-average figure. Within each figure the MOS-KL and original bars
% for SVM/MLP/ResNet-3/ResNet-30 sit side by side (light blue = MOS-KL, light gray
% = original features); the three ensemble baselines (RF/GB/RUS) follow a divider.
% Log y-axis with plain decimal ticks.
%
%   plotModelRuntime('ADNI')          % full figure (legend + y-axis label)
%   plotModelRuntime('CSF', true)     % "bare": no legend, no y-axis label, for a
%                                     %   row of panels sharing the first's legend
if nargin < 2 || isempty(bare), bare = false; end

family = string(family);
root = getenv('PNAS_ROOT');
csv = char(fullfile(root, 'results', "model_runtime_" + family + ".csv"));
R = readtable(csv, 'TextType','string');

outdir = fullfile(root, 'results', 'figures');
if ~isfolder(outdir), mkdir(outdir); end

tasks = unique(R.Task, 'stable');
for t = 1:numel(tasks)
    tk = tasks(t);
    sub = R(R.Task==tk, :);
    if tk == "ALL"
        base = char(family + "_runtime");        % family-average (back-compat name)
        ttl  = '';                                % no title on the pooled view
    else
        [code, pretty] = taskName(tk);
        base = char(family + "_" + code + "_runtime");
        ttl  = pretty;
    end
    drawOne(sub, fullfile(outdir, base), ttl, bare);
end
end

% ======================================================================
function drawOne(R, fnbase, ttl, bare)
% R: rows for a single task (11 rows). fnbase: output path w/o extension.
models = ["SVM","MLP","ResNet-3","ResNet-30"];
mlsT = nan(1,4); mlsS = nan(1,4); orT = nan(1,4); orS = nan(1,4);
for i = 1:4
    a = R(R.Rep=="MLS"  & R.Model==models(i), :);
    if ~isempty(a), mlsT(i)=a.TimeSec(1); mlsS(i)=a.TimeStd(1); end
    b = R(R.Rep=="Orig" & R.Model==models(i), :);
    if ~isempty(b), orT(i)=b.TimeSec(1);  orS(i)=b.TimeStd(1);  end
end
bases = ["Random Forest","Gradient Boosting","RUS Boost"];
bT = nan(1,3); bS = nan(1,3);
for i = 1:3
    c = R(R.Rep=="Orig" & R.Model==bases(i), :);
    if ~isempty(c), bT(i)=c.TimeSec(1); bS(i)=c.TimeStd(1); end
end

blue = [0.42 0.64 0.86];        % MLS
gray = [0.62 0.63 0.66];        % original features
alph = 0.55; bw = 0.56; off = 0.36;
gc = [1.0 2.7 4.4 6.1];         % NN group centers
xM = gc - off; xO = gc + off;   % MLS / Orig within each group
xB = [8.0 9.2 10.4];            % baselines

fig = figure('Position',[100 100 1560 860],'Color','w'); hold on; box off;
xline(7.05, '-', 'Color',[0.85 0.85 0.85], 'LineWidth',1.4, 'HandleVisibility','off');

edgeB = blue*0.72; edgeG = gray*0.72;
for i = 1:4
    bar(xM(i), mlsT(i), bw, 'FaceColor',blue, 'FaceAlpha',alph, 'EdgeColor',edgeB, 'LineWidth',0.75);
    bar(xO(i), orT(i),  bw, 'FaceColor',gray, 'FaceAlpha',alph, 'EdgeColor',edgeG, 'LineWidth',0.75);
end
for i = 1:3
    bar(xB(i), bT(i), bw, 'FaceColor',gray, 'FaceAlpha',alph, 'EdgeColor',edgeG, 'LineWidth',0.75);
end

X = [xM xO xB]; Y = [mlsT orT bT]; E = [mlsS orS bS];
errorbar(X, Y, E, 'LineStyle','none', 'CapSize',3, 'LineWidth',0.7, ...
         'Color',[0.35 0.35 0.35], 'HandleVisibility','off');
% Labels use 2 decimals by default. Where a model's MLS and Orig would round to
% the SAME 2-decimal string (two different-height bars both showing e.g. "0.02",
% which is misleading -- ADNI MLP, 0.016 vs 0.021), add decimals for that pair
% until the two values read differently (capped at 4).
dec = 2 * ones(1, numel(X));
for i = 1:4
    if ~isnan(mlsT(i)) && ~isnan(orT(i))
        d = 2;
        while d < 4 && strcmp(sprintf('%.*f', d, mlsT(i)), sprintf('%.*f', d, orT(i)))
            d = d + 1;
        end
        dec(i) = d; dec(i+4) = d;
    end
end
for k = 1:numel(X)
    if ~isnan(Y(k))
        xk = X(k); fs = 34;
        if dec(k) > 2      % wider high-precision labels: shrink a touch and nudge the pair apart
            fs = 31;
            if k <= 4, xk = xk - 0.20; else, xk = xk + 0.20; end
        end
        text(xk, (Y(k)+E(k))*1.18, sprintf('%.*f', dec(k), Y(k)), ...
             'HorizontalAlignment','center', 'FontSize',fs, 'Color',[0.30 0.30 0.30]);
    end
end

set(gca, 'YScale','log');
lo = max(0.008, min(Y,[],'omitnan')*0.5);
hi = max(Y+E,[],'omitnan')*2.2;
ylim([lo hi]);
yt = [0.01 0.03 0.1 0.3 1 3 10 30 100];
yt = yt(yt>=lo & yt<=hi);
set(gca, 'YTick',yt, 'YTickLabel', compose('%g', yt));
set(gca, 'XTick',[gc xB], ...
         'XTickLabel', {'SVM','MLP','ResNet-3','ResNet-30','RF','GB','RUS'});
xlim([0.3 11.1]); xtickangle(20);
if ~bare       % y-axis name only on the first panel of a row
    ylabel('fit + predict time (s / fold)', 'Interpreter','latex', 'FontSize',46);
end
set(gca, 'TickDir','out', 'YGrid','on', 'XGrid','off', 'LineWidth',1.2, ...
         'FontSize',40, 'XColor',[0.25 0.25 0.25], 'YColor',[0.25 0.25 0.25]);
if ~isempty(ttl)
    title(ttl, 'Interpreter','latex', 'FontSize',44);
end

if ~bare       % legend only on the first panel of a row
    h1 = bar(nan, nan, 'FaceColor',blue, 'FaceAlpha',alph, 'EdgeColor',edgeB);
    h2 = bar(nan, nan, 'FaceColor',gray, 'FaceAlpha',alph, 'EdgeColor',edgeG);
    legend([h1 h2], {'MOS-KL features','original features'}, ...
           'Location','northwest', 'Box','off', 'FontSize',44);
end

exportgraphics(fig, [fnbase '.pdf'], 'ContentType','vector');
exportgraphics(fig, [fnbase '.png'], 'Resolution',180);
fprintf('saved %s.pdf\n', fnbase);
close(fig);
end

% ======================================================================
function [code, pretty] = taskName(raw)
% map a raw task label to a short filename code and a pretty title
map = { ...
 'Plasma_M12_ADCN',   'ADCN',   'AD vs.\ CN'; ...
 'Plasma_M12_ADLMCI', 'ADLMCI', 'AD vs.\ LMCI'; ...
 'Plasma_M12_CNLMCI', 'CNLMCI', 'CN vs.\ LMCI'; ...
 'SOMAscan7k_KNNimputed_AD_CN',     'AD_CN',     'AD vs.\ CN'; ...
 'SOMAscan7k_KNNimputed_AD_EMCI',   'AD_EMCI',   'AD vs.\ EMCI'; ...
 'SOMAscan7k_KNNimputed_AD_LMCI',   'AD_LMCI',   'AD vs.\ LMCI'; ...
 'SOMAscan7k_KNNimputed_CN_EMCI',   'CN_EMCI',   'CN vs.\ EMCI'; ...
 'SOMAscan7k_KNNimputed_CN_LMCI',   'CN_LMCI',   'CN vs.\ LMCI'; ...
 'SOMAscan7k_KNNimputed_EMCI_LMCI', 'EMCI_LMCI', 'EMCI vs.\ LMCI'; ...
 'newAD', 'newAD', 'newAD: AD vs.\ CN'; ...
 'GCM',   'GCM',   'Tumor vs.\ Normal' };
i = find(strcmp(map(:,1), char(raw)), 1);
if isempty(i)
    code = char(raw); pretty = char(raw);
else
    code = map{i,2}; pretty = map{i,3};
end
end
