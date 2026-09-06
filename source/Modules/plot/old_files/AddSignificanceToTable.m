function AddSignificanceToTable

TablePath = fullfile('..','results', 'Manual_Hyperparameter_Selection', 'Kfold', 'Graphs');
fileID = fopen(fullfile(TablePath, 'Performance_Table.tex'));

continueReading = true;
AlgoPattern = ("MLS"|"ACA-L""ACA-S"|"SVM"|"Boost/Bag");
PerformanceMatrix = [];
while continueReading
    currentLine = fgetl(fileID);
    disp(currentLine)
    if startsWith(currentLine, AlgoPattern)
        PMrow = extract(currentLine, ("0." + digitsPattern(3)));
        PMrow = cellfun(@str2num, PMrow);
    end
    if isnumeric(currentLine)
        continueReading = currentLine == -1;
    end

end

end