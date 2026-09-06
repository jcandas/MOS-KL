function array = CompAblationSub(Datas, parameters, methods, results)

sz = size(results.array(1,:,:,:,:));
array = nan(sz);

%% Create a dictionary between the ablations and the arguments passed to fitcsvm
ip = @(str) strcmp(parameters.Ablation.List, str);

KernelArgs = cell(size(parameters.Ablation.List));

KernelArgs{...
    ip("2nd degree polynomial kernel")}...
    = {'KernelFunction', 'polynomial', 'PolynomialOrder', 2};

KernelArgs{...
    ip("Kernel scaling")}...
    = {'KernelScale', 'auto'};

KernelArgs{...
    ip("L1 quadratic programming solver")}...
    = {'Solver', 'L1QP'};

% KernelArgs{...
%     ip("10-fold cross validation")}...
%     = {'Kfold', 10};
% 
% KernelArgs{...
%     ip("5-fold cross validation")}...
%     = {'Kfold', 5};

KernelArgs{...
    ip("Box constraint = 10")}...
    = {'BoxConstraint', 10};

KernelArgs{...
    ip("Standardized")}...
    = {'Standardize', true};

KernelArgs{...
    ip("Delta gradient tolerance = $10^{-2}$")}...
    = {'DeltaGradientTolerance', 10e-2};


for iab = 1:length(parameters.Ablation.List)

    ablation = parameters.Ablation.List(iab);
    fprintf('\n %s \n', ablation);
    KernelArgsI = KernelArgs{ip(ablation)};

    %if iab == 4, keyboard, end
    for j = parameters.data.NBvals
        parameters.data.j = j;

        Datas = methods.all.prepdata(Datas, parameters);
        Datas = methods.transform.tree(Datas, parameters, methods);
        Datas = methods.misc.prep(Datas, parameters);       
        Datas = methods.SVMonly.Prep(Datas);
        %if j == 3, keyboard, end
        parameters.multilevel.SVMModel = fitcsvm(Datas.X_Train, Datas.y_Train, KernelArgsI{:});
        array(1,j,ip(ablation),:,:) = methods.all.predict(Datas, parameters, methods);

    end
end