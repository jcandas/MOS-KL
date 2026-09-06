function [results] = PrintResultsTxt(Datas, parameters, methods, results)

switch parameters.multilevel.chooseTrunc
    case false
        MOE = "Manual_Hyperparameter_Selection";
    case true
        MOE = func2str(methods.Multi2.ChooseTruncations);
end

folder = fullfile("..", "results", MOE, parameters.data.validationType,"txt_files");
if ~isfolder(folder), mkdir(folder), end

switch parameters.multilevel.svmonly
    case 2
        name = func2str(methods.Multi2.ConstructResidualSubspace) + ".txt";
    case 1
        name = parameters.misc.MachineList + ".txt";
end


file = fullfile(folder, name);
fID = fopen(file, "a+");


fprintf(fID, '%s\n', parameters.data.label);


fprintf(fID, 'Balanced: %d, ', parameters.multilevel.splitTraining);
fprintf(fID, 'Kernel: %d, ' , parameters.svm.kernal);
fprintf(fID, 'Threshold: %0.2f\n', parameters.multilevel.concentration);

for field = ["AUC", "accuracy", "precision", "recall", "specificity", "F1Score"]
fprintf(fID, '%s = %0.4f, ', field, results.(field));
end

%fprintf(fID, ' (AUC = %0.4f, acc = %0.4f, precA = %0.4f, precB = %0.4f)', ...
    %results.AUC, results.accuracy, results.precisionA, results.precisionB);
fprintf(fID, '\nRun Time: %s\n\n', results.run_time);
fclose(fID);


end