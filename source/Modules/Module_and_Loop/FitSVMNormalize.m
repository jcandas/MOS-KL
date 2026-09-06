function [parameters] = FitSVMNormalize(Datas, parameters, methods)

SVMField = 'multilevel';
% switch parameters.multilevel.svmonly
%     case 1
%         SVMField = 'multilevel';
%     case 0
%         SVMField = 'multilevel';
%     case 2
%         SVMField = 'multilevel';
% end

if parameters.svm.kernal == 1
    [parameters.(SVMField).SVMModel] = methods.all.SVMmodel(Datas.X_Train, Datas.y_Train, ...
                                                    'KernelFunction', 'RBF', 'KernelScale', 'auto');
else
    [parameters.(SVMField).SVMModel] = methods.all.SVMmodel(Datas.X_Train, Datas.y_Train);%,...
end

parameters.(SVMField).SVMModel = fitSVMPosterior(parameters.(SVMField).SVMModel);

pr = predict(parameters.(SVMField).SVMModel, Datas.X_Train);

if ~parameters.parallel.on 
fprintf('\t Internal Accuracy: %0.2f\n', sum(pr == Datas.y_Train)/length(pr));
fprintf('\t Internal Precision: %0.2f\n', sum(pr & Datas.y_Train)/sum(Datas.y_Train));
end

close all
assert(~all(pr == 0) || ~all(pr == 1));