function Datas = SepFilter2(Datas, parameters, methods)



switch parameters.multilevel.eigentag
    case 'largest'
        iFeatures = 1:parameters.multilevel.iMres;
    case 'smallest'
        iFeatures = 1:parameters.data.numofgene;
        ndelete = parameters.data.numofgene - parameters.multilevel.iMres;
        iFeatures(1:ndelete) = [];
end

end