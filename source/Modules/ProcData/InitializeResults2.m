function results = InitializeResults2(parameters)


% For the MLS (0) and ACA/feature-select (2,3) paths, each of the
% parameters.multilevel.Classifiers (SVM/MLP/ResNet3/ResNet30) is fitted at every
% level/truncation and stored in its own dim-3 slot. SlotLabels names each slot
% "SVM-L0","MLP-L0",... The benchmark (1) and ablation (4) paths key off their own
% lists (each machine/ablation is already its own slot).
Classifiers = parameters.multilevel.Classifiers;
nC = numel(Classifiers);
SlotLabels = strings(1,0);

switch parameters.multilevel.svmonly
    case 1 % Benchmark: one slot per learner in MachineList
        SlotLabels = string(parameters.misc.MachineList);
        nLevels = numel(SlotLabels);
    case 0 % MLS: nC classifiers x (l+1) levels
        baseLevels = parameters.multilevel.l + 1;
        if parameters.multilevel.chooseTrunc, baseLevels = 1; end
        nLevels = baseLevels * nC;
        SlotLabels = strings(1, nLevels);
        for c = 1:nC, for lv = 1:baseLevels
            SlotLabels((c-1)*baseLevels + lv) = Classifiers(c) + "-L" + string(lv-1);
        end, end
    case {2,3} % ACA / feature-select: nC classifiers x Mres truncations
        baseLevels = length(parameters.multilevel.Mres);
        if parameters.multilevel.chooseTrunc, baseLevels = 1; end
        nLevels = baseLevels * nC;
        SlotLabels = strings(1, nLevels);
        for c = 1:nC, for l = 1:baseLevels
            SlotLabels((c-1)*baseLevels + l) = Classifiers(c) + "-Mres" + string(l);
        end, end
    case 4
        SlotLabels = string(parameters.Ablation.List);
        nLevels = numel(SlotLabels);
end



switch parameters.data.validationType
    case 'Synthetic', nY = 2*parameters.synthetic.NTest;
    case 'Cross', nY = parameters.cross.NTestA + parameters.cross.NTestB;
    case 'Kfold', nY = 2*parameters.Kfold;
end

results.array = nan(length(parameters.data.NAvals),...
                    length(parameters.data.NBvals),...
                    nLevels,...
                    nY, ...
                    3);

results.notes = ["First dimension indexes the ith iteration over Class A subsets";...
                 "Second dimension indexes the jth iteration over Class B subsets";...
                 "Third dimension indexes the lth level of the multilevel filter, the lth subspace dimension, or lth machine";...
                 "Fourth Dimension indexes the Test Point";
                 "Fifth Dimension indexes the actual class label (1), raw SVM value (2), and predicted class (3)"];

results.DimRunTime = nan(1,nLevels);
results.SlotLabels = SlotLabels;   % human-readable name for each dim-3 slot


if parameters.multilevel.chooseTrunc
    results.TruncArray = nan(length(parameters.data.NAvals),...
                            length(parameters.data.NBvals),...
                            2);

end
