function Datas = MyUnitBox2(Datas)

A = [Datas.A.CovTraining, Datas.B.CovTraining];
M = max(A, [], 2); m = min(A, [], 2);
midpoint = 0.5 * (m + M);
width = (M - m)/2;


for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
        Datas.(C).(Set) = (Datas.(C).(Set) - midpoint) ./ width;
end, end



end