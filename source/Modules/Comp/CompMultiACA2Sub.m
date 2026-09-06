function array = CompMultiACA2Sub(Datas, parameters, methods, results)

sz = size(results.array);
sz(1) = 1;
array = nan(sz);

Backup1 = Datas;

%for j = parameters.data.NBvals

for j = parameters.data.NBvals
    parameters.data.j = j;
    

    %% Apply both layers of filtering to data
    Datas2 = methods.all.prepdata(Datas, parameters, methods);% Split data into two groups: training and testing             
    %MyPlotTrainingData(Datas2, parameters);
    Datas4 = methods.transform.tree(Datas2, parameters, methods); % Compute Transformation K using training data, apply to training and validation data 
    
    parameters2 = methods.Multi2.ChooseTruncations(Datas4, parameters, methods);
    [Datas5, parameters3] = methods.Multi2.ConstructResidualSubspace(Datas4, parameters2, methods); %Construct Filter
    %%MyPlotTrainingData(Datas5, parameters);
    

    %% Feature selection
    
    tic; t1 = toc;
    for l = 1:length(parameters.multilevel.Mres)
        parameters3.multilevel.iMres = parameters3.multilevel.Mres(l);
        
        Datas6 = methods.Multi2.SepFilter(Datas5, parameters3, methods); %Apply Filter 
        %MyPlotTrainingData(Datas6, parameters);
        
        Datas7 = methods.SVMonly.Prep(Datas6); %Prepare Training and Testing Data for SVM
        parameters4 = methods.SVMonly.fitSVM(Datas7, parameters3, methods); %Construct SVM 
        array(1,j,l,:,:) = methods.all.predict(Datas7, parameters4, methods); % Predict class value using transformed data
    t2 = toc;
            %Datas = Backup2;
    end
    
    %results.DimRunTime = t2 - t1;
    %Restore Datas
    %Datas = Backup1;
end

end

