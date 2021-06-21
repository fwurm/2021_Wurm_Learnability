function fitSimulatedData(modelstructure,para_sim,dir,mode4fit)

for iSample = 1:modelstructure.nSample
    S(iSample).index = iSample;
    S(iSample).dir = dir.dir;
end

outfix = [dir.dir_simulation datestr(now,'yyyy-mm-dd') '\'];
if ~exist(outfix, 'dir')
    fprintf('   Creating folder %s\n',outfix)
    mkdir(outfix);
end


recovinput = input('      Start model recovery?. (y/n)>','s');
if strcmp(recovinput,'y')
    fprintf('      starting model recovery...\n')
    
    
    for iModel = 1:length(modelstructure.models)
        
        %model that will be fitted to the data
        reconstructionModel = modelstructure.models{iModel};        
        [~,param,f] = defineModel_gambLearn(reconstructionModel);
        
                
        for jModel = 1:length(modelstructure.models)

            %model and data that will be used as input/data
            datamodel = modelstructure.models{jModel};            
            fn_input = [dir.dir_simulation 'modelRecovery_data_' num2str(modelstructure.nSample) 'Samples_' modelstructure.mode '_' datamodel '.mat'];
            load(fn_input)
            
            for i = 1:length(S)
                
                k = find([S.index]==S(i).index);
                
                %build data structure
                data(i).d = squeeze([BEHdata(k).dec])+1;
                data(i).y = squeeze([BEHdata(k).yoked]);
                data(i).s = squeeze([BEHdata(k).seq]);
                
                if strcmp(para_sim.fbtype,'relpay') %center around 0, with [-1 1]
                    data(i).r = (squeeze([BEHdata(k).rew])./50)-1;
                elseif strcmp(para_sim.fbtype,'dichot') %center around 0, with [-1 1]
                    %                 data(i).r = (squeeze([BEHdata(k).rew]).*2)-1;
                    data(i).r = squeeze([BEHdata(k).rew]);
                else
                    warning('no rewardscale specified')
                end
                
                data(i).rt = [BEHdata(k).RT]./1000; %not necessary for simulated data
                         
                data(i).nB = para_sim.nBlock;
                data(i).nT = para_sim.nTrial;
                data(i).N = para_sim.nTrial*para_sim.nBlock;
                data(i).nS = para_sim.nSet;
                data(i).info.type = para_sim.methodtype;
            end
            
            % run optimization
            fprintf('... Fitting RL model\n')
            fprintf('       Type: %s\n',reconstructionModel);
            fprintf('       Outprefix: %s\n','');
            
            if strcmp(mode4fit,'standard')
                results = mfit_optimize(f,param,data,modelstructure.nSeed);
            elseif strcmp(mode4fit,'parallel')
                results = mfit_optimize_parallel(f,param,data,modelstructure.nSeed);
            elseif strcmp(mode4fit,'hierarchical')
                %             results = mfit_optimize_hierarchical(f,param,data,modelstructure.nSeed,0);
                results = mfit_optimize_hierarchical(f,param,data,modelstructure.nSeed,1);  %parallel computing
            else
                error()
            end
            
            %
            
            
            outname = ['-to-data-' modelstructure.models{jModel} '-' num2str(modelstructure.nSample) 'Samples-'   modelstructure.mode];
            fn = [outfix 'fit_' mode4fit '_' reconstructionModel outname];
            
            fprintf('... Saving RL model\n')
            fprintf('    File: %s\n',fn)
            save(fn,'results')
            
            
            
        end
        
        
        gnu = 1;
    end
elseif strcmp(recovinput,'n')
    display('      aborting model recovery...')
else
    error()
end