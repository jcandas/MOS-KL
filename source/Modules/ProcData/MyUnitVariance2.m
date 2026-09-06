function Datas = MyUnitVariance2(Datas)

A = [Datas.A.Training, Datas.B.Training];
mu = mean(A,2);
sigma = std(A,[],2);

for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set) = (Datas.(C).(Set) - mu) ./ sigma;
end, end



end