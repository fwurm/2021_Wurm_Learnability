function batch_gamblearn_behavior()


dir.dir = 'C:\Users\wurmf\Dropbox\GitHub\gambLearn_OS\';

%%% Directories %%%
dir.dir_model = [dir.dir 'Models\'];
dir.dir_fits = [dir.dir 'Fits\'];
dir.dir_rpe = [dir.dir 'RPEs\'];
dir.mode = 'github'; %adapted for Github

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
  
  
%% Model fitting
optionsim.type = 'behavioral fit';
optionsim.nstarts = 20;
optionsim.rewardscale = [0 1];
optionsim.nBlock = 10;
optionsim.nTrial_learn = 16*4;
optionsim.nSet = 4;
optionsim.nRep = 16;

% for iM = 1:length(models)
% 	BEH_parafit_gambLearn(S,'gambLearn_BEHdata',models{iM},optionsim)
% end

  
%% Model comparison
[mout_LAinformed, mout_BICinformed] = BEH_modelcomp_gambLearn(dir,models,'gambLearn_BEHdata');


%% Model simulation (to obtain RPEs which can be later used for regression)
options.type = 'simulation';
options.nSamples = 1;
options.nBlock = 10;
options.nSet = 4;
options.nRep = 16;
options.nTrial_learn = 16*4;
options.VPname = 'all';
options.VPnums = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
options.fin_BEH = 'gambLearn_BEHdata';

% for iM = 1:length(models)
% 	BEH_simulateVars_gambLearn(dir,models{iM},options)
% end








function [S] = getS(SCode,dir)

nS = length(SCode);
for iVP = 1:nS
    S(iVP).index = SCode(iVP);
    S(iVP).dir = dir.dir;
    S(iVP).dir_model = dir.dir_model;
    S(iVP).dir_fits = dir.dir_fits;
    S(iVP).dir_rpe = dir.dir_rpe;
    S(iVP).code = ['VP' num2str(SCode(iVP)) '_tested'];
    S(iVP).EEGfn = ['VP' num2str(SCode(iVP))];
    S(iVP).PROBdir = [dir.dir '\BEH\VP' num2str(SCode(iVP)) '\'];   
    S(iVP).suffix = '';
end

%%% Subsample for analysis %%%
cS = [1:nS];


