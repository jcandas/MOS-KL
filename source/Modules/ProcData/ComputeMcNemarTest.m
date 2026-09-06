Datasets = [...
            "newAD", 
            "Plasma_M12_ADCN", 
            "Plasma_M12_ADLMCI",
            "Plasma_M12_CNLMCI",
            "SOMAscan7k_KNNimputed_AD_LMCI",
            "SOMAscan7k_KNNimputed_CN_LMCI",
            "SOMAscan7k_KNNimputed_AD_CN",
            "GCM"...
            ];

myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
rF = ["results"];
CV = ["Synthetic"];
Balances = ["Balanced", "Unbalanced"];
Accs = ["accuracy"];

transforms = arrayfun(@(x) replace( ...
    sprintf("Noise_%0.g", x),...
    '.', '_'), ...
    5*10.^[-2,-1]);
transforms = ["id", transforms];



for DS = Datasets(:)'
    fprintf('Processing %s \n', DS);
for Noise = transforms
  
  X = dir(fullfile('..', rF, 'Manual_Hyperparameter_Selection', ...
      CV, DS, '600_TrainingA_200_TrainingB_10000_Testing', ...
      Noise, '**', '*.mat'));
  isBench = contains({X.name}, 'Benchmark') & contains({X.folder}, 'Unbalanced');
  XB = X(isBench);

  YB = load(fullfile(XB.folder, XB.name));

for Acc = Accs

[BestBaseline,iBest] = max(YB.results.(Acc));

BenchmarkActual = squeeze(YB.results.array(:,:,iBest,:,1));
BenchmarkActual = BenchmarkActual(~isnan(BenchmarkActual));
BenchmarkPredicted = squeeze(YB.results.array(:,:,iBest,:,3));
BenchmarkPredicted = BenchmarkPredicted(~isnan(BenchmarkPredicted));
BenchmarkCorrect = BenchmarkActual == BenchmarkPredicted;
BenchmarkIncorrect = ~BenchmarkCorrect;

XF = X(~isBench);

for i = 1:length(XF)
    
    %Get result
    fileName = fullfile(XF(i).folder, XF(i).name);
    YF = load(fileName);
    nL = size(YF.results.array,3);

    pvaluesMcNemar = nan(1,nL);
    pvaluesWilcoxon = pvaluesMcNemar;
    for iL = 1:nL
    
    FinderActual = squeeze(YF.results.array(:,:,iL,:,1));
  FinderActual = FinderActual(~isnan(FinderActual));
  FinderPredicted = squeeze(YF.results.array(:,:,iL,:,3));
  FinderPredicted = FinderPredicted(~isnan(FinderPredicted));
  if isempty(FinderActual) || isempty(FinderPredicted), continue, end
  FinderCorrect = FinderActual == FinderPredicted;
  FinderIncorrect = ~FinderCorrect;



  B = sum(BenchmarkCorrect & FinderIncorrect);
  C = sum(BenchmarkIncorrect & FinderCorrect);
  
  testStatistic = (abs(B - C) - 1)^2 / (B + C);
  pvaluesMcNemar(iL) = chi2cdf(testStatistic,1,'upper');
  pvaluesWilcoxon(iL) = signrank(double(FinderCorrect), ...
      double(BenchmarkCorrect), 'tail', 'right');
 
  end

   fieldnameMcNemar = sprintf('McNemar_pvalue_%s', Acc);
   fieldnameWilcoxon = sprintf('Wilcoxon_pvalue_%s', Acc);
  YF.results.(fieldnameMcNemar) = pvaluesMcNemar;
  YF.results.(fieldnameWilcoxon) = pvaluesWilcoxon;

  save(fileName, '-struct', 'YF');


end

end

end 

end 








