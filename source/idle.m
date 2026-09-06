while true
    load irow2
    if irow2 >= 208
        break
    end
    disp(irow2/208);
    pause(300)
end

ComputeMcNemarTest;
plotSemisyntheticBaselines;
plotSemisynthetic;