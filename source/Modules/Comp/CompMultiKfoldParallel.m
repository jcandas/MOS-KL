function [results] = CompMultiKfoldParallel(Datas, parameters, methods, results, l)

% Fits every classifier in parameters.multilevel.Classifiers (SVM/MLP/ResNet3/
% ResNet30) at level l and stores each in its own dim-3 slot
% (c-1)*baseLevels + (l+1), matching the SlotLabels built in InitializeResults2.

Classifiers = parameters.multilevel.Classifiers;
nC = numel(Classifiers);
baseLevels = parameters.multilevel.l + 1;
if parameters.multilevel.chooseTrunc, baseLevels = 1; end

sz = size(results.array(:,:,l+1,:,:));
sz(3) = nC;                       % one dim-3 slice per classifier
array = nan(sz);

for i = parameters.data.NAvals

        parameters.data.i = i;

      parfor j = parameters.data.NBvals

            parameters2 = parameters;
            Datas2 = Datas;

            parameters2.data.j = j;

           %% Split data into two groups: training and testing
            [Datas3] = methods.all.prepdata(Datas2, parameters2, methods);

            %% Compute Transformation K using all training data, apply to training and validation data
            Datas4 = methods.transform.tree(Datas3, parameters2, methods);
            parameters3 = methods.Multi2.ChooseTruncations(Datas4, parameters2, methods);

            %% Balance Data and construct multi-level filter (classifier-independent)
            [Datas5, parameters5] = methods.Multi.Filter(Datas4, parameters3, methods);

            %% Fit each classifier on the same multilevel features and predict
            aj = nan(1, 1, nC, sz(4), sz(5));
            for c = 1:nC
                parameters5.multilevel.currentClassifier = Classifiers(c);
                [Datas6, parameters6] = methods.Multi.machine(Datas5, parameters5, methods, l);
                aj(1,1,c,:,:) = methods.all.predict(Datas6, parameters6, methods);
            end
            array(i,j,:,:,:) = aj;

        end


end

% scatter each classifier's slice into its (classifier x level) slot
for c = 1:nC
    results.array(:,:,(c-1)*baseLevels + (l+1),:,:) = array(:,:,c,:,:);
end
