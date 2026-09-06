function Datas = MyUnitVarianceSample(Datas)
% MyUnitVarianceSample  Per-sample (per-observation) z-scoring: each sample is
% normalized across its own features. This is the "previous" normalization
% scheme (old readData normalized each sample at load), as opposed to the
% per-feature MyUnitVariance2. Because every column is scaled by its OWN mean
% and standard deviation, no statistics are shared across samples, so there is
% no train/test leakage.
%
% Data are stored feature-by-sample (D-by-N), so a sample is a column: the mean
% and std are taken over dim 1 (features).

for C = ["A", "B"], for Set = ["CovTraining", "Machine", "Testing"]
        X = Datas.(C).(Set);
        mu = mean(X, 1);
        sg = std(X, [], 1) + eps;
        Datas.(C).(Set) = (X - mu) ./ sg;
end, end

end
