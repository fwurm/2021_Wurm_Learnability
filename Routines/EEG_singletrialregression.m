function fw_singletrial_revision(S,dir,options,models,varargin)

%define options
options.inprefix = '';
options.outprefix = '';
options.srate = [];
options.zscore = false;

for iVar = 1:length(varargin)
    if strcmp(varargin{iVar}, 'in')
        if length(varargin)>iVar
            options.inprefix = varargin{iVar+1};
        else
            disp('ERROR: Input for parameter ''inprefix'' is not valid!');
        end
    end
    if strcmp(varargin{iVar}, 'out')
        if length(varargin)>iVar
            options.outprefix = varargin{iVar+1};
        else
            disp('ERROR: Input for parameter ''outprefix'' is not valid!');
        end
    end
    if strcmp(varargin{iVar}, 'srate')
        if length(varargin)>iVar
            options.srate = varargin{iVar+1};
        else
            disp('ERROR: Input for parameter ''srate'' is not valid!');
        end
    end
    if strcmp(varargin{iVar}, 'sepzscore')
        options.zscore = true;
    end
end

% model specifications for regression
modelspecs = {'eeg ~ task*valence*absrpe' ...
    'eeg ~ valence' 'eeg ~ valence' ... %contrast task*valence
    'eeg ~ absrpe' 'eeg ~ absrpe' ... %contrast task*surprise
    'eeg ~ absrpe' 'eeg ~ absrpe'}; %contrast valence*surprise

% read behavioral data
filename = [dir.dir 'BEH\' options.fin_BEH '.mat'];
fprintf('   Load File: %s\n', filename);
load(filename);

% read estimated model variables 
if ~isstr(models) %multiple models input ==> calculate weighted average

    for iM = 1:length(models.mnames) %loop through models
        filename2 = [dir.dir_rpe '\gambLearn_RPEs_subject_' models.mnames{iM} '.mat'];
        fprintf('   Load File: %s\n', filename2);
        load(filename2);
        rpes = {RPEs.RPEs};
        
        for iS = 1:length(S)
            rpejoint{iS}(:,iM) = rpes{iS};
        end
    end
    
    %weight RPEs according to probabilites (sum to 1)
    rpejoint_weight = cellfun(@(x) x*diag([models.pxp]),rpejoint,'UniformOutput',false); %use protected exceedance probability
    rpejoint_weightsum = cellfun(@(x) sum(x,2),rpejoint_weight,'UniformOutput',false);
    
    for iS = 1:length(S)
        rpesout{iS} = sum(rpejoint{iS}*diag(models.g(iS,:)),2);
    end
    
    model = 'pxpweight';
    
else %single model input
    filename2 = [dir.dir_rpe '\gambLearn_RPEs_subject_' models '.mat'];
    fprintf('   Load File: %s\n', filename2);
    load(filename2);
    rpesout = {RPEs.RPEs};
    
    model = models;
    
end

% generate folder to save outputs
if ~exist(options.outprefix, 'dir')
    mkdir(options.outprefix);
end



% preparation for parallel computing toolbox
RPEvpnums = [RPEs.VPnum];
BEHvpnums = [BEHdata.VPnum];
rewarddata = {BEHdata.rew};
yokeddata = {BEHdata.yoked};
rpedata = rpesout;
qdata = {RPEs.Q_updated};


% start regression and loop through every participant
tic
parfor iVP = 1:length(S) %replace with for
    
    %initialize variables
    t = [];
    mdl = [];
    out = struct();
    bvals = [];
    coefname = [];
    
    fprintf('#####################\n')
    fprintf('# Processing %s... #\n',S(iVP).EEGfn)
    fprintf('#####################\n')
    
    % Read EEG data
    fn = [S(iVP).EEGfn '.set'];
    raw = pop_loadset('filename',fn,'filepath',[S(iVP).EEGdir options.inprefix]);
    
    trialnums = [raw.event.TrialNumber]; %trials left after preprocessing
    
    if ~isempty(options.srate)
        raw = pop_resample(raw,options.srate);
    else
        fprintf('   No resampling applied\n')
    end
    
    
    % Get valence and yoked info & construct identifier
    %select correct VP
    vpidxRPE = find(RPEvpnums==S(iVP).index);
    vpidxBEH = find(BEHvpnums==S(iVP).index);
    
    %valence
    valence = rewarddata{vpidxBEH};
    valence = reshape(valence',options.nTrial_learn*options.nBlock,1);
    valence = valence(trialnums);
    posident = ismember(valence,[1]);
    negident = ismember(valence,[-1]);
    
    %task condition
    yoked = yokeddata{vpidxBEH};
    yoked = reshape(yoked',options.nTrial_learn*options.nBlock,1);
    yoked = yoked(trialnums);
    task = yoked;
    task(task==1) = -1;
    task(task==0) = 1;
    learnident = ismember(yoked,0);
    gambident = ismember(yoked,1);
    
    %RPEs
    rpes = rpedata{vpidxRPE};
    rpes = rpes(trialnums);
    absrpes = abs(rpes);
    
    %updated Qvalues
    Q_updated = qdata{vpidxRPE};
    Q_updated = Q_updated(trialnums);
    absqval = abs(Q_updated);
       
    %get EEG signal
    y_raw = double(squeeze(raw.data(:,:,:)));
    
    %prepare standard regressors
    x1 = rpes; 
    x2 = Q_updated; 
    x3 = absrpes;
    x4 = absqval;
    x5 = valence;
    x6 = task;
    
    %prepare zscored regressors    
    z1 = (rpes-nanmean(rpes))/nanstd(rpes);
    z2 = (Q_updated-nanmean(Q_updated))/nanstd(Q_updated);
    if options.zscore %separate zscore for task condition
      z3(learnident,1) = (absrpes(learnident)-nanmean(absrpes(learnident)))/nanstd(absrpes(learnident));
      z3(gambident,1) = (absrpes(gambident)-nanmean(absrpes(gambident)))/nanstd(absrpes(gambident));        
    else
      z3 = (absrpes-nanmean(absrpes))/nanstd(absrpes);  
    end
    z4 = (absqval-nanmean(absqval))/nanstd(absqval);
    z5 = (valence-nanmean(valence))/nanstd(valence);
    z6 = (task-nanmean(task))/nanstd(task);

    
    % prepare to exclude nans etc.
    nanident = ~isnan(x1);
    valident = ismember(valence,[-1 1]);
    taskident = ismember(task,[-1 1]);

    
    
    fprintf('Calculating multiple univariate regressions....\n Channel: ')
    
    
    for i = 1:raw.nbchan %EEG channels        
        fprintf('%s, ',raw.chanlocs(i).labels)     
        for j = 1:raw.pnts %EEG timepoints

            y = squeeze(y_raw(i,j,:));
            
            %construct tables for GLM
            t{1} = table(y(valident&taskident&nanident),z3(valident&taskident&nanident),z5(valident&taskident&nanident),z6(valident&taskident&nanident),'VariableNames',{'eeg','absrpe','valence','task'}); %full regression model
            t{2} = table(y(valident&learnident&nanident),z5(valident&learnident&nanident),'VariableNames',{'eeg','valence'}); %learning task & valence
            t{3} = table(y(valident&gambident&nanident),z5(valident&gambident&nanident),'VariableNames',{'eeg','valence'}); %gambling task & valence
            t{4} = table(y(valident&learnident&nanident),z3(valident&learnident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task & surprise
            t{5} = table(y(valident&gambident&nanident),z3(valident&gambident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task & surprise
            t{6} = table(y(posident&taskident&nanident),z3(posident&taskident&nanident),'VariableNames',{'eeg','absrpe'}); %win feedback & surprise
            t{7} = table(y(negident&taskident&nanident),z3(negident&taskident&nanident),'VariableNames',{'eeg','absrpe'}); %loss feedback & surprise
                        
            for k = 1:length(modelspecs)
                mdl{k} = fitglm(t{k},modelspecs{k},'Distribution','normal'); %fit regression
                bvals{k}(i,j,:) = table2array(mdl{k}.Coefficients(2:end,1)); %save beta values
            end           
        end
    end
    fprintf('\n')
    
    %save names of coefficients
    for m = 1:length(modelspecs)
        coefname{m} = mdl{m}.CoefficientNames(2:end);
    end
    
    fprintf('Constructing variable with regression values...\n')
    
    out.VPname = S(iVP).EEGfn;
    out.VPnum = S(iVP).index;
    out.modelspec = modelspecs;
    out.rpemethod = 'zscored';
    out.bvals = bvals;
    out.coefname = coefname;
    out.times = raw.times;
    
    fprintf('Writing output variable...\n')
    
    fout = [options.outprefix 'singletrial-' S(iVP).EEGfn '-' model '.mat'];
    fw_parsave(fout,out);    
    
end
toc


    



