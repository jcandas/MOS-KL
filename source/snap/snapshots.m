%Construct eigenfunction by using eigenvectors
function [results] = snapshots(Datas, parameters);

tcx = Datas.TrainingTum;
ncx = Datas.TrainingNrom;

tmx = size(tcx,2);
nmx = size(ncx,2);

% Compute eigenvectors and eigenvalues of covariance matrice
k = parameters.snapshots.k;
tM = size(tcx,2);
nM = size(ncx,2);

% Run SVD to compute eigenvalues and eigenvectors
tC = (tcx' * tcx) / tM; %Covariance Matrix
[tu,ts,tv] = svd(tC);
nC = (ncx' * ncx) / nM; %Covariance Matrix
[nu,ns,nv] = svd(nC);

ts = diag(ts);
ts = ts(1 : k);
tu = tu(:,1 : k);

ns = diag(ns);
ns = ns(1 : k);
nu = nu(:,1 : k);


results.covariancetum = tC;
results.eigenvaluestum = ts;
results.eigenvectorstum = tu;

results.covariancenorm = nC;
results.eigenvaluesnorm = ns;
results.eigenvectornorm = nu;

%Normalize eigenfunction
txefun = results.eigenvectorstum' * tcx' ./sqrt(ts)/sqrt(tM);
nxefun = results.eigenvectorsnorm' * ncx' ./sqrt(ns)/sqrt(nM);

results.eigenfunctionTum = txefun;
results.eigenfunctionNorm = nxefun;
end


