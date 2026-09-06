function Mdl = ConstructResNet(X, Y, parameters)
% ConstructResNet  Train a tabular ResNet (fully-connected residual blocks).
%
%   Mdl = ConstructResNet(X, Y) builds and trains a residual MLP on the
%   tabular data X (N-by-D, observations in rows) with 0/1 labels Y, and
%   returns a ResNetClassifier whose [label, scores] = predict(Mdl, X) is a
%   drop-in match for the SVM/ensemble models used elsewhere.
%
%   Mdl = ConstructResNet(X, Y, parameters) reads architecture/training
%   settings from parameters.nn:
%       parameters.nn.resBlocks  - number of residual blocks (3-5, default 3)
%       parameters.nn.width      - hidden width per block        (default 64)
%       parameters.nn.maxEpochs  - training epochs               (default 150)
%
%   Each residual block is  fc -> relu -> fc  with a skip connection added
%   back in (additionLayer), followed by a relu. The head is fc(2) -> softmax.

% ---- Settings -----------------------------------------------------------
nBlocks  = 3;
width    = 64;
maxEpochs = 30;      % fixed number of training epochs (no early stopping)
if nargin >= 3 && isfield(parameters, 'nn')
    if isfield(parameters.nn, 'resBlocks') && ~isempty(parameters.nn.resBlocks)
        nBlocks = parameters.nn.resBlocks;
    end
    if isfield(parameters.nn, 'width') && ~isempty(parameters.nn.width)
        width = parameters.nn.width;
    end
    if isfield(parameters.nn, 'maxEpochs') && ~isempty(parameters.nn.maxEpochs)
        maxEpochs = parameters.nn.maxEpochs;
    end
end

% ---- Standardization. By default inputs arrive already standardized per feature
% from the training fold, so identity statistics are used and every model sees the
% same data. When parameters.nn.standardize is true, standardize per feature here
% using the TRAINING statistics; the same mu/sigma are stored and re-applied at
% predict time by ResNetClassifier.predict.
stdz = false;
if nargin >= 3 && isfield(parameters, 'nn') && isfield(parameters.nn, 'standardize') ...
        && ~isempty(parameters.nn.standardize)
    stdz = logical(parameters.nn.standardize);
end
if stdz
    mu = mean(X, 1);
    sigma = std(X, [], 1) + eps;
    Xn = (X - mu) ./ sigma;
else
    mu = 0;
    sigma = 1;
    Xn = X;
end

D = size(X, 2);

% ---- Targets: one-hot, columns ordered by sorted class names [0 1] ------
classNames = unique(Y);                       % e.g. [0; 1]
Ycat = categorical(Y, classNames);
T = onehotencode(Ycat, 2);                    % N-by-numClasses
numClasses = numel(classNames);

% ---- Build the residual network -----------------------------------------
lgraph = layerGraph();
stem = [
    featureInputLayer(D, 'Name', 'in')
    fullyConnectedLayer(width, 'Name', 'fc_in')
    reluLayer('Name', 'relu_in')
];
lgraph = addLayers(lgraph, stem);
prev = 'relu_in';

for b = 1:nBlocks
    block = [
        fullyConnectedLayer(width, 'Name', sprintf('fc%d_1', b))
        reluLayer('Name', sprintf('relu%d_1', b))
        fullyConnectedLayer(width, 'Name', sprintf('fc%d_2', b))
    ];
    lgraph = addLayers(lgraph, block);
    lgraph = addLayers(lgraph, additionLayer(2, 'Name', sprintf('add%d', b)));
    lgraph = addLayers(lgraph, reluLayer('Name', sprintf('relu%d_2', b)));

    % main path: prev -> fc_1 -> relu_1 -> fc_2 -> add/in1
    lgraph = connectLayers(lgraph, prev, sprintf('fc%d_1', b));
    lgraph = connectLayers(lgraph, sprintf('fc%d_2', b), sprintf('add%d/in1', b));
    % skip path: prev -> add/in2
    lgraph = connectLayers(lgraph, prev, sprintf('add%d/in2', b));
    % post-add activation
    lgraph = connectLayers(lgraph, sprintf('add%d', b), sprintf('relu%d_2', b));

    prev = sprintf('relu%d_2', b);
end

head = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
];
lgraph = addLayers(lgraph, head);
lgraph = connectLayers(lgraph, prev, 'fc_out');

net = dlnetwork(lgraph);

% ---- Train (fixed number of epochs, no early stopping) ------------------
% Trains on all the data for maxEpochs epochs (mini-batch Adam). The per-epoch
% mean training loss is captured for the loss-vs-epoch plots.
mbs = min(64, size(Xn, 1));
iterPerEpoch = max(1, floor(size(Xn, 1) / mbs));

opts = trainingOptions('adam', ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', mbs, ...
    'Shuffle', 'every-epoch', ...
    'InitialLearnRate', 1e-3, ...
    'L2Regularization', 1e-4, ...
    'Verbose', false);

[net, info] = trainnet(Xn, T, net, "crossentropy", opts);

% per-epoch mean training loss (from the per-iteration TrainingHistory)
th = info.TrainingHistory;
lossCol = th.Properties.VariableNames(contains(th.Properties.VariableNames, 'Loss'));
lossIter = th.(lossCol{1});
ep = ceil((1:numel(lossIter))' / iterPerEpoch);
lossHistory = accumarray(ep, lossIter(:), [], @(v) mean(v, 'omitnan'));
epochsRun = max(ep);

% ---- Wrap with prediction interface -------------------------------------
Mdl = ResNetClassifier(net, classNames, mu, sigma, epochsRun, lossHistory);

end
