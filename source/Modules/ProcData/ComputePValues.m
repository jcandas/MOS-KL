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

myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
rF = ["results"];
CV = ["Kfold"];
Balances = ["Balanced", "Unbalanced"];
Accs = ["AUC", "accuracy"];




for DS = Datasets(:)'
  fprintf('Processing %s \n', DS);

  %Get Balanced result
  homePath = fullfile('..', rF, 'Manual_Hyperparameter_Selection', CV, DS, 'Leave_1_out');
  X = dir(fullfile(homePath, '**', '*.mat'));
  isBench = contains({X.name}, 'Benchmark');
  XB = X(isBench);
  YB = load(fullfile(XB.folder, XB.name));
  N = YB.parameters.data.A*YB.parameters.data.B;

  XF = X(~isBench);
for i = 1:length(XF)
    %Get result
    fileName = fullfile(XF(i).folder, XF(i).name);
    YF = load(fileName);
for Acc = Accs

    p1 = YB.results.(Acc)(:); %Benchmark metric
    p2 = YF.results.(Acc)(:)'; %Comparative metric
        
    %Compute p value
    p = (p1 + p2) / 2;
    z = (p2 - p1) ./ sqrt((p .* (1 - p) * (2/N)));
    pval = 1 - normcdf(z);
    YF.results.(Acc + "_pval") = pval;
       
end
    save(fileName, '-struct', 'YF');
    % cd(XF(i).folder);
    % keyboard;
    % cd(thisdir);
end 
end 








