function [Datas, parameters] = EpsilonBinningSymmetrization(Datas, parameters, methods)
%close all
%Rewrite Data in class A eigenbasis
Datas2 = Datas;
Datas2 = methods.Multi2.EigenbasisA(Datas2, parameters, methods);

BinSize = 1 - parameters.multilevel.concentration;
ANoise = mean(Datas2.A.CovTraining.^2,2);
Bins = ANoise(1) * (1:-BinSize:0);
if ~ismember(0, Bins), Bins = [Bins 0]; end

%Symmetrize components 
for iBin = 1:length(Bins)-1

    Bin = [Bins(iBin), Bins(iBin+1)];
    Bindices = find(ANoise <= Bin(1) & ANoise > Bin(2));

    if isempty(Bindices), continue, end

for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        components = Datas2.(C).(Set)(Bindices,:);  %Components in the bin
        SRC = mean(components, 1); %Symmetrized Components
        DRC = components - SRC; %Denoised Components
        Datas2.(C).(Set)(Bindices,:) = DRC;
end, end

end

%Eliminate Features where the variance of B is too close to that of A
NoiseField = "CovTraining";
ANoise = mean(Datas2.A.(NoiseField).^2,2);
BNoise = mean(Datas2.B.(NoiseField).^2,2);


thresh = 3;

while true

RelativeNoise = abs(BNoise - ANoise) ./ ANoise;
NoisyFeatures = RelativeNoise >= 3;
numNoisy = sum(NoisyFeatures);

if numNoisy == 0 
    thresh = thresh - 0.2;

    if thresh <= 0
        NoisyFeatures = parameters.snapshots.k1:parameters.data.numofgene;
        numNoisy = length(NoisyFeatures);
        break
    end
    continue
elseif numNoisy > 0
    break
end

end



for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas2.(C).(Set) = Datas2.(C).(Set)(NoisyFeatures,:);
end, end
parameters.multilevel.Mres = numNoisy;


%% For Plotting Only
if ~parameters.parallel.on
close all
Variances = nan(6,numNoisy);
i = 0;
YTickLabels = [];
for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        i = i+ 1;
        v = mean(Datas2.(C).(Set).^2,2);
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

q = quantile(Variances(:),0.75); q = max(q, 0.0005);
clim([0,q]);


end

Datas = Datas2;




end