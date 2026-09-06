clc;
clear all;
close all;


methods = DefineMethods;
methods.all.initialization = @InitializeParameters3;

%MOE = arrayfun(@str2func, "MethodOfEllipsoids_" + string(8:11), 'UniformOutput', false);
CRS = {@MLSFCT_FCD, @MLSARNT_FCD}; 


DS = [methods.data.ADNI_files,...
     {'newAD'},...
     {'GCM'},...
     methods.data.CSF_files([1 3 5]),...
     ];

D = methods.all.ValuesTable(...'Noise', {5}, ...
                            'Noise', num2cell(0:0.1:0.5),...
                            'Balance', {true,false},...
                            'Kernel', {true,false},...
                            'Eigenspace', {'smallest', 'largest'},...
                            'Algorithm', {0,2,1}, ...
                            'Name', DS);


D(D.Balance & D.Kernel,:) = [];

for irow3 = 1:height(D) %irow = 41
parameters =  methods.all.initialization();
parameters.multilevel.splitTraining = D.Balance(irow3); %D{irow3,1};
parameters.svm.kernal = D.Kernel(irow3); %D{irow3,2};
parameters.multilevel.eigentag = D.Eigenspace{irow3}; % D{irow3,3};
parameters.multilevel.svmonly = D.Algorithm(irow3); %D{irow3,4};

parameters.data.label = D.Name{irow3};
parameters.data.name = [parameters.data.label '.txt'];
parameters.synthetic.GaussianNoiseFactor = D.Noise(irow3);

%methods.Multi2.ConstructResidualSubspace = D.CRS{irow3};
%parameters.multilevel.concentration = D.Threshold(irow3);

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
     parameters.data.irow = irow3;
     Datas.rawdata.AData = []; Datas.rawdata.BData = [];
     %PrintResultsTxt(Datas, parameters, methods, results);
     save(fullfile(parameters.datafolder,parameters.dataname), 'parameters', 'results', 'Datas');
     save('irow3.mat', 'irow3');
     


     %%Parallel pool clean up
     if parameters.parallel.on
     delete(gcp('nocreate'));
     myCluster = parcluster('Processes');
     delete(myCluster.Jobs);
     end

     clear Datas parameters results
end

end
 

