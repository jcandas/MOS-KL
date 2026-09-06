function [Datas, parameters] = readData2(parameters, methods)



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



AData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeA)));
BData = table2array(T(:,startsWith(T.Properties.VariableNames, parameters.data.typeB)));

%if isempty(parameters.data.numofgene)
    parameters.data.numofgene = height(T);
%end



% normalization
if parameters.data.normalize == 1 
    AData = methods.all.normalizedata(AData); 
    BData = methods.all.normalizedata(BData); 
end

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
        % %Compute Sine Transform 
        % omega = parameters.synthetic.functionTransform;
        % if isnumeric(omega)
        %     %omega = str2double(omega);
        %     transformHandle = @(x) sin(omega*x);
        %     for CData = ["AData", "BData"]
        %         Datas.rawdata.(CData) = transformHandle(Datas.rawdata.(CData));
        %     end
        % end

    case 'Kfold'

        if isempty(parameters.Kfold), parameters.Kfold = ceil(NB / 10); end  
        parameters.data.NAvals = 1:floor(NA / parameters.Kfold);
        parameters.data.NBvals = 1:floor(NB/ parameters.Kfold);

    case 'Cross'
    
        
        if isempty(parameters.cross.NTestB), parameters.cross.NTestB = floor(NB*0.2); end
        if isempty(parameters.cross.NTestA), parameters.cross.NTestA = floor(NA*0.2); end

end


%% Choose only a subset of the pairs to hold out if the Kfold is sufficiently low
% if strcmp(parameters.data.validationType, 'Kfold')
% if parameters.Kfold < ceil(NB / 5)
%     NAvals = ceil(NA / 2);
%     NBvals = ceil(NB / 2);
%     %NAvals = ceil(NA / NB*10);
%     parameters.data.NAvals = 1:NAvals;
%     parameters.data.NBvals = 1:NBvals;
% end
% end

end