function fw_simBEH(dir,model,options)

fprintf('Simulating model parameters for model ''%s''...\n',model)

%load behavioral data
load([dir.dir 'BEH\' options.fin_BEH '.mat'])

VPind = [options.VPnums];

%load VP fits
load([dir.dir 'Fits\fit_gambLearn_' model '.mat'])

[~,~,f] = defineModel_gambLearn(model);

%simulate data based on fits
for i = 1:length(VPind)
    
    %participant index
    k = find([BEHdata.VPnum] == VPind(i));
    
    %contstruct data for model
    walk.r = [BEHdata(k).rew];
    walk.d = [BEHdata(k).dec]+1;
    walk.rt = [BEHdata(k).RT];
    walk.s = [BEHdata(k).seq];
    walk.y = [BEHdata(k).yoked];
    walk.nT = options.nTrial_learn;
    walk.nB = options.nBlock;
    walk.nS = options.nSet;
    walk.N = options.nBlock*options.nTrial_learn;
    walk.info = options;
    
    %get fit parameter
    param = squeeze([results.x(VPind(k),:)]);
    
    %simulate data
    data = f(param,walk);
    
    %get outputs
    rpes = reshape([data.rpe]',prod(size(data.rpe)),1);
    Q_updated = reshape([data.Q_updated]',prod(size(data.Q_updated)),1);  
    Q_notupdated = reshape([data.Q_notupdated]',prod(size(data.Q_notupdated)),1);  
    
    %assign outputs to structure
    RPEs(i).VPname = BEHdata(k).VPname;
    RPEs(i).VPnum = BEHdata(k).VPnum;
    RPEs(i).RPEs = rpes;
    RPEs(i).Q_updated = Q_updated;
    RPEs(i).Q_notupdated = Q_notupdated;
    
    gnu = 1;
end

%save outputs of all participants
fprintf('   Saving model parameters...\n')
fout = [dir.dir_rpe 'gambLearn_RPEs_subject_' model '.mat'];
save(fout,'RPEs')