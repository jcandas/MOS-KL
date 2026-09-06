clc;
clear all;
close all;


methods = DefineMethods;
methods.all.initialization = @InitializeParameters4;

MOE = arrayfun(@str2func, "MethodOfEllipsoids_" + string(8:11), 'UniformOutput', false);

DS = [methods.data.ADNI_files,...
     {'newAD'},...
     methods.data.CSF_files([1 3 5]),...
     {'GCM'}];

D = methods.all.ValuesTable('Name', DS,...
                            'Balance', {true, false},...
                            'Kernel', {true, false},...
                            'Eigenspace', {'smallest', 'largest'},...
                            'MOE', MOE,...
                            'Algorithm', {2,1});




for irow4 = 1:height(D)

parameters =  methods.all.initialization();
parameters.multilevel.splitTraining = D.Balance(irow4); 
parameters.svm.kernal = D.Kernel(irow4); 
parameters.multilevel.eigentag = D.Eigenspace{irow4}; 
parameters.multilevel.svmonly = D.Algorithm(irow4); 
methods.Multi2.ChooseTruncations = D.MOE{irow4};
parameters.data.label = D.Name{irow4};
parameters.data.name = [parameters.data.label '.txt'];
parameters = methods.data.GetCommonParameters(parameters, methods);

 t0 = tic;
 for k = 1:parameters.data.nk
     t1 = toc(t0);

      % Read Data
      parameters.data.currentiter=k; 
      [Datas, parameters] = methods.all.readcancerData(parameters, methods);     
      
      %Initialize Max Multilevel if need be.
      parameters = methods.all.GetMaxMultiLevel(Datas, parameters, methods);
    
      % Create results structure
      [results] = methods.all.iniresults(parameters);

     [parameters] = methods.all.Datasize(Datas, parameters);

     %Plot Data if handles are there
      if parameters.transform.createPlots
      if ~isempty(methods.transform.createPlot)
          for i = 1:length(methods.transform.createPlot)
              plotHandle = methods.transform.createPlot{i};
              plotHandle(Datas, parameters, methods);
          end
          return
      end
      end

     %Generate random genes
     
     % select random genes
     [Datas] = methods.all.selectgene(Datas, parameters.data.numofgene, parameters.data.B);


     
     switch parameters.multilevel.svmonly 
         case 1
         %SVM Only
         results = methods.SVMonly.CompSVMonly(methods, Datas, parameters, results);
         case 0
         % Multilevel Method with SVM
         results = methods.Multi.CompMulti(methods, Datas, parameters, results);
         %parameters = ResidDimensionForMOLS(Datas, parameters, methods);
         case 2
         %Trajan's Multilevel Method with SVM
         results = methods.Multi2.CompMulti(Datas, parameters, methods, results);
         case 3
         results = methods.Multi2.FeatureSelect(Datas, parameters, methods, results);
         case 4
         results = methods.misc.Ablations(Datas, parameters, methods, results);
             
     end

     
     results = methods.all.ComputeAccuracyAndPrecision(Datas, parameters, methods, results);

     t2 = toc(t0);
      
      results.run_time = duration(0,0,t2 - t1, 'Format', 'hh:mm:ss');
      results.creation_time = datetime;
      

     parameters = methods.all.filefunc(parameters, methods);
     parameters.data.irow = irow4;
     Datas.rawdata.AData = []; Datas.rawdata.BData = [];
     %PrintResultsTxt(Datas, parameters, methods, results);
     save(fullfile(parameters.datafolder,parameters.dataname), 'parameters', 'results', 'Datas');
     save('irow4.mat', 'irow4');
     clear Datas parameters results
     

     %%Parallel pool clean up
     delete(gcp('nocreate'));
     myCluster = parcluster('Processes');
     delete(myCluster.Jobs);
end

end
 

