function [Datas, parameters] = CompMultiConstructFilter3(Datas, parameters, methods)

[U,~,~] = svds(Datas.A.CovTraining, parameters.snapshots.k1,'largest');


for C = 'AB', for set = ["Machine", "Testing"]
    Datas.(C).(set) = methods.Multi2.BinarySVD(U, Datas.(C).(set));
    Datas.(C).(set)(1:parameters.snapshots.k1,:) = [];
end, end

end

function Cell = Datas2Cell(Datas)

if isstruct(Datas)
Cell = {...
    Datas.A.Testing,...
    Datas.B.CovTraining,...
    Datas.B.Machine,...
    Datas.B.Testing};
elseif iscell(Datas)
    Cell.A.Machine = Datas{1};
    Cell.A.Testing = Datas{2};
    Cell.B.Machine = Datas{3};
    Cell.B.Testing = Datas{4};
end

end


