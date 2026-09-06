function PlotSynthMcNemarVals
close all

folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', 'Graphs');
if ~isfolder(folder), mkdir(folder); end

%% Define Iterators 

[DS, DS2] = DefineDatasets;
t0 = 5*10.^[-5,-4,-3];
transforms = arrayfun(@(x) replace(sprintf("Noise_%0.g", x),'.', '_'),t0);
transforms = ["id", transforms];
transforms2 = ["0", arrayfun(@(x) sprintf("%0.0e",x), t0)];
Algos = ["MLS", "ACA-L", "ACA-S"];

%% Define Folder Path
folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', 'Graphs');
if ~isfolder(folder), mkdir(folder); end


%% Create Figure and Axes
[f, ax] = CreateFigureAndAxes(Algos, transforms2, DS2);


%% Get imagesc's

images = nan(length(DS), length(transforms), length(Algos));
for iDS = 1:length(DS)
    ds = DS(iDS); ds2 = DS2(iDS);

for iNoise = 1:length(transforms)
    Noise = transforms(iNoise);
    X = GetFiles(ds, Noise);


for iAlgo = 1:length(Algos)
    Algo = Algos(iAlgo);
    images(iDS, iNoise, iAlgo) = GetBestPVal(X, Algo);
end

end
end

x = 1:size(images,2); y = 1:size(images,1);
labels = arrayfun( @(x) sprintf("%0.2f", x), max(images, 0.01+eps));
labels(labels == "0.01") = "<.01";
labels = replace(labels, ["1.00", "0."], ["1.0", "."]);
[x2, y2] = meshgrid(x,y);

for iAlgo = 1:length(Algos)
    image = flipud(images(:,:,iAlgo));
    imagesc(ax(iAlgo), x,y,image);
    label = flipud(labels(:,:,iAlgo));
    text(ax(iAlgo), x2(:), y2(:), label, ...
        'VerticalAlignment','middle',...
        'HorizontalAlignment','center',...
        'FontSize',11);
    %grid on
end




c = [min(images(:)), max(images(:))];
FixAxes(ax,transforms2,DS2(end:-1:1),c);
exportgraphics(gcf, fullfile(folder, "McNemar_pvals.pdf"));


end

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
function files = GetFiles(DS,Noise)

ClassSize = sprintf('%d_TrainingA_%d_TrainingB_%d_Testing', 600, 200, 10000);
folder = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', 'Synthetic', DS, ClassSize, Noise,'Unbalanced');
files = dir(fullfile(folder, '*.mat'));
files(matches({files.name}, [".", ".."])) = [];

end
%==========================================================================
%==========================================================================
function MPval = GetBestPVal(files, Algo)

X0 = files(contains({files.name}, Algo));
X1 = arrayfun( @(x) load(fullfile(x.folder, x.name)), X0);
[Best,~] = arrayfun( @(x) max(x.results.accuracy), X1);
[~,iBest] = max(Best);
X2 = X1(iBest);
[~,iBest2] = max(X2.results.accuracy);
MPval = X2.results.McNemar_pvalue_accuracy(iBest2);
end
%==========================================================================
%==========================================================================
function [f, ax] = CreateFigureAndAxes(Algos, x, y)
    f = figure('Units', 'Normalized', 'Position', [0.1,0.3,0.6,0.5]);
    for i = 1:length(Algos)
        ax(i) = subplot(1,3,i); hold on
        % 
        % ylabel("Noise", 'FontSize', 12, 'Interpreter', 'latex');
        %xlim([-0.5, length(x) + 0.5]);
        %ylim([-0.5, length(y) + 0.5]);
    end
end
%==========================================================================
%==========================================================================
function FixAxes(ax,x,y,c)

g = linspace(0,1,50); g = g'.^(10);
colorgrad =  [ [1,0,0] .* (1 - g) + [1,1,0] .* g;
               [1,1,0] .* (1 - g) + [0,1,0] .* g];
colorgrad = flipud(colorgrad);

Algos = ["MLS", "ACA-L", "ACA-S"];
% co = colorbar; 
% co.Position([1,3,4]) = [0.95, 0.04, 0.805];



for i = 1:length(ax)
       % ax(i).Position([1,3]) = [0.08, 0.7250];
        ax(i).Position([2,4]) = [0.11, 0.815];
        ax(i).XTick = 1:length(x);
        yline(ax(i), 0.5:length(y)+0.5);
        xline(ax(i), 0.5:length(x)+0.5);
        ax(i).XTickLabels = x;
        ax(i).XLim = [0.5, length(x)+0.5];
        ax(i).YLim = [0.5, length(y)+0.5];
        ax(i).GridColor = 'k';
        ax(i).FontSize = 13;
        
        if i == 2
        xlabel(ax(i), "Noise", 'FontSize', 14, 'Interpreter', 'latex');
        end
        title(ax(i), Algos(i), 'FontSize', 16, 'Interpreter', 'latex');
            
        if i == 1
            ax(i).YTick = 1:length(y) ;
            ax(i).YTickLabels = y;
            ax(i).YAxis.FontSize = 13;
            %ax(i).YTickLabelRotation = 30;
           
            
        else
            ax(i).YTickLabels = "";
        end

        ax(i).TickLabelInterpreter = 'latex';

        colormap(ax(i), colorgrad);
        ax(i).ColorScale = "log";
        clim(ax(i), c);
end



end

