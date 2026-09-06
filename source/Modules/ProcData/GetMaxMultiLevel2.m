function parameters = GetMaxMultiLevel2(Datas, parameters, methods)

%% Get the dimension of each subspace W in the multilevel basis.
[U,~,~] = svds(Datas.rawdata.AData, parameters.snapshots.k1, 'largest');
[LevelSizes] = methods.Multi2.BinarySVD(U);


%% Get number of levels l
if isnumeric(parameters.multilevel.l)
        %Do nothing
elseif strcmp(parameters.multilevel.l, 'max')
    parameters.multilevel.l = length(LevelSizes)-1;
end

if parameters.multilevel.chooseTrunc    
    parameters.multilevel.l = 0;
end


%% Get the size of each residual subspace
switch parameters.multilevel.nested
        case 0 %not nested
            Mres_auto = LevelSizes;
        case 1 %inner nesting
            Mres_auto = cumsum(LevelSizes);        
        case 2 %outer nesting            
            Mres_auto = cumsum(LevelSizes, 'reverse');
end

if isempty(parameters.multilevel.Mres_auto)
    parameters.multilevel.Mres = parameters.multilevel.Mres_manual;
elseif strcmp(parameters.multilevel.Mres_auto, 'MLS')
    parameters.multilevel.Mres = [parameters.multilevel.Mres_manual, Mres_auto];
end

parameters.multilevel.Mres_auto = Mres_auto;
end