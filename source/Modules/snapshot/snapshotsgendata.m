
function [Datas, parameters] = snapshotsgendata(Datas, methods, parameters)
% generates synthetic data 
    
    % real A and B data
    AData=Datas.rawdata.AData;
    BData=Datas.rawdata.BData;

    % Normalize the base data before generation. readData3 (unlike the old readData)
    % does NOT normalize at load, so AData/BData are on the raw GCM scale (~[-3e4,
    % 3e4]); the functionTransform sin(omega*x) applied below would then wrap
    % thousands of times and erase all class structure (held-out test AUC ~0.5).
    %
    % Two schemes (toggle parameters.data.normPerSample):
    %   per-SAMPLE  (previous method): each sample z-scored across its features.
    %   per-FEATURE (default): common per-feature standardization pooled over ALL
    %       samples of both classes (same mean/std to A and B -- uses no labels).
    if isfield(parameters.data, 'normPerSample') && parameters.data.normPerSample
        AData = (AData - mean(AData, 1)) ./ (std(AData, 0, 1) + eps);
        BData = (BData - mean(BData, 1)) ./ (std(BData, 0, 1) + eps);
    else
        Xall = [AData, BData];
        muF  = mean(Xall, 2);
        sgF  = std(Xall, 0, 2) + eps;
        AData = (AData - muF) ./ sgF;
        BData = (BData - muF) ./ sgF;
    end

    %Modify parameters to include number of eigenvalues for semisynthetic data
    k1backup = parameters.snapshots.k1;
    parameters.snapshots.k1 = parameters.synthetic.NKLTerms;
    
    % eigenvectors, values, functions and KL realizations for the true data.
    k = parameters.data.currentiter;
 
   
    rng(10000, 'philox');
    parameters.origB = snapshots1(BData, parameters,methods, ...
         parameters.synthetic.NTest + parameters.synthetic.Brs(k));

    rng(0, 'philox');
    parameters.origA = snapshots1(AData, parameters, methods, ...
        parameters.synthetic.NTest + parameters.synthetic.Ars(k));
    
    % save the realizations in the Datas structure
    Datas.rawdata.AData=parameters.origA.snapshots.realizations;
    Datas.rawdata.BData=parameters.origB.snapshots.realizations;

    %Apply functional transformation 
    if strcmp(parameters.synthetic.functionTransform, 'id'), functionTransform = @(x) x;
    elseif isnumeric(parameters.synthetic.functionTransform)
        functionTransform = @(x) sin(parameters.synthetic.functionTransform * x);
    else, error('parameters.synthetic.functionTransform must be ''id'' or a real scalar');
    end
    
    Datas.rawdata.AData = functionTransform(Datas.rawdata.AData);
    Datas.rawdata.BData = functionTransform(Datas.rawdata.BData);

    %Resotre parameter parameter.snapshots.k1
    parameters.snapshots.k1 = k1backup; 


    
        
end
