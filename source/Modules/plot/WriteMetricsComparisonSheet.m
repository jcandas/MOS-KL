function WriteMetricsComparisonSheet

p.Results = "results";
p.MOE = "Manual_Hyperparameter_Selection";
p.Nesting = "Inner-Nesting";
p.Normalized = "MyUnitBox";
p.Truncs = [39, 8, 5, 5, 5, 8, 8, 8];
p.Trunc = [];
p.CrossVal = "Kfold";
p.HoldOut = "Leave_5_out";

Accs = ["AUC", "accuracy"];
[DataSets, ~] = GetDataSets();

%% Print AUC and accuracy Table
load(fullfile('..',p.Results, p.MOE, p.CrossVal, 'Tables', 'Performance_Table.mat'));
for acc = Accs
    fprintf('\t\t%s\n', acc);
    disp(table2array(T.(acc)));
    keyboard
end


%% Print FINDER and Bench difference

for acc = Accs
    fprintf('\n');
    fprintf('\t\t Absolute %s Difference between FINDER and Bench \n', acc);
    AMinusSVM = table2array(T.(acc)(["MLS", "ACA-S", "ACA-L"],:)) - ....
    table2array(T.(acc)("SVM",:));

    AMinusBoost = table2array(T.(acc)(["MLS", "ACA-S", "ACA-L"],:)) - ...
        table2array(T.(acc)("Boost/Bag",:));

    disp([AMinusSVM; AMinusBoost]);

    % fprintf('\n\t\t Relative %s Difference between FINDER and Bench \n', acc);
    % RMinusSVM = AMinusSVM ./ table2array(T.(acc)("SVM",:));
    % RMinusBoost = AMinusBoost ./ table2array(T.(acc)("Boost/Bag",:));
    % 
    % disp([RMinusSVM; RMinusBoost]);

    keyboard

end

for acc = Accs
fprintf('\n')
fprintf('\t\t Absolute %s Difference between MLS and ACA \n', acc);
AMinusACA =  table2array(T.(acc)(["ACA-S", "ACA-L"],:)) - ...
    table2array(T.(acc)("MLS",:));

disp(AMinusACA);

% fprintf('\n\t\t Relative %s Difference between MLS and ACA \n', acc);
% RMinusACA = AMinusACA ./ table2array(T.(acc)("MLS",:));
% 
% disp(RMinusACA);

keyboard

end

SVMArray = nan(4, length(DataSets), length(Accs));
for acc = Accs
    
    for iDS = 1:length(DataSets)
        p.DS = DataSets(iDS); p.acc = acc;
        SVMArray(:,iDS, Accs == acc) = GetBenchmark(p);
    end

    fprintf('\n')
    fprintf('\t\t SVM %s \n', acc);
    disp(SVMArray(:,:, Accs == acc));

    keyboard
    
end

for acc = Accs
    fprintf('\n')
    fprintf('\t\t Absolute %s SVM Difference \n');
    
    ASVM = SVMArray(2:end,:,Accs == acc) - SVMArray(1,:,Accs == acc);

    % fprintf('\t\t Relative %s SVM Difference \n');
    % RSVM = ASVM ./ SVMArray(1,:,Accs == acc);

end




end

%==========================================================================
function [DataSets, DataAliases] = GetDataSets()

a1 = ["AD" "AD" "CN"]; a2 = ["CN" "LMCI" "LMCI"];

DataSets(1:2) = ["GCM" "newAD"];
DataSets(3:5) = "Plasma_M12_" + a1 + a2;
DataSets(6:8) = "SOMAscan7k_KNNimputed_" + a1 + "_" + a2;

DataAliases(1:2) = DataSets(1:2);
DataAliases(3:5) = "ADNI (" + a1 + " vs. " + a2 + ")";
DataAliases(6:8) = replace(DataAliases(3:5), "ADNI", "CSF");
end

%==========================================================================
function Xout = GetBenchmark(p)
folderpath = fullfile('..', p.Results, p.MOE, p.CrossVal, p.DS, p.HoldOut,'**', '*.mat');
X = dir(folderpath); 
mycontains = @(f,s) contains({X.(f)}, s); 

XBench = X(mycontains('name','Benchmark') &...
           mycontains('name',p.Normalized));
load(fullfile(XBench.folder, XBench.name));
SVMs = "SVM_" + ["Linear", "Radial"] + ["";"-PCA"]; SVMs = SVMs(:);

fun = @(x) results.(p.acc)(parameters.misc.MachineList == x);
Xout = arrayfun(@(x) results.(p.acc)(parameters.misc.MachineList == x), SVMs);
%Xout = Xout(:)';
end