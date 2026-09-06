function ComputeAUCStatistics
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
% 
myload = @(x) load(fullfile(x.folder, x.name));
thisdir = pwd;
methods = DefineMethods;
rF = ["Manual_Hyperparameter_Selection"];
CV = ["Kfold"];
Balances = ["Balanced", "Unbalanced"];
% 
% 
for DS = Datasets(:)'
  fprintf('Processing %s \n', DS);

    homePath = fullfile('..', 'results', rF, CV, DS, 'Leave_1_out', '**');

    X = dir(fullfile(homePath, '*.mat')); 
    for i = 1:length(X)
        fileName = fullfile(X(i).folder, X(i).name);
        load(fileName);
        nLevels = size(results.array,3);
        AUCstatistics = nan(length(parameters.data.NAvals), nLevels,2);

        for iA = parameters.data.NAvals
            for iLevel = 1:nLevels

            actual = results.array(iA,:,iLevel,:,1);
            rawMachine = results.array(iA,:,iLevel,:,2);
            actual = squeeze(actual(~isnan(actual)));
            rawMachine = squeeze(rawMachine(~isnan(rawMachine)));
            predicted = results.array(iA,:,iLevel,:,3);
            predicted = squeeze(predicted(~isnan(predicted)));

            [~,~,~,AUC] = perfcurve(actual,rawMachine,1);
            accuracy = sum(actual == predicted) / length(predicted);
            AUCstatistics(iA,iLevel,1) = AUC;
            AUCstatistics(iA, iLevel, 2) = accuracy;

            end
        end

        results.meanAUC = mean(AUCstatistics(:,:,1),1);
        results.stdAUC = std(AUCstatistics(:,:,1),1);
        %results.meanaccuracy = mean(AUCstatistics(:,:,2),1);
        results.stdaccuracy = std(AUCstatistics(:,:,2),1);

        save(fileName, 'Datas', 'parameters', 'results');
        
        % fprintf('%s', repmat('=',[1 100]));
        % fprintf('\nAUC:\n');
        % fprintf('%0.3f, ',results.AUC);
        % fprintf('\nMean AUC:\n');
        % fprintf('%0.3f, ', meanAUC);
        % fprintf('\nAUC standard deviation:\n')
        % fprintf('%0.3f, ', stdAUC);
        % fprintf('\n');

    end
%end 
end 
end


