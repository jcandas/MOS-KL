function MergeManualMRESwMLSMres

folderpath = fullfile('..','results', 'Manual_Hyperparameter_Selection', 'Kfold', ...
    'SOMAscan7k_KNNimputed_EMCI_LMCI', '**', '*.mat');

X = dir(folderpath); 
X(matches({X.name}, [".", ".."])) = [];
for i = 5:length(X)
    objpath = fullfile(X(i).folder, X(i).name);
    Xobj = load(objpath);
    Zobj = Xobj;
    Zobj.parameters.multilevel.Mres = Zobj.parameters.multilevel.Mres_auto;

    Mres = [Zobj.parameters.multilevel.Mres_auto, Zobj.parameters.multilevel.Mres_manual];
    Mres = sort(Mres);
    isMres = ismember(Mres, Zobj.parameters.multilevel.Mres);
    for acc = ["AUC", "accuracy", "BalancedAccuracy"]
        if length(Zobj.results.(acc)) > length(Zobj.parameters.multilevel.Mres)
        Zobj.results.(acc) = Zobj.results.(acc)(isMres);
        end
    end
   
    save(objpath, '-struct', 'Zobj');
    
    %Test if successful
    load(objpath);
    disp(parameters.multilevel.Mres);
    % Additional processing can be added here if needed
end



        


end