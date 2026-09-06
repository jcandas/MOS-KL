function [Datas, parameters] = MLSFCT_FCD(Datas, parameters, methods)
%close all

%Chooses Truncation parameter based on Fisher Criterion. Projects data onto
%corresponding MLS subspace. Conserves the featues whose Fisher Criterion
%lie in the top percentile specified by parameters.multilevel.concentration

MA = getMA(Datas);
parameters.snapshots.k1 = MA; 
Datas = myMLS(Datas, parameters, methods);

%Eliminate Features where the variance of B is too close to that of A
NoiseField = "CovTraining";
FC = ComputeFC(Datas, NoiseField);
q = quantile(FC,parameters.multilevel.concentration);
isNoisy = FC >= q;


for C = ["A" "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set) = Datas.(C).(Set)(isNoisy,:);
end, end

parameters.multilevel.Mres = sum(isNoisy);

%% For Plotting Only
if ~parameters.parallel.on
close all
Variances = nan(6,parameters.multilevel.Mres);
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
%==========================================================================
function FC = ComputeFC(Datas, NoiseField)
for C = ["A", "B"]
    m.(C) = mean(Datas.(C).(NoiseField),2);
    v.(C) = var(Datas.(C).(NoiseField),[],2);
end
FC = ((m.A - m.B).^2) ./ (v.A + v.B);
end
%==========================================================================
function MA = getMA(Datas)
[U,~,~] = svd(Datas.A.CovTraining, 'econ', 'vector');

for C = ["A", "B"]
    Datas2.(C).CovTraining = U'*Datas.(C).CovTraining;
    %Datas2.(C).Noise = mean(Datas2.(C).CovTraining.^2,2);
end

FC = ComputeFC(Datas2, "CovTraining");
%relNoise = abs(Datas2.B.Noise - Datas2.A.Noise)./Datas2.A.Noise;

MA = [];
thresh = 3.2;
while isempty(MA)
thresh = thresh - 0.2;
MA = find(FC >= thresh, 1, 'first');
end
if MA == length(FC), MA = 1;  end
end


%==========================================================================
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
