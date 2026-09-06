Datasets = [...
            "GCM",
            "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",            
            ];

Truncs = [39,8,5,5,5,8,8,8];

thisdir = pwd;
methods = DefineMethods;

Accs = ["AUC", "accuracy"];
Balances = ("Balanced"|"Unbalanced");
Kernels = ("Linear"|"Radial");
Algos = ("MLS"|"ACA-S"|"ACA-L"|"Benchmark");
Normalize = ("MyUnitVariance2");
PatternArray = [Balances, Kernels, Algos, Normalize];

f0 = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', ...
            'Kfold', '*', 'Leave_5_out', '**', '*.mat');

f1 = dir(f0);
f2 = fullfile({f1.folder}, {f1.name});
f3 = f2(contains(f2, Normalize));
nf = length(f3);
m = floor(log10(nf)); 
for i = 1:length(f3)
    if mod(i,10^(m-1)) == 0
        fprintf('Processing %d of %d\n', i, nf);
    end
    f4 = load(f3{i});
    f4.results.array = 1 - f4.results.array;
    f4.results = ComputeResultsAccuracy(f4.results);
    save(f3{i},"-struct", "f4");
end



% for DS = Datasets'
%    fprintf('Processing %s\n', DS);
%     f0 = fullfile('..', 'results', 'Manual_Hyperparameter_Selection', ...
%         'Kfold', DS, 'Leave_5_out', '**', '*.mat');
%     f1 = dir(f0);
% 
%     idx = contains({f1.name}, Normalize);
%     f2 = f1(idx);
% 
%     for i = 1:length(f2)
%         Path = string(fullfile(f2(i).folder, f2(i).name));
%         load(Path);
%         V = arrayfun(@(x) extract(Path, x), PatternArray, 'UniformOutput',false);
%         V = [V{:}];
%         fprintf('\t'), fprintf('%s, ', V); fprintf('\n');
%         for Acc = Accs
%             fprintf('\t %s:', Acc);
%             fprintf(' %0.3f, ', results.(Acc));
%             fprintf('\n');
%         end
%         fprintf('\n');
%         pause(3)
%     end
% 
% end








