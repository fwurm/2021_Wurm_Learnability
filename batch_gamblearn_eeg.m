function batch_gamblearn_review()

dir.dir = [pwd '\'];

dir.did_data = ''; %to be added

%%% Directories %%%
dir.dir_model = [dir.dir 'Models\'];
dir.dir_fits = [dir.dir 'Fits\'];
dir.dir_rpe = [dir.dir 'RPEs\'];
dir.mode = 'github'; %adapted for Github



dir.BEHdir = strcat(dir.dir_data, 'BEH\');
dir.EEGdir = strcat(dir.dir_data, 'EEG\');

dir.ERPdir = strcat(dir.dir_data, 'ERP\');


%%% Add specific paths %%%
addpath('Routines\');
addpath('Models\');
addpath('mfit\'); %add Gershman's mfit toolbox

%% Options
%structure with relevant task info and pointers
options.nBlock = 10;
options.nSet = 4;
options.nRep = 16;
options.nTrial_learn = 16*4;
options.VPname = 'all';
options.VPnums = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
options.fin_BEH = 'gambLearn_BEHdata';



%%% generate structure with relevant path information
SCode = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
[S] = getS(SCode,dir);

%%% specify relevant models
models = {'freeLR-partial' 'freeIT-partial' 'mixture-partial'...
    'freeLR-full' 'freeIT-full' 'mixture-full' };

%% Model comparison
[mout_LAinformed, mout_BICinformed] = BEH_modelcomp_gambLearn(dir,models,'gambLearn_BEHdata');


model2regress = mout_LAinformed; %uses the PXP-weighted average for prediction errors 
% model2regress = 'freeLR-partial'; %uses the model's specific prediction errors 


input = 'fbLocked_riche_';
output = [dir.dir_rpe '\LAprior-zsep\'];
EEG_singletrialregression(S,dir,options,model2regress,1,'in',input,'out',output,'srate',125)



% output = [dir.dir_rpe '\revision2-mixture-zsep\'];
% singletrial_revision_round2(S,dir,options,'combiRL-pers-fullUpdate',1,'in',input,'out',output,'srate',125)
% output = [dir.dir_rpe '\revision2-freeLR-zsep\'];
% singletrial_revision_round2(S,dir,options,'basicRL-freeLR-pers-fullUpdate',1,'in',input,'out',output,'srate',125)
% output = [dir.dir_rpe '\revision2-freeLR-zjoin\'];
% singletrial_revision_round2(S,dir,options,'basicRL-freeLR-pers-fullUpdate',0,'in',input,'out',output,'srate',125)
% output = [dir.dir_rpe '\revision2-freeIT-zsep\'];
% singletrial_revision_round2(S,dir,options,'basicRL-freeIT-pers-fullUpdate',1,'in',input,'out',output,'srate',125)

input = 'fbLocked_riche_';
% output = [dir.dir_rpe '\revision2-LAprior-gweight-noZ\'];
% singletrial_revision_round2_noZ(S,dir,options,mout,'in',input,'out',output,'srate',125)
% output = [dir.dir_rpe '\revision2-BICprior-gweight-noZ\'];
% singletrial_revision_round2_noZ(S,dir,options,mout2,'in',input,'out',output,'srate',125)


% method = 'revision2-mweight-zseprt';
% method = 'revision2-mweight-zjoint';
% method = 'revision2-LAprior-gweight-zsep';
method = 'revision2-gweight-zjoint';
% method = 'revision2-BICprior-gweight-zseprt';
% method = 'revision2-BICprior-gweight-zjoint';
% method = 'revision2-LAprior-gweight-noZ';
% method = 'revision2-BICprior-gweight-noZ';
% method = 'revision2-mixture-zsep';
% method = 'revision2-freeLR-zsep';
% method = 'revision2-freeIT-zsep';
method = 'revision2-gweight-zjoint';
method = 'revision2-freeLR-zjoin';

model = 'mweight';

singletrial_buildEEG(S,options,model,method)
singletrial_buildGND(S,dir,options,model,method)

fin = [dir.dir_rpe method '\GND-RPE-' model '-' method '.GND'];
load(fin,'-mat');

weights = 'RPEweights';
outprefixes = {'RL-fullByRPE' 'RLvalence-learn' 'RLvalence-gamb' 'RLsurprise-learn' 'RLsurprise-gamb' 'RLsurprise-win' 'RLsurprise-los' };
folder = [dir.dir_rpe '\' method '\'];
nperm = 10000;

GND=clustGND(GND_rpe,6,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,10,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,11,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,12,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,13,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');

%% valence effect topographies
contrasts = [2 8 9];
timepoint = 300;
for i = 1:length(contrasts)
    clear GND
    GND=clustGND(GND_rpe,contrasts(i),'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
    tpnts = GND.time_pts(GND.t_tests.used_tpt_ids);
    chans = GND.t_tests.include_chans;
    tidx = dsearchn(tpnts',timepoint);
    posclust = find(GND.t_tests.clust_info.pos_clust_pval<0.05);
    if ~isempty(posclust)
        cident_pos = ismember(GND.t_tests.clust_info.pos_clust_ids(:,tidx),posclust);  
        sigchans_pos{i} = chans(cident_pos);
    else
        sigchans_pos{i} = {};
    end
    negclust = find(GND.t_tests.clust_info.neg_clust_pval<0.05);
    if ~isempty(negclust)
        cident_neg = ismember(GND.t_tests.clust_info.neg_clust_ids(:,tidx),negclust);  
        sigchans_neg{i} = chans(cident_neg);
    else
        sigchans_neg{i} = {};
    end
    
    gnu = 1;
end

AVGcons1 = {[weights '-' model '-' method '-' outprefixes{1} '-valence'] ...
    [weights '-' model '-' method '-' outprefixes{2} '-valence']...
    [weights '-' model '-' method '-' outprefixes{3} '-valence']}; %rpe

visual_topoplot_cluster2(AVGcons1 ,sigchans_pos,sigchans_neg,folder, timepoint ,[-2 2])


%% surprise*task effect topographies
sigchans_pos = [];
sigchans_neg = [];
contrasts = [5 10 11];
timepoint = 400;
for i = 1:length(contrasts)
    clear GND
    GND=clustGND(GND_rpe,contrasts(i),'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
    tpnts = GND.time_pts(GND.t_tests.used_tpt_ids);
    chans = GND.t_tests.include_chans;
    tidx = dsearchn(tpnts',timepoint);
    posclust = find(GND.t_tests.clust_info.pos_clust_pval<0.05);
    if ~isempty(posclust)
        cident_pos = ismember(GND.t_tests.clust_info.pos_clust_ids(:,tidx),posclust);  
        sigchans_pos{i} = chans(cident_pos);
    else
        sigchans_pos{i} = {};
    end
    negclust = find(GND.t_tests.clust_info.neg_clust_pval<0.05);
    if ~isempty(negclust)
        cident_neg = ismember(GND.t_tests.clust_info.neg_clust_ids(:,tidx),negclust);  
        sigchans_neg{i} = chans(cident_neg);
    else
        sigchans_neg{i} = {};
    end
    
    gnu = 1;
end

AVGcons1 = {[weights '-' model '-' method '-' outprefixes{1} '-absrpeBytask'] ...
    [weights '-' model '-' method '-' outprefixes{4} '-absrpe']...
    [weights '-' model '-' method '-' outprefixes{5} '-absrpe']}; %rpe

visual_topoplot_cluster2(AVGcons1 ,sigchans_pos,sigchans_neg,folder, timepoint ,[-1 1])

%% surprise*valence effect topographies
sigchans_pos = [];
sigchans_neg = [];
contrasts = [4 12 13];
timepoint = 300;
for i = 1:length(contrasts)
    clear GND
    GND=clustGND(GND_rpe,contrasts(i),'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
    tpnts = GND.time_pts(GND.t_tests.used_tpt_ids);
    chans = GND.t_tests.include_chans;
    tidx = dsearchn(tpnts',timepoint);
    posclust = find(GND.t_tests.clust_info.pos_clust_pval<0.05);
    if ~isempty(posclust)
        cident_pos = ismember(GND.t_tests.clust_info.pos_clust_ids(:,tidx),posclust);  
        sigchans_pos{i} = chans(cident_pos);
    else
        sigchans_pos{i} = {};
    end
    negclust = find(GND.t_tests.clust_info.neg_clust_pval<0.05);
    if ~isempty(negclust)
        cident_neg = ismember(GND.t_tests.clust_info.neg_clust_ids(:,tidx),negclust);  
        sigchans_neg{i} = chans(cident_neg);
    else
        sigchans_neg{i} = {};
    end
    
    gnu = 1;
end

AVGcons1 = {[weights '-' model '-' method '-' outprefixes{1} '-absrpeByvalence'] ...
    [weights '-' model '-' method '-' outprefixes{6} '-absrpe']...
    [weights '-' model '-' method '-' outprefixes{7} '-absrpe']}; %rpe
visual_topoplot_cluster2(AVGcons1 ,sigchans_pos,sigchans_neg,folder, timepoint ,[-1 1])


AVGcons1 = {[weights '-' model '-' method '-' outprefixes{2} '-valence'] ...
    [weights '-' model '-' method '-' outprefixes{3} '-valence']}
visual_comperp(AVGcons1, folder,'channels',[1:67]);

AVGcons1 = {[weights '-' model '-' method '-' outprefixes{4} '-absrpe'] ...
    [weights '-' model '-' method '-' outprefixes{5} '-absrpe']}
visual_comperp(AVGcons1, folder,'channels',[1:67]);

AVGcons1 = {[weights '-' model '-' method '-' outprefixes{6} '-absrpe'] ...
    [weights '-' model '-' method '-' outprefixes{7} '-absrpe']}
visual_comperp(AVGcons1, folder,'channels',[1:67]);










% GND=clustGND(GND_rpe,5,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',2500,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,8,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',2500,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
GND=clustGND(GND_rpe,9,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',2500,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');




% for i = 1:7
for i = 1:13
    GND=clustGND(GND_rpe,i,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',2500,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
end


folder = [dir.dir_rpe '\' method '\'];
weights = 'RPEweights';
outprefixes = {'RL-fullByRPE'};
AVGcons1 = {[weights '-' model '-' method '-' outprefixes{1} '-absRPE'] [weights '-' model '-' method '-' outprefixes{1} '-valence'] ...
    [weights '-' model '-' method '-' outprefixes{1} '-task'] [weights '-' model '-' method '-' outprefixes{1} '-absrpeBytask'] ...
    [weights '-' model '-' method '-' outprefixes{1} '-absrpeByvalence'] [weights '-' model '-' method '-' outprefixes{1} '-valenceBytask'] ...
    [weights '-' model '-' method '-' outprefixes{1} '-absrpeByvalenceBytask']}; %rpe
% visual_topoplot(AVGcons1,folder, [50:100:750], [-1 1], 'mean', 100);
visual_comperp(AVGcons1, folder,'channels',[1:67]);



%% Behavioral analysis and preprocessing
info.nB = 10;
info.nR = 16; % #repetitions per block/pair
info.nP = 4;  % #pairs per block
info.nT = info.nR*info.nP; % #trials per block
info.fin_BEH = ['outfile_gamblearn']; %file with behavioral data

% prepBEHdata_gambLearn(S,info) %for EEG
% saveBEHdata_gambLearn(S,info,'gambLearn') %for model & behavioral
% analyzeBEHdata_gambLearn(S,info)
% analyzeBEHdata_gambLearn_catch(S,info)

% analyzeBEHdata_gambLearn_questionnaire(S)








function [S] = getS(SCode,dir)

nS = length(SCode);
for iVP = 1:nS
    S(iVP).index = SCode(iVP);
    S(iVP).dir = dir.dir;
    S(iVP).dir_data = dir.dir_data;
    S(iVP).dir_model = dir.dir_model;
    S(iVP).dir_fits = dir.dir_fits;
    S(iVP).dir_rpe = dir.dir_rpe;
    S(iVP).dir_switch = dir.dir_switch;
    S(iVP).EEGdir = dir.EEGdir;
    S(iVP).ERPdir = dir.ERPdir;
    S(iVP).TFAdir = dir.TFAdir;
    %     S(iVP).EYEdir = dir.EYEdir;
    S(iVP).BEHdir_agg = [dir.BEHdir '\Aggregated\'];
    S(iVP).code = ['VP' num2str(SCode(iVP)) '_tested'];
    S(iVP).EEGfn = ['VP' num2str(SCode(iVP))];
    S(iVP).BEHdir = [dir.BEHdir '\VP' num2str(SCode(iVP)) '_tested\'];
    S(iVP).PROBdir = [dir.dir '\BEH\VP' num2str(SCode(iVP)) '\'];
    
    S(iVP).suffix = '';
end

%%% Subsample for analysis %%%
cS = [1:nS];


function out = loadTFparameters()

% Time-Frequency Parameter stuff
out.min_freq =  1;
out.max_freq = 50;
out.num_frex = 50;
out.frex = logspace(log10(out.min_freq),log10(out.max_freq),out.num_frex);
out.num_cycl = 4; % Important!!!
out.plot = 0;
out.win = [-500 1000];
out.baselinetype = ['decBase'];
% fftoptions.baselinetype = [];
out.baselinewin = [-300 -200];
out.s =  out.num_cycl./(2*pi*out.frex); % standard deviation of Gaussian for Morlet Wavelet