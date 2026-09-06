function [Datas, parameters] = SymmetrizeResidualComponents(Datas, parameters, methods)
close all
%Rewrite Data in class A eigenbasis
Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);
% %S = sum(Datas.A.CovTraining.^2,2);
% %EV = cumsum(S) / sum(S);
% %parameters.snapshots.k1 = find(EV > parameters.multilevel.concentration, 1, 'first');


%Smooth residual components 
M = parameters.snapshots.k1;
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        RC = Datas.(C).(Set)(M+1:end,:); %Residual Components
        SRC = mean(RC, 1); %Smoothed Residual Components
        DRC = RC - SRC; %Denoised Residual Components
        Datas.(C).(Set) = DRC;
end, end

%Eliminate Features where the variance of B is too close to that of A
NoiseField = "CovTraining";
ANoise = mean(Datas.A.(NoiseField).^2,2);
BNoise = mean(Datas.B.(NoiseField).^2,2);
RelativeNoise = abs(BNoise - ANoise) ./ ANoise;

thresh = 3; 
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


for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set) = Datas.(C).(Set)(NoisyFeatures,:);
end, end


%% For Plotting Only
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
cm = (t) .* [1,0,0] + (1-t) .* [1 1 1];

%Plot Variances
imagesc(Variances)
colormap(cm), colorbar
set(gca, 'YTick', 1:size(Variances,1))
set(gca, 'YTickLabels', YTickLabels);

XTickLabel = string(get(gca, 'XTickLabel'));
XTickLabel(double(XTickLabel) ~= floor(double(XTickLabel))) = "";
set(gca, 'XTickLabel', XTickLabel);

q = quantile(Variances(:),0.75); clim([0,q]);

parameters.multilevel.Mres = sum(NoisyFeatures);





end