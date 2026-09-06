function [Datas, parameters] = ResidSubspace4(Datas, parameters, methods)

%% Express Data in Class A eigenbasis
Datas = methods.Multi2.EigenbasisA(Datas, parameters, methods);

% Take residuals:
iMA = 1:parameters.snapshots.k1;
for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(set)(iMA, :) = [];
end, end

%% Express Data in Class B eigenbasis
Datas = methods.Multi2.EigenbasisB(Datas, parameters, methods);

% Flip Data (this is a weird technicality from how the OG multilevel basis function worked)
for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(set) = flipud(Datas.(C).(set));
end, end

end
