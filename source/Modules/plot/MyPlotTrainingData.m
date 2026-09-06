function MyPlotTrainingData(Datas, parameters)

if ~parameters.parallel.on 
    figure();
    iplot = 0;
    q = quantile(Datas.A.Machine(:),[0.2, 0.8]);
    for C = ["A", "B"], for Set = ["Machine", "Testing"]
            iplot = iplot + 1;
            subplot(2,2,iplot);
            imagesc(Datas.(C).(Set));
            title(C + " " + Set);
            colormap jet, colorbar; clim(q);
    end, end
%keyboard
end


end