function [results] = CompAblation(Datas, parameters, methods, results)

    tic; t1 = toc;
    array = results.array;
    if parameters.parallel.on
        
        
        parfor i = parameters.data.NAvals
                parameters2 = parameters;
                parameters2.data.i = i;
                array(i,:,:,:,:,:) = methods.misc.AblationSub(Datas, parameters2, methods, results);
        end

    elseif ~parameters.parallel.on
       
        for i = parameters.data.NAvals
            parameters.data.i = i;
            array(i,:,:,:,:) = methods.misc.AblationSub(Datas, parameters, methods, results);
        end
    end

    t2 = toc; 
    fprintf('Elapsed Time: %0.3f s \n', 1000*(t2 - t1));

    results.array = array;
end