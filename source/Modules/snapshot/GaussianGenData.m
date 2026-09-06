function [Datas, parameters] = GaussianGenData(Datas, methods, parameters)

tol = 10e-8;
for C = ["A", "B"]
    rawdata = Datas.rawdata.(C + "Data");
    m = mean(rawdata,2);
    N = size(rawdata,2);
    X = (N-1)^(-0.5)*(rawdata - m); 
    %neig = min(size(X));
    
    %[Phi, Lambda, Y] = svds(X); Lambda = diag(Lambda);
    [Phi, Lambda, Y] = svd(X, 'econ', 'vector'); 

    EV = cumsum(Lambda.^2) / sum(Lambda.^2);
    R = find(EV >= 1 - tol, 1, 'first');
    Phi = Phi(:,1:R); Lambda = Lambda(1:R); Y = Y(:,1:R);
    nY = size(Y,2);

    k = parameters.data.currentiter;
    numSamples = parameters.synthetic.NTest + parameters.synthetic.(C + "rs")(k);
    rng(1000);
    stochComps = randn(numSamples, nY);
    
    Datas.rawdata.(C + "Data") = m + (Phi .* Lambda') * stochComps';

end

end