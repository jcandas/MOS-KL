function [parameters] = FitClassifierNormalize(Datas, parameters, methods)
% FitClassifierNormalize  Generic classifier fitter for the multilevel path.
%
%   Drop-in replacement for FitSVMNormalize. It fits the classifier named by
%   parameters.multilevel.currentClassifier ("SVM" | "MLP" | "ResNet") on the
%   (possibly multilevel-transformed) training data and stores the trained
%   model in parameters.multilevel.SVMModel -- the field CompPredictAUC2
%   reads. The "SVM" branch reproduces FitSVMNormalize exactly, so existing
%   SVM results are unchanged.

SVMField = 'multilevel';

classifier = "SVM";
if isfield(parameters.multilevel, 'currentClassifier') ...
        && ~isempty(parameters.multilevel.currentClassifier)
    classifier = string(parameters.multilevel.currentClassifier);
end

switch classifier
    case "SVM"
        if parameters.svm.kernal == 1
            model = methods.all.SVMmodel(Datas.X_Train, Datas.y_Train, ...
                'KernelFunction', 'RBF', 'KernelScale', 'auto');
        else
            model = methods.all.SVMmodel(Datas.X_Train, Datas.y_Train);
        end
        model = fitSVMPosterior(model);

    case "MLP"
        model = ConstructMLP(Datas.X_Train, Datas.y_Train, parameters);

    case {"ResNet", "ResNet3", "ResNet30"}
        % depth encoded in the name (e.g. "ResNet30" -> 30 residual blocks)
        d = regexp(char(classifier), '\d+$', 'match', 'once');
        if ~isempty(d), parameters.nn.resBlocks = str2double(d); end
        model = ConstructResNet(Datas.X_Train, Datas.y_Train, parameters);

    otherwise
        error('FitClassifierNormalize:unknownClassifier', ...
            'Unknown classifier "%s".', classifier);
end

parameters.(SVMField).SVMModel = model;

end
