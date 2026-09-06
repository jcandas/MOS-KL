function Datas = SepFilter4(Datas, parameters, methods)

Fend = min(parameters.multilevel.iMres, size(Datas.A.Machine, 1));
iFeatures = 1:Fend;
for C = 'AB', for field = ["Machine", "Testing"]
        Datas.(C).(field) = Datas.(C).(field)(iFeatures,:);
end,end

end