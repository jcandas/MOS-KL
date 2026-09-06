function [Datas, parameters] = readData3(parameters, methods)



T = readtable(strcat(parameters.data.path, parameters.data.name));


if parameters.data.randomize
    rng(1000);
    T = T(randperm(height(T)), randperm(width(T)));
end

%My Additions============
%========================
labels = T.Properties.VariableNames;
labels = cellfun( @(str) regexprep(str,'[^a-zA-Z\s]',''), labels, 'UniformOutput', false);
labels = categorical(labels);
unique_labels = categories(labels);

[~,itypeA] = max(countcats(labels));
[~,itypeB] = min(countcats(labels));

parameters.data.typeA = unique_labels{itypeA};
parameters.data.typeB = unique_labels{itypeB};
%========================
%========================

% normalization
if parameters.data.normalize  
    T = methods.all.normalizedata(T);
end

AData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeA)));
BData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeB)));

%if isempty(parameters.data.numofgene)
    parameters.data.numofgene = height(T);
%end


Datas.rawdata.T = T;
Datas.rawdata.AData = AData;
Datas.rawdata.BData = BData;

NA = size(Datas.rawdata.AData,2);
NB = size(Datas.rawdata.BData,2); 
parameters.data.NAvals = 1;
parameters.data.NBvals = 1;
switch parameters.data.validationType
    case 'Synthetic'
        [Datas, parameters] = methods.Multi.generateData(Datas, methods, parameters);
        [Datas, parameters] = methods.all.corruptData(Datas, parameters, methods);
        

    case 'Kfold'

        if isempty(parameters.Kfold), parameters.Kfold = ceil(NB / 10); end  
        parameters.data.NAvals = 1:floor(NA / parameters.Kfold);
        parameters.data.NBvals = 1:floor(NB/ parameters.Kfold);

    case 'Cross'
    
        
        if isempty(parameters.cross.NTestB), parameters.cross.NTestB = floor(NB*0.2); end
        if isempty(parameters.cross.NTestA), parameters.cross.NTestA = floor(NA*0.2); end

end




end