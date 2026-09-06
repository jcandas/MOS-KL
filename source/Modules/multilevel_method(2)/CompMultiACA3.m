function results = CompMultiACA3(Datas, parameters, methods, results)

if parameters.multilevel.svmonly == 3
    methods.Multi2.ConstructResidualSubspace = @ResidSubspace3;
    results = CompMultiACA2(Datas, parameters, methods, results);
end

end