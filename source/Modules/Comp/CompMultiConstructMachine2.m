function [Datas, parameters] = CompMultiConstructMachine2(Datas, parameters, methods, l)

            
            nLevels = parameters.multilevel.l;
            NFeatures = size(Datas.A.Machine,1);
            switch parameters.multilevel.nested
                case 0 %not nested
                    Mres = [0, parameters.multilevel.Mres_auto];
                    Mres = cumsum(Mres);
                    iFeatures = Mres(l+1)+1 : Mres(l + 2);
                case 1 %Inner nesting
                    Mres = [0, parameters.multilevel.Mres_auto];
                    iFeatures = 1 : Mres(l + 2); 
                case 2 %Outer nesting
                    Mres = parameters.multilevel.Mres_auto;
                    iFeatures = NFeatures:-1:(NFeatures - Mres(l+1)+1);
            end

            for C = 'AB', for set = ["Machine", "Testing"]
                    Datas.(C).(set) = Datas.(C).(set)(iFeatures,:);
            end, end
           
            %% Fit SVM
            Datas = methods.SVMonly.Prep(Datas);
            [parameters] = methods.SVMonly.fitSVM(Datas, parameters, methods);
           
end
