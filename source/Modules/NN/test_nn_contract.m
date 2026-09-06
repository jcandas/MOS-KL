function test_nn_contract()
% Smoke test: confirm ConstructMLP and ConstructResNet satisfy the
% [label, scores] = predict(model, X) contract that CompPredictAUC2 needs.

addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

rng(0);
N = 120; D = 12;
X = randn(N, D);
Y = double(sum(X(:,1:3), 2) + 0.3*randn(N,1) > 0);   % 0/1 labels

fprintf('Toolbox check: fitcnet=%d trainnet=%d dlnetwork=%d minibatchpredict=%d\n', ...
    exist('fitcnet','file')>0, exist('trainnet','file')>0, ...
    exist('dlnetwork','file')>0, exist('minibatchpredict','file')>0);

% ---- MLP ----
M = ConstructMLP(X, Y);
[lab, sc] = predict(M, X);
assert(size(sc,2) == 2, 'MLP scores must be N-by-2');
assert(all(ismember(lab, [0 1])), 'MLP labels must be 0/1');
fprintf('MLP    OK  train-acc = %.3f\n', mean(lab(:) == Y(:)));

% ---- ResNet ----
p.nn.resBlocks = 3; p.nn.width = 32; p.nn.maxEpochs = 30;
R = ConstructResNet(X, Y, p);
[lab2, sc2] = predict(R, X);
assert(size(sc2,2) == 2, 'ResNet scores must be N-by-2');
assert(all(ismember(lab2, [0 1])), 'ResNet labels must be 0/1');
fprintf('ResNet OK  train-acc = %.3f\n', mean(lab2(:) == Y(:)));

disp('ALL CONTRACT TESTS PASSED');
end
