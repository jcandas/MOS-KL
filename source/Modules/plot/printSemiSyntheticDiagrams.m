function printSemiSyntheticDiagrams

%% Get Folder Ingredients
folder = fullfile("..", "results", "Manual_Hyperparameter_Selection", "Synthetic", "Graphs", "tex_files");
if ~isfolder(folder), mkdir(folder); end
%name = "Synthetic_Diagrams.tex";

%fID = fopen(fullfile(folder, name), "w+");

%% Define iterates
methods = DefineMethods;
DS = string(methods.data.all_files);
DS = string(DS([1:6, 8, 10]));
DS2(1:2) = ["GCM", "newAD"];
DS2(3:5) = "ADNI (" + ["AD", "AD", "CN"] + " vs. " + ["CN", "LMCI", "LMCI"] + ")";
DS2(6:8) = "CSF (" + ["AD", "AD", "CN"] + " vs. " + ["CN", "LMCI", "LMCI"] + ")";


transforms = arrayfun(@(x) replace(sprintf("Noise_%0.g", x),'.', '_'),5*10.^[-5,-4,-3]);
transforms = ["id", transforms];
transforms2 = ["0", "5e-0" + ["5", "4", "3"]];

for ids = 1:length(DS)
    name = DS(ids) + "_corruptions.tex";
    path = fullfile(folder, name);
    fID = fopen(path, "w+");

    %% Print Header
    fprintf(fID, ['\\begin{figure}[h]\n',...
    '\\centering\n',...
    '\\caption{AUC and accuracy for each FINDER method + highest ',...
    'performing benchmark for quasi-bootstrapped %s data set.} \n'],...
    DS2(ids));

    %% Open fbox
    fprintf(fID, ['\\setlength{\\fboxrule}{0.25pt}',...
		'\\setlength{\\fboxsep}{2pt}',...
		'\\fbox{\n\n']);

for it = 1:length(transforms)

    %% Print subfigure 
    fprintf(fID, ['\\begin{subfigure}[b]{0.35\\textwidth}\n',...
        '\\centering\n',...
        '\\includegraphics[height=0.27\\textheight]\n',...
        '{Visualizing_Corruption/%s_%s_Synthetic.pdf}\n',...
        '\\caption*{\\texttt{sc} = %s}\n',...
        '\\end{subfigure}\n',...
        ], DS(ids), transforms(it), transforms2(it));
end

    %% Close fbox
    fprintf(fID, '}\n\n');

    %% Figure Footer
    fprintf(fID, ['\\label{%s_QB}\n',...
        '\\end{figure}'], DS(ids));

    fclose(fID);

end



end