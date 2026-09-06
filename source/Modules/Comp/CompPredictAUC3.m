function array = CompPredictAUC3(Datas, parameters, methods)
    

[class_Test,scores] = methods.all.SVMpredict(parameters.multilevel.SVMModel, Datas.X_Test);
scores = scores(:,2);
NA = size(Datas.X_Test_A, 1); NB = size(Datas.X_Test_B,1);
labels = [zeros(NB, 1); ones(NA, 1)];


switch parameters.data.validationType
    case 'Synthetic', nY = 2*parameters.synthetic.NTest;
    case 'Cross', nY = parameters.cross.NTestA + parameters.cross.NTestB;
    case 'Kfold', nY = 2*parameters.Kfold;
end
numpad = nY - length(scores);

if numpad > 0
    padnan = @(x) padarray(x(:), [numpad, 0], nan, 'post');
    scores= padnan(scores);
    labels = padnan(labels);
end

array = [labels(:),scores(:), class_Test(:)] ;
array = reshape(array, [1,1,size(array)]);






end
