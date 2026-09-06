function parameters = filefunc2(parameters, methods)


%% Remove 'origA', 'origB', 'Training', 'Testing' fields from parameters (they're huge!)
bigFields = {'origA', 'origB', 'Training', 'Testing', 'AData', 'BData'};
for i = 1:length(bigFields)
    if isfield(parameters, bigFields{i})
    parameters = rmfield(parameters, bigFields{i});
    end
end


%% Tag containing validation type 

switch parameters.data.validationType
    case 'Synthetic'
        assert(parameters.parallel.on == 0, 'Make sure parameters.parallel.on is set to ''0'' if parameters.data.generealization is set to ''1''')


        split_tag = sprintf('%d_TrainingA_%d_TrainingB_%d_Testing', ...
                        parameters.synthetic.Ars(parameters.data.currentiter), ...
                        parameters.synthetic.Brs(parameters.data.currentiter), ...
                        parameters.synthetic.NTest);

            if strcmp(parameters.synthetic.functionTransform, 'id')
                str = 'id';
            elseif isnumeric(parameters.synthetic.functionTransform)
                str = sprintf('sin(%dx)', parameters.synthetic.functionTransform);
            else
                error('parameters.synthetic.functionTransform must be id or a real number');
            end

        split_tag = [split_tag, filesep, str];



    case 'Kfold'

        split_tag = sprintf('Leave_%d_out', parameters.Kfold);
       

    case 'Cross'

        split_tag = sprintf('%d_TrainingA_%d_TestingA_%d_TrainingB_%d_TestingB',...
                            parameters.data.A - parameters.cross.NTestA,...
                            parameters.data.B - parameters.cross.NTestB,...
                            parameters.cross.NTestA,...
                            parameters.cross.NTestB);


       
end

%% Tag containing Machine
switch parameters.svm.kernal
    case true, kern_tag = 'Radial';
    case false, kern_tag = 'Linear';
end

%% Tag containing filtering method (ML, None, or Class B Adapted)

switch parameters.multilevel.nested
    case 0, nest_tag = 'Unnested';
    case 1, nest_tag = 'Inner-Nesting';
    case 2, nest_tag = 'Outer-Nesting';
end


switch parameters.multilevel.svmonly
    case 0
        SFT_tag = ['MLS-', nest_tag];
    case 1
        SFT_tag = 'Benchmark'; 
        kern_tag = '';
        if parameters.misc.PCA, SFT_tag = 'Benchmark-PCA'; end
    case 2
        SFT_tag = sprintf('ACA-%s-%s', upper(parameters.multilevel.eigentag(1)), nest_tag);  
    case 3
        SFT_tag = 'Feat';  
    case 4
        SFT_tag = 'Ablations'; kern_tag = '';
end

%% Tag containing Truncation parameter
if ismember(parameters.multilevel.svmonly, [0,2])
    eigen_tag = sprintf('Eigen-%d', parameters.snapshots.k1);
else 
    eigen_tag = '';
end


%% Normalization Tag
switch parameters.data.normalize
    case 0, norm_tag = 'Unnormalized';
    case 1, norm_tag = 'Normalized';
end

%% Balance Tag
switch parameters.multilevel.splitTraining
    case true, balanced = 'Balanced';
    case false, balanced = 'Unbalanced';
end


%% Results Folder
switch parameters.multilevel.chooseTrunc
    case false
        MOEfldr = "Manual_Hyperparameter_Selection";
    case true
        MOEfldr = func2str(methods.Multi2.ChooseTruncations);
        MOEfldr = replace(MOEfldr, '@', '');
end

%% Create file name for results
dataname_string = {parameters.data.label, SFT_tag, kern_tag, eigen_tag, norm_tag};
dataname_string(cellfun(@isempty, dataname_string)) = [];
parameters.dataname = strjoin(dataname_string, '-');
parameters.dataname = [parameters.dataname '.mat'];


%% Create path for results
switch isTallMatrix(parameters, methods)
case true, rF = 'results2'; case false, rF = 'results2'; end

parameters.datafolder = fullfile('..', rF, MOEfldr, parameters.data.validationType, parameters.data.label, split_tag, balanced);

if ~isfolder(parameters.datafolder), mkdir(parameters.datafolder), end



end

function bool = isTallMatrix(parameters, methods)
M = nan([parameters.data.numofgene, parameters.data.A]);
bool = methods.Multi2.isTallMatrix(M);
end