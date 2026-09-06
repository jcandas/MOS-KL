function [Datas, parameters] = EigenbasisATruncDim(Datas, parameters, methods)
%close all

Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);

%Eliminate Features where the variance of B is too close to that of A
NoiseField = "CovTraining";
ANoise = mean(Datas.A.(NoiseField).^2,2);
BNoise = mean(Datas.B.(NoiseField).^2,2);

RelativeNoise = abs(BNoise - ANoise) ./ ANoise;

thresh = 2; 
while true

NoisyFeatures = RelativeNoise >= thresh;
numNoisy = sum(NoisyFeatures);

if numNoisy == 0
    thresh = thresh - 0.2;
    if thresh <= 0
        NoisyFeatures = true([1 parameters.data.numofgene]);
        numNoisy = sum(NoisyFeatures);
        break
    end
    continue
elseif numNoisy > 0
    break
end
end


%% Set MA to be the first index at which a noisy feature is found. 
MA = find(NoisyFeatures, 1, 'first');
NoisyFeatures(1:MA) = [];
numNoisy = sum(NoisyFeatures);

for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set)(1:MA,:) = [];
        Datas.(C).(Set) = Datas.(C).(Set)(1:numNoisy,:);
end, end

parameters.multilevel.Mres = numNoisy;

%% For Plotting Only
if ~parameters.parallel.on
close all
Variances = nan(6,sum(NoisyFeatures));
i = 0;
YTickLabels = [];
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        i = i+ 1;
        v = mean(Datas.(C).(Set).^2,2);
        Variances(i,:) = v';
        YTickLabels = [YTickLabels, C + " " + Set];
end, end
Variances = Variances / max(Variances, [], 'all');


f = figure('Units', 'normalized', 'Position', [0.2, 0.2, 0.6, 0.2]);


%Make gradation from red to white
t = linspace(0.1,0.9,100); t = t(:);
cm = (t) .* [0.5,0,0] + (1-t) .* [1 1 1];

%Plot Variances
imagesc(Variances)
colormap(cm), colorbar
set(gca, 'YTick', 1:size(Variances,1))
set(gca, 'YTickLabels', YTickLabels);

XTickLabel = string(get(gca, 'XTickLabel'));
XTickLabel(double(XTickLabel) ~= floor(double(XTickLabel))) = "";
set(gca, 'XTickLabel', XTickLabel);

q = quantile(Variances(:),0.75); q = max(q, 0.005);
clim([0,q]);


end


end

function Datas = myMLS(Datas, parameters, methods)

[U,~,~] = svds(Datas.A.CovTraining, parameters.snapshots.k1, 'largest');

[~,...
Datas.A.CovTraining,...
Datas.A.Machine,...
Datas.A.Testing,...
Datas.B.CovTraining,...
Datas.B.Machine,...
Datas.B.Testing] = ...
methods.Multi2.BinarySVD(...
U,...
Datas.A.CovTraining,...
Datas.A.Machine,...
Datas.A.Testing,...
Datas.B.CovTraining,...
Datas.B.Machine,...
Datas.B.Testing);

for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set)(1:parameters.snapshots.k1, :) = [];
end, end

end
