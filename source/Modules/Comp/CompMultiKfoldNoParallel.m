
function [results, Datas, parameters] = CompMultiKfoldNoParallel(Datas, parameters, methods, results, l)

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

        for j = parameters.data.NBvals

            parameters.data.j = j;

           %% Split data into two groups: training and testing
            [Datas2] = methods.all.prepdata(Datas, parameters, methods);

            %% Compute Transformation K using all training data, apply to training and validation data
            Datas3 = methods.transform.tree(Datas2, parameters, methods);
            parameters2 = methods.Multi2.ChooseTruncations(Datas3, parameters, methods);

            %% Balance Data and construct multi-level filter (classifier-independent)
            tic; t1 = toc;
            [Datas4, parameters3] = methods.Multi.Filter(Datas3, parameters2, methods);

            %% Fit each classifier on the same multilevel features and predict
            for c = 1:nC
                parameters3.multilevel.currentClassifier = Classifiers(c);
                [Datas5, parameters4] = methods.Multi.machine(Datas4, parameters3, methods, l);
                array(i,j,c,:,:) = methods.all.predict(Datas5, parameters4, methods);
            end
            t2 = toc;
            results.DimRunTime(l+1) = t2 - t1;

        end


end


% scatter each classifier's slice into its (classifier x level) slot
for c = 1:nC
    results.array(:,:,(c-1)*baseLevels + (l+1),:,:) = array(:,:,c,:,:);
end
