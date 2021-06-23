function batch_gamblearn_eeg()

% necessary GND file is provided in .\RPEs\LAprior-zsep\

% in order to replicate the results from Wurm, Walentowska, Ernst, Severo,
% Pourtois, Steinhauser (2021), download the preprocesses EEG data via 
% figshare.com (https://figshare.com/s/3fc4f009b16feb3eabcb). Unzip and
% change dir_data accordingly.

% This scripts requires following toolboxes to be installed (added to
% working directory):
%   - mfit (https://github.com/sjgershm/mfit.git)
%   - EEGLAB (https://github.com/sccn/eeglab.git)
%   - Mass Univariate ERP (https://github.com/dmgroppe/Mass_Univariate_ERP_Toolbox.git)


dir.dir = [pwd '\'];

dir.dir_data = 'D:\Experiment_data\GambLearn\TestData\'; %to be added

%%% Directories %%%
dir.dir_model = [dir.dir 'Models\'];
dir.dir_fits = [dir.dir 'Fits\'];
dir.dir_rpe = [dir.dir 'RPEs\'];

dir.mode = 'github'; %adapted for Github


%%% Add specific paths %%%
addpath('Routines\');
addpath('Models\');

%%% Add external toolboxes %%%
addpath('mfit\');
addpath('eeglab\'); 
addpath('Mass_Univariate_ERP_Toolbox\'); 

%%% generate structure with relevant path information
SCode = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
[S] = getS(SCode,dir);

%%% specify relevant models
models = {'freeLR-partial' 'freeIT-partial' 'mixture-partial'...
    'freeLR-full' 'freeIT-full' 'mixture-full' };

%%% model comparison (necessary for weighted average RPEs)
[mout_LAinformed, mout_BICinformed] = BEH_modelcomp_gambLearn(dir,models,'gambLearn_BEHdata');


%% Single-trial regression
options.fin_BEH = 'gambLearn_BEHdata';
options.nBlock = 10;
options.nSet = 4;
options.nRep = 16;
options.nTrial_learn = options.nRep*options.nSet;

%Laplace-informed weighted average
% model2regress = mout_LAinformed; %uses the PXP-weighted average for prediction errors 
% output = [dir.dir_rpe '\LAprior-zsep\'];

%freeLR model
model2regress = 'freeLR-full';
output = [dir.dir_rpe '\freeLR-zsep\'];

% EEG_singletrialregression(S,dir,options,model2regress,'sepzscore','out',output,'srate',125) %calculate single-trial regression



% foldername = 'LAprior-zsep'; model = 'pxpweight'; %Laplace-informed weighted average
foldername = 'freeLR-zsep'; model = 'freeLR-full'; %freeLR weighted average


EEG_buildGND(S,dir,options,model,foldername) %build the GND structure from the regression results

%load GND structure
fin = [dir.dir_rpe foldername '\GND-RPE-' model '.GND'];
load(fin,'-mat');
nperm = 10000; %number of permutations

%full regression model
for i = 1:7
    GND=clustGND(GND_rpe,i,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no');
end

%contrast valence*task
GND=clustGND(GND_rpe,8,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %learning task
GND=clustGND(GND_rpe,9,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %gambling task

%contrast surprise*task
GND=clustGND(GND_rpe,8,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %learning task
GND=clustGND(GND_rpe,9,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %gambling task

%contrast valence*surprise
GND=clustGND(GND_rpe,8,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %win feedback
GND=clustGND(GND_rpe,9,'time_wind',[0 1000],'thresh_p',.05,'alpha',.05,'n_perm',nperm,'exclude_chans',{'VOGa' 'VOGu' 'HOGl'},'save_GND','no'); %loss feedback





function [S] = getS(SCode,dir)
nS = length(SCode);
for iVP = 1:nS
    S(iVP).index = SCode(iVP);
    S(iVP).dir = dir.dir;
    S(iVP).dir_data = dir.dir_data;
    S(iVP).dir_model = dir.dir_model;
    S(iVP).dir_fits = dir.dir_fits;
    S(iVP).dir_rpe = dir.dir_rpe;   
    S(iVP).EEGdir = dir.dir_data;
    S(iVP).EEGfn = ['VP' num2str(SCode(iVP))];   
    S(iVP).suffix = '';
end
