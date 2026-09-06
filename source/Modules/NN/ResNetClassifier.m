classdef ResNetClassifier
    % ResNetClassifier  Wrapper that gives a trained tabular-ResNet dlnetwork
    % the same prediction interface as fitcsvm / fitcnet models.
    %
    %   [label, scores] = predict(obj, X) returns N-by-1 class labels and an
    %   N-by-2 score matrix (softmax probabilities) with columns ordered to
    %   match obj.ClassNames = [0; 1]. This is exactly the contract that
    %   CompPredictAUC2 relies on, so a ResNetClassifier can be dropped in
    %   wherever an SVM model is used.
    %
    %   Built by ConstructResNet.

    properties
        Net          % trained dlnetwork
        ClassNames   % column vector of class labels, e.g. [0; 1]
        Mu           % 1-by-D feature means used for standardization
        Sigma        % 1-by-D feature standard deviations used for standardization
        Epochs       % epochs actually run; NaN if unknown
        LossHistory  % per-epoch mean training loss (column vector); [] if unknown
    end

    methods
        function obj = ResNetClassifier(net, classNames, mu, sigma, epochs, lossHistory)
            obj.Net = net;
            obj.ClassNames = classNames;
            obj.Mu = mu;
            obj.Sigma = sigma;
            if nargin >= 5, obj.Epochs = epochs; else, obj.Epochs = NaN; end
            if nargin >= 6, obj.LossHistory = lossHistory; else, obj.LossHistory = []; end
        end

        function [label, scores] = predict(obj, X)
            % Standardize with the training statistics.
            Xn = (X - obj.Mu) ./ obj.Sigma;

            % Forward pass -> N-by-2 softmax probabilities.
            scores = minibatchpredict(obj.Net, Xn);
            scores = double(gather(scores));

            % Predicted class = argmax over columns (column j -> ClassNames(j)).
            [~, idx] = max(scores, [], 2);
            label = obj.ClassNames(idx);
        end
    end
end
