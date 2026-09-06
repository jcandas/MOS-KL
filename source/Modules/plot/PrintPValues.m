Datasets = [...
              "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            % "SOMAscan7k_KNNimputed_AD_LMCI",
            % "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "GCM"...
            ];

%myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
rF = ["results"];
CV = ["Kfold"];
Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];
sig = 0.05;




for DS = Datasets(:)'
  fprintf('Processing %s \n', DS);

  %Get Balanced result
  homePath = fullfile('..', rF, 'Manual_Hyperparameter_Selection', CV, DS, 'Leave_1_out');
  X = dir(fullfile(homePath, '**', '*.mat'));
  isBench = contains({X.name}, 'Benchmark');
  XB = X(isBench);
  YB = load(fullfile(XB.folder, XB.name));

for Balance = Balances
    fprintf('%s regime \n', Balance);

for Acc = Accs
    
    [maxAcc, imax] = max(YB.results.(Acc));
    BestBaseline = YB.parameters.misc.MachineList(imax);
    fprintf('\nBest %s: %0.2f, obtained by %s \n', ...
        Acc, maxAcc, BestBaseline);


    XF = X(~isBench & contains({X.folder}, Balance));
    
    
for i = 1:length(XF)
    
    %Get result
    fileName = fullfile(XF(i).folder, XF(i).name);
    YF = load(fileName);
    pvalues = YF.results.(Acc + "_pval")(imax,:);
    if ~any(pvalues < sig), continue, end

    pvalues_str = repmat("", size(pvalues));
   % s = string(char([1 1 1]));
    pvalues_str(pvalues >= sig) = "| X.XXX ";
    pvalues_str(pvalues < sig) = arrayfun(@(x) sprintf("| %0.3f ", x), pvalues(pvalues < sig));
    

    printTag = replace(XF(i).name, '-Inner-Nesting', '');
    printTag = extractBefore(printTag, '-Eigen');
    printTag = extractAfter(printTag, DS + "-");

    
    fprintf('%s', pvalues_str);
    %fprintf('| %0.3f ', pvalues);
    fprintf('| %s\n', printTag);
    

    
end
fprintf('\n');
end
    
end 
end 








