function fw_singletrial_revision(S,dir,options,models,separatezscore,varargin)

% modelspecs = {'eeg ~ rpe'; 'eeg ~ rpe'; 'eeg ~ Qval'; 'eeg ~ Qval'; 'eeg
% ~ rpe + valence'; 'eeg ~ rpe + valence'; 'eeg ~ Qval + valence'; 'eeg ~ Qval + valence'}; %revision
% modelspecs = {'eeg ~ rpe*valence'; 'eeg ~ rpe*valence'; 'eeg ~ Qval*valence'; 'eeg ~ Qval*valence'; 'eeg ~ rpe'; 'eeg ~ rpe';'eeg ~ Qval';'eeg ~ Qval';}; %revision-absolute
% modelspecs = {'eeg ~ (rpe+Qval)*valence'; 'eeg ~ (rpe+Qval)*valence';}; %revision-absolute-full
% modelspecs = {'eeg ~ rpe+Qval'; 'eeg ~ rpe+Qval';'eeg ~ absrpe+Qval'; 'eeg ~ absrpe+Qval';'eeg ~ rpe+absQval'; 'eeg ~ rpe+absQval';'eeg ~ rpe';'eeg ~ rpe'; 'eeg ~ Qval'; 'eeg ~ Qval'; 'eeg ~ valence'; 'eeg ~ valence'}; %revision-absolute-full
% modelspecs = {'eeg ~ valence+absrpe+Qval'; 'eeg ~ valence+absrpe+Qval'}; %revision-absolute-full
% modelspecs = {'eeg ~ task*(valence+absrpe)';'eeg ~ task*valence*absrpe';'eeg ~ absrpe';'eeg ~ absrpe';'eeg ~ absrpe';'eeg ~ absrpe'};

modelspecs = {'eeg ~ task*valence*absrpe'};
% modelspecs = {'eeg ~ task*valence*absrpe' 'eeg ~ valence' 'eeg ~ valence' 'eeg ~ absrpe' 'eeg ~ absrpe' 'eeg ~ absrpe' 'eeg ~ absrpe'};
model = 'mweight';



%define options
options.inprefix = '';
options.outprefix = '';
options.srate = [];

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
end



%% Read Behavioral data
filename = [dir.dir 'BEH\' options.fin_BEH '.mat'];
fprintf('   Load File: %s\n', filename);
load(filename);

%% Read parameter and weigh them accordingly (protected exceedance prob)
if ~isstr(models)
    a = cell(1,length(S));
    a = [];
    for iM = 1:length(models.mnames)
        filename2 = [dir.dir_rpe '\gambLearn_RPEs_subject_' models.mnames{iM} '.mat'];
        fprintf('   Load File: %s\n', filename2);
        load(filename2);
        rpes = {RPEs.RPEs};
        
        for iS = 1:length(S)
            rpejoint{iS}(:,iM) = rpes{iS};
        end
    end
    gnu = 1
    rpejoint_weight = cellfun(@(x) x*diag([models.pxp]),rpejoint,'UniformOutput',false);
    rpejoint_weightsum = cellfun(@(x) sum(x,2),rpejoint_weight,'UniformOutput',false);
    
    for iS = 1:length(S)
        rpesout{iS} = sum(rpejoint{iS}*diag(models.g(iS,:)),2);
    end
    
else
    filename2 = [dir.dir_rpe '\gambLearn_RPEs_subject_' models '.mat'];
    fprintf('   Load File: %s\n', filename2);
    load(filename2);
    rpesout = {RPEs.RPEs};
    
end

%% generate folder
if ~exist(options.outprefix, 'dir')
    mkdir(options.outprefix);
end

%reconstruct switch behavior
for iVP = 1:length(S)
    fn = [S(iVP).BEHdir  'outfile_gamblearn.txt'];
    rawdata = tdfread(fn);
    [~,switches] = calcCorrSwitch(S(iVP),rawdata,options);
    BEHdata(iVP).switch = switches;
end


%% necessary part for parallel computing toolbox
RPEvpnums = [RPEs.VPnum];
BEHvpnums = [BEHdata.VPnum];

rewarddata = {BEHdata.rew};
yokeddata = {BEHdata.yoked};
switchdata = {BEHdata.switch};

rpedata = rpesout;
% rpedata = rpejoint_weightsum;
qdata = {RPEs.Q_updated};
% qdata = {RPEs.Q_notupdated};

%% start regression
tic
% for iVP = 1:length(S)
parfor iVP = 1:length(S)
    
    t = [];
    mdl = [];
    out = struct();
    bvals = [];
    coefname = [];
    
    fprintf('#####################\n')
    fprintf('# Processing %s... #\n',S(iVP).EEGfn)
    fprintf('#####################\n')
    
    %% Read EEG data
    fn = [rs_mkDirs(options.inprefix,S.EEGdir) S(iVP).EEGfn '.set'];
    raw = pop_loadset('filename',fn,'filepath',S(iVP).EEGdir);
    trialnums = [raw.event.TrialNumber];
    
    if ~isempty(options.srate)
        raw = pop_resample(raw,options.srate);
    else
        fprintf('   No resampling applied\n')
    end
    
    
    %% Get valence and yoked info & construct identifier
    %select correct VP
    vpidx = find(RPEvpnums==S(iVP).index);
    vpidx2 = find(BEHvpnums==S(iVP).index);
    
    %valence
    valence = rewarddata{vpidx2};
    valence = reshape(valence',options.nTrial_learn*options.nBlock,1);
    valence = valence(trialnums);
    
    %condition
    yoked = yokeddata{vpidx2};
    yoked = reshape(yoked',options.nTrial_learn*options.nBlock,1);
    yoked = yoked(trialnums);
    task = yoked;
    task(task==1) = -1;
    task(task==0) = 1;
    learnident = ismember(yoked,0);
    gambident = ismember(yoked,1);
    
    %switching (switch = 1, stay = 0)
    switching = switchdata{vpidx};
    switching(switching==0) = -1;
    switching = switching(trialnums);
    
    %RPEs
    rpes = rpedata{vpidx};
    rpes = rpes(trialnums);
    absrpes = abs(rpes);
    
    %updated Qvalues
    Q_updated = qdata{vpidx};
    Q_updated = Q_updated(trialnums);
    absqval = abs(Q_updated);
    
    
    %get EEG 
    y_raw = double(squeeze(raw.data(:,:,:)));
    
    %prepare regressors
    x1 = rpes; 
    x2 = Q_updated; 
    x3 = absrpes;
    x4 = absqval;
    x5 = valence;
    x6 = switching;
    x7 = task;
    
        
    z1 = (rpes-nanmean(rpes))/nanstd(rpes);
    z2 = (Q_updated-nanmean(Q_updated))/nanstd(Q_updated);
    if separatezscore
      z3(learnident,1) = (absrpes(learnident)-nanmean(absrpes(learnident)))/nanstd(absrpes(learnident));
      z3(gambident,1) = (absrpes(gambident)-nanmean(absrpes(gambident)))/nanstd(absrpes(gambident));        
    else
      z3 = (absrpes-nanmean(absrpes))/nanstd(absrpes);  
    end
    z4 = (absqval-nanmean(absqval))/nanstd(absqval);
    z5 = (valence-nanmean(valence))/nanstd(valence);
    z6 = (switching-nanmean(switching))/nanstd(switching);
    z7 = (task-nanmean(task))/nanstd(task);

    
    
    nanident = ~isnan(x1);
    valident = ismember(valence,[-1 1]);
    taskident = ismember(task,[-1 1]);
    swtident = ismember(switching,[-1 1]);
    
    posident = ismember(valence,[1]);
    
    fprintf('Calculating multiple univariate regressions....\n Channel: ')
    
    
    
    for i = 1:raw.nbchan
        fprintf('%s, ',raw.chanlocs(i).labels)
        for j = 1:raw.pnts
            y = squeeze(y_raw(i,j,:));
            
            

%             t{1} = table(y(valident&taskident&nanident),z3(valident&taskident&nanident),z5(valident&taskident&nanident),z7(valident&taskident&nanident),'VariableNames',{'eeg','absrpe','valence','task'}); %learning task 
%             t{2} = table(y(valident&taskident&nanident),z3(valident&taskident&nanident),z5(valident&taskident&nanident),z7(valident&taskident&nanident),'VariableNames',{'eeg','absrpe','valence','task'}); %learning task 
%             t{3} = table(y(posident&learnident&nanident),z3(posident&learnident&nanident),z5(posident&learnident&nanident),'VariableNames',{'eeg','absrpe','valence'}); %gambling task    
%             t{4} = table(y(~posident&learnident&nanident),z3(~posident&learnident&nanident),z5(~posident&learnident&nanident),'VariableNames',{'eeg','absrpe','valence'}); %gambling task    
%             t{5} = table(y(posident&gambident&nanident),z3(posident&gambident&nanident),z5(posident&gambident&nanident),'VariableNames',{'eeg','absrpe','valence'}); %gambling task    
%             t{6} = table(y(~posident&gambident&nanident),z3(~posident&gambident&nanident),z5(~posident&gambident&nanident),'VariableNames',{'eeg','absrpe','valence'}); %gambling task    

              t{1} = table(y(valident&taskident&nanident),z3(valident&taskident&nanident),z5(valident&taskident&nanident),z7(valident&taskident&nanident),'VariableNames',{'eeg','absrpe','valence','task'}); %learning task 
              t{2} = table(y(valident&learnident&nanident),z5(valident&learnident&nanident),'VariableNames',{'eeg','valence'}); %learning task 
              t{3} = table(y(valident&gambident&nanident),z5(valident&gambident&nanident),'VariableNames',{'eeg','valence'}); %learning task 
              t{4} = table(y(valident&learnident&nanident),z3(valident&learnident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task 
              t{5} = table(y(valident&gambident&nanident),z3(valident&gambident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task 
              t{6} = table(y(posident&taskident&nanident),z3(posident&taskident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task 
              t{7} = table(y(~posident&taskident&nanident),z3(~posident&taskident&nanident),'VariableNames',{'eeg','absrpe'}); %learning task 
%               t{6} = table(y(swtident&valident&taskident&nanident),z3(swtident&valident&taskident&nanident),z5(swtident&valident&taskident&nanident),z7(swtident&valident&taskident&nanident),z6(swtident&valident&taskident&nanident),'VariableNames',{'eeg','absrpe','valence','task','switchBEH'}); %learning task 
            
            
            for k = 1:length(modelspecs)
                mdl{k} = fitglm(t{k},modelspecs{k},'Distribution','normal'); %fit regression
                bvals{k}(i,j,:) = table2array(mdl{k}.Coefficients(2:end,1)); %save beta values
            end
            gnu = 1;
            
        end 
        gnu = 1;
    end
    fprintf('\n')
    
    for m = 1:length(modelspecs)
        coefname{m} = mdl{m}.CoefficientNames(2:end);
    end
    
    fprintf('Constructing variable with regression values...\n')
    
    out.VPname = S(iVP).EEGfn;
    out.VPnum = S(iVP).index;
    out.modelspec = modelspecs;
%     out.rpemethod = 'standard';
%     out.rpemethod = 'absolute';
    out.rpemethod = 'zscored';
    out.bvals = bvals;
    out.coefname = coefname;
    out.times = raw.times;
    
    fprintf('Writing output variable...\n')
    
    fout = [options.outprefix 'singletrial-' S(iVP).EEGfn '-' model '.mat'];
    parsave(fout,out);    


    
    gnu = 1;
end
toc

gnu = 1;

    



