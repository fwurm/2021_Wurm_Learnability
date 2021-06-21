function batch_simulation


%%% Path %%%
dir.dir = [pwd '\'];
dir.dir_model = [dir.dir 'Models\'];
dir.dir_fits = [dir.dir 'Fits\'];
dir.dir_simulation = [dir.dir 'Simulation\'];
dir.setting = 'github'; %adapted for github
%adding model
addpath('Routines\');
addpath('Models\');
addpath('mfit\'); %add Gershman's mfit toolbox


models = {'freeLR-partial' 'freeIT-partial' 'mixture-partial'...
    'freeLR-full' 'freeIT-full' 'mixture-full' };
nSamples = 100; %number of simulated participants
nSeed = 15; %number of seeds for model fitting
mode = 'random'; %'empprior'




%% Data simulation 

%setting up the environment
envment.nBlock = 10; % number of blocks (= 2*x because of yoked design)
envment.nSet = 4; % number of sets per block
envment.nRepeat = 16; % number of repetitions for each set
envment.nTrial = envment.nSet*envment.nRepeat; % number of trials
envment.lowerBound = 1;
envment.upperBound = 99;
envment.walkMean = 0;
envment.walkStd = 10;
envment.fbtype = 'dichot'; %rewardscale: either 'dichot' or 'relpay'
envment.methodtype = 'simulation';
% rng(0,'twister'); %initialize the random number generator for replicability


%% Model recovery
agents.models = models;
agents.nSample = nSamples;
agents.mode = mode; 

% SIM_simulateData_gambLearn(agents,envment,dir)


%% model recovery

envment.methodtype = 'behavioral fit'; % just changing environment

%make new agents for model fitting
modrecov.models = models;
modrecov.nSample = nSamples;
modrecov.nSeed = nSeed;
modrecov.mode = 'random';

mode4fit = 'standard'; %'standard' 'hierarchical'

% SIM_parafit_gambLearn(modrecov,envment,dir,mode4fit)


%% confusion matrix
confopt.models = models;
confopt.nSample = nSamples;
confopt.mode = mode;

% when asked for folder name type '100samples-paper' to replicate plots from the paper
[cm] = SIM_prepConfusion(confopt,dir,'parallel_');


%plot the confusion matrix
fig1 = figure();
fig1.Units = 'normalized';
fig1.OuterPosition = [0 0.2 0.4 0.8];
subplotnames = {'BIC' 'AIC' 'PXP'};
for i = 1:3
    fig1 = plotSubConfusion(fig1,squeeze(cm(:,:,i)),i,subplotnames{i})
end
fig1.Color = 'w';



gnu = 1;

 

function fighandle = plotSubConfusion(fighandle,data,k,ttext)

% s = subplot(3,2,k);
s = subplot(1,3,k);
imagesc(data)
cmap = 1-gray(256);
colormap(cmap); 
for i = 1:size(data,1)
    for j = 1:size(data,2)
        t(j,i) = text(j,i, num2str(data(i,j), '%.2f'));
        if data(i,j) > 0.5
            t(j,i).Color = 'w';
        end
        t(j,i).HorizontalAlignment = 'center';
        t(j,i).VerticalAlignment = 'middle';      
    end
end

mnames = {'1' '2' '3' '4' '5' '6'};
s.XTick = [1:length(mnames)]; 
s.XTickLabel = mnames'; 
s.YTick = [1:length(mnames)];


s.FontSize = 12;
% set(t(cm(:,:,1)'>0.5), 'color', 'w')

title(ttext,'FontSize',12,'FontWeight','bold')

% if ismember(k,[5 6])
    xlabel('recovered model','FontSize',12)
% end

if ismember(k,[1 ]) %3 5
    ylabel('simulated model','FontSize',12)
else
    s.YTickLabel = {};
end




