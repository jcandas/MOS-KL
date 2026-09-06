% Record the source root so the output folder is resolved portably.
setenv('PNAS_ROOT', fileparts(mfilename('fullpath')));

% Load QC dataset and filter for visit code 'bl'
% Raw downloads are read from source/data/ (place the two CSVs there).
qc = readtable(fullfile(getenv('PNAS_ROOT'), 'data', 'CruchagaLab_CSF_SOMAscan7k_Protein_matrix_postQC_20230620.csv'));
qc_bl = qc(strcmp(qc.VISCODE2, 'bl'), :);  % Keep only baseline rows

qc_bl = standardizeMissing(qc_bl, {'.','NaN'});  % Convert 'NaN' strings to real NaNs

% remove rows with all missing values
qc_bl = qc_bl(~all(ismissing(qc_bl), 2), :);
% Remove columns with all or one missing value
qc_bl = qc_bl(:, ~all(ismissing(qc_bl), 1));


% Load phenotype data and filter for visit code 'bl'
phenotype = readtable(fullfile(getenv('PNAS_ROOT'), 'data', 'adni_phenotype_bl.csv'));
phenotype_bl = phenotype(strcmp(phenotype.VISCODE, 'bl'), :);  % Keep only baseline rows

% Merge 'DX.bl' from phenotype into qc based on 'RID'
qc_bl_labelled = outerjoin(qc_bl, phenotype_bl(:, {'RID', 'DX_bl'}), 'Type','Left','Keys', 'RID', 'MergeKeys', true);
% Remove rows where 'DX_bl' is missing
qc_bl_labelled = qc_bl_labelled(~ismissing(qc_bl_labelled.DX_bl), :);

% Remove the first 7 columns (equivalent to keeping everything after 8th)
qc_bl_labelled(:, 1:7) = [];


% Move last column to the front
vars = qc_bl_labelled.Properties.VariableNames;
qc_bl_labelled = qc_bl_labelled(:, [end, 1:end-1]);

% Check for any missing values
if any(any(ismissing(qc_bl_labelled)))
    disp('Before imputation there are missing values');
else
    disp('There is no missing values, skip imputation');
end

% Imputation using KNN
[numRows, numCols] = size(qc_bl_labelled);
target = qc_bl_labelled{:,1};
features = qc_bl_labelled{:,2:end};

missingPercent = sum(ismissing(features))' / numRows * 100;
colsToDrop = find(missingPercent > 25); %Drop columns with >25% missing
features(:, colsToDrop) = [];

imputedFeatures = knnimpute(features', 5)';  % transpose trick

df_imputed = [table(target), array2table(imputedFeatures)];
%df_imputed.Properties.VariableNames = ...
%    [qc_bl_labelled.Properties.VariableNames(1), ...
%     featuresTable.Properties.VariableNames];

% Report group sizes for the four diagnostic groups used by the six tasks
for g = {'AD','CN','EMCI','LMCI'}
    fprintf('size of %s is %d .\n', g{1}, sum(strcmp(df_imputed.target, g{1})));
end

% Save the six pairwise datasets (matching methods.data.CSF_files)
generate_six_datasets(df_imputed);

% -------- Function definition --------
function generate_six_datasets(data)
    % Output directory: source/data/CSF_data (read by GetCommonParameters)
    outdir = fullfile(getenv('PNAS_ROOT'), 'data', 'CSF_data');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    % {output-name suffix, {group A, group B}} -- names match
    % methods.data.CSF_files = SOMAscan7k_KNNimputed_<suffix>
    pairs = { ...
        'AD_CN',     {'AD','CN'}; ...
        'AD_EMCI',   {'AD','EMCI'}; ...
        'AD_LMCI',   {'AD','LMCI'}; ...
        'CN_EMCI',   {'CN','EMCI'}; ...
        'CN_LMCI',   {'CN','LMCI'}; ...
        'EMCI_LMCI', {'EMCI','LMCI'} };

    for p = 1:size(pairs,1)
        sub = data(ismember(data.target, pairs{p,2}), :);
        T = rows2vars(sub);          % transpose -> rows = [label; features], cols = samples
        T = splitvars(T);
        T = T(:, 2:end);             % drop the rows2vars identifier column
        fname = ['SOMAscan7k_KNNimputed_' pairs{p,1} '.txt'];
        writetable(T, fullfile(outdir, fname), 'WriteVariableNames', false);
        fprintf('  wrote %s (%d samples)\n', fname, size(sub,1));
    end
    fprintf('All 6 CSF datasets generated successfully in %s\n', outdir);
end