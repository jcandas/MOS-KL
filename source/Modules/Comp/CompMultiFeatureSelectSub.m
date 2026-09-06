function array = CompMultiFeatureSelectSub(Datas, parameters, methods, results)

sz = size(results.array);
sz(1) = 1;
array = nan(sz);

Backup1 = Datas;

%for j = parameters.data.NBvals


parameters2 = parameters;
for j = parameters.data.NBvals
    parameters2.data.j = j;
    

    %% Apply both layers of filtering to data
    Datas2 = methods.all.prepdata(Datas, parameters2);% Split data into two groups: training and testing             
    Datas3 = methods.transform.tree(Datas2, parameters2, methods); % Compute Transformation K using training data, apply to training and validation data 
    
    Datas4 = methods.Multi2.SelectSVMFeatures(Datas3, parameters2, methods);
    

    %% Feature selection
    tic; t1 = toc;
    for l = 1:length(parameters.multilevel.Mres)
        parameters2.multilevel.iMres = parameters2.multilevel.Mres(l);
        Datas5 = methods.Multi2.OmitFeatures(Datas4, parameters2, methods); %Subselect Features
        Datas6 = methods.SVMonly.Prep(Datas5); %Prepare Training and Testing Data for SVM
        parameters3 = methods.SVMonly.fitSVM(Datas6, parameters2, methods); %Construct SVM 
        array(1,j,l,:,:) = methods.all.predict(Datas6, parameters3, methods); % Predict class value using transformed data
    t2 = toc;
    end
 
end

end

