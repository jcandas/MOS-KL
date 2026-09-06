function results = CompMultiACA3(Datas, parameters, methods, results)

if parameters.multilevel.svmonly == 3
    methods.Multi2.ConstructResidualSubspace = @ResidSubspace2;

end

end