function Datas = ProjectOntoT2(Datas, parameters, methods)

%% Construct a Basis of Clas B using the multilevel tree method and project the Class A and B machine data onto this basis

    XB = Datas.B.CovTraining - mean(Datas.B.CovTraining, 2);
    %XB = Datas.B.CovTraining;
    if ~methods.Multi2.isTallMatrix(Datas.B.CovTraining) 
        [U,~,~] = svd(XB);
       % U = fliplr(U);

        for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
            Datas.(C).(set) = U'*Datas.(C).(set);
        end, end

    

    else
        % for C = 'AB', for set = ["CovTraining", "Machine", "Testing"]
        %     Datas.(C).(set) = methods.Multi2.BinarySVD(XB, Datas.(C).(set));
        % end, end

        D2 = Datas;
        Yin = Datas2Cell(Datas);
        Yout = methods.Multi2.BinarySVD(XB, Yin);
        Datas = Datas2Cell(Yout);
        Datas.rawdata = D2.rawdata;
        Datas.A.Training = D2.A.Training;
        Datas.B.Training = D2.B.Training;


    end

end

function Cell = Datas2Cell(Datas)

if isstruct(Datas)
Cell = {Datas.A.CovTraining,...
    Datas.A.Machine,...
    Datas.A.Testing,...
    Datas.B.CovTraining,...
    Datas.B.Machine,...
    Datas.B.Testing};
elseif iscell(Datas)
    Cell.A.CovTraining = Datas{1};
    Cell.A.Machine = Datas{2};
    Cell.A.Testing = Datas{3};
    Cell.B.CovTraining = Datas{4};
    Cell.B.Machine = Datas{5};
    Cell.B.Testing = Datas{6};
end

end
