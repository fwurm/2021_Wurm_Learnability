function simulateData(modelstructure,para_sim,dir)

fprintf('   Model recovery procedure\n')
fprintf('      parameter fitting: %s\n',modelstructure.mode)
fprintf('      feedback type: %s\n',para_sim.fbtype);
fprintf('      number of samples: %d\n',modelstructure.nSample);

overwrite = 0; %default
nSample = modelstructure.nSample;
nModel = length(modelstructure.models);
for iModel = 1:nModel
    fprintf('   Calculating model %d\n',iModel)
    fprintf('      model: %s\n',modelstructure.models{iModel})
    
    fn_simulation = [dir.dir_simulation 'modelRecovery_data_' num2str(modelstructure.nSample) 'Samples_' modelstructure.mode '_' modelstructure.models{iModel} '.mat'];
    if exist(fn_simulation)
        promptinput = input('      File exists already. Overwrite? (y/n)>','s');
        if strcmp(promptinput,'n')
            display('      abort model simulation...')
        elseif strcmp(promptinput,'y')
            overwrite = 1;
            display('      proceed overwriting...')
        else
            error()
        end
    end
    
    if overwrite == 1 || ~exist(fn_simulation)
        
        %construct model
        [mstruct,~,~] = defineModel_gambLearn(modelstructure.models{iModel});
        
        %draw random samples for every simulated participant
        [paraspace] = sampleParameters(mstruct,modelstructure.nSample,modelstructure.mode);
        
        BEHdata = [];
        S = [];
        
        for iSample = 1:nSample
            
            %simulate environment
            [rew_payoff,rew_dichot,yoked,seq] = doWalk(para_sim);
            
            %build structure of environment
            if strcmp(para_sim.fbtype,'relpay')
                walk.r(:,:,1) = squeeze(rew_payoff(:,:,:));
                walk.r(:,:,2) = 100 - squeeze(rew_payoff(:,:,:));
            elseif strcmp(para_sim.fbtype,'dichot')
                walk.r(:,:,1) = rew_dichot;
                walk.r(:,:,2) = 1 - rew_dichot;
                walk.r = (walk.r.*2)-1;
            end
            walk.y = yoked; %task condition
            walk.s = seq; %stimulus pair\set sequence
            walk.info.type = para_sim.methodtype;
            walk.nS = para_sim.nSet;
            walk.nB = para_sim.nBlock;
            walk.nT = para_sim.nTrial;
            
            %simulate agent in environment
            data_sim = mstruct.funhandle(paraspace(:,iSample),walk);
            
            S(iSample).index = iSample;
            S(iSample).dir = dir.dir;
            
            BEHdata(iSample).VPname = ['Sim' num2str(iSample)];
            BEHdata(iSample).VPnum = iSample;
            BEHdata(iSample).dec = data_sim.c-1;
            BEHdata(iSample).rew = data_sim.r;
            BEHdata(iSample).yoked = data_sim.y;
            BEHdata(iSample).seq = data_sim.s;
            BEHdata(iSample).RT = nan;
            BEHdata(iSample).parameter = paraspace(:,iSample);
            
            gnu = 1;
            
        end
        
        fprintf('      saved as: %s\n',fn_simulation)
        save(fn_simulation,'BEHdata')
        
        nPara = size(paraspace,1);
        figure
        for iPara = 1:nPara
            subplot(1,nPara,iPara)
            hist(paraspace(iPara,:))
            title(mstruct.name(iPara))
        end
        
    end
    
end