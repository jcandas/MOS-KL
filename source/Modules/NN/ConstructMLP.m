function Mdl = ConstructMLP(X, Y, parameters)
% ConstructMLP  Train a multilayer perceptron (3-5 hidden layers) classifier.
%
%   Mdl = ConstructMLP(X, Y) trains a feedforward neural network with the
%   default hidden-layer sizes using fitcnet. X is N-by-D (observations in
%   rows), Y is an N-by-1 vector of 0/1 labels.
%
%   Mdl = ConstructMLP(X, Y, parameters) reads the hidden-layer sizes from
%   parameters.nn.mlpLayers when present.
%
%   The returned model is a ClassificationNeuralNetwork whose
%   [label, scores] = predict(Mdl, X) interface is a drop-in match for the
%   SVM/ensemble models used elsewhere (see CompPredictAUC2), so no changes
%   to the prediction pipeline are required.

% Hidden-layer sizes (3-5 layers). Override via parameters.nn.mlpLayers.
layers = [64 32 16];
if nargin >= 3 && isfield(parameters, 'nn') && isfield(parameters.nn, 'mlpLayers') ...
        && ~isempty(parameters.nn.mlpLayers)
    layers = parameters.nn.mlpLayers;
end

% Let fitcnet standardize per feature internally when requested
% (parameters.nn.standardize); default false so pre-standardized pipelines are
% unchanged.
stdz = false;
if nargin >= 3 && isfield(parameters, 'nn') && isfield(parameters.nn, 'standardize') ...
        && ~isempty(parameters.nn.standardize)
    stdz = logical(parameters.nn.standardize);
end

Mdl = fitcnet(X, Y, ...
    'LayerSizes', layers, ...
    'Activations', 'relu', ...
    'Standardize', stdz, ...
    'IterationLimit', 1000);

end
