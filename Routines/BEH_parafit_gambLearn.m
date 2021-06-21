function fw_parafit(S,fn,model,options,varargin)
% S - VP structure
% fn - filename for data
% model - filename for model

%% information on model
infopt.type = options.type;
infopt.nstarts = options.nstarts;    % number of random parameter initializations
infopt.rewardscale = options.rewardscale;


outprefix = '';

for i = 1:length(varargin)
    if strcmp(varargin{i}, 'out')
        if length(varargin)>i
            outprefix = ['_' varargin{i+1}];
        else
            disp('ERROR: Input for parameter ''outprefix'' is not valid!');
        end
    end
    if strcmp(varargin{i}, 'block')
        if length(varargin)>i
            block = varargin{i+1};
        else
            disp('ERROR: Input for parameter ''block'' is not valid!');
        end
    end
end


load([S(1).dir 'BEH\' fn '.mat'])

if length(S) ~= size([BEHdata.dec],2)./size([BEHdata(1).dec],2)
    warning('#VP mismatch')
end

%build parameter structure (taken from Gershman example)
[~,param,f] = defineModel_gambLearn(model);
   

%build data structure
VPs = [BEHdata.VPnum];
for i = 1:length(S)
    
    k = find(VPs==S(i).index);
    
        data(i).d = squeeze([BEHdata(k).dec])+1;
        data(i).r = squeeze([BEHdata(k).rew]);
        data(i).rt = squeeze([BEHdata(k).RT]);
        data(i).s = squeeze([BEHdata(k).seq]);
        data(i).y = squeeze([BEHdata(k).yoked]);
        data(i).nT = options.nTrial_learn;
        data(i).nB = options.nBlock;
        data(i).nS = options.nSet;
        data(i).N = options.nBlock*options.nTrial_learn;
        data(i).info = infopt;
        
end

% run optimization
fprintf('... Fitting RL model\n')
fprintf('       Type: %s\n',model);
fprintf('       Outprefix: %s\n',outprefix);

% results = mfit_optimize(f,param,data,infopt.nstarts);
results = mfit_optimize_parallel(f,param,data,infopt.nstarts);

fn = [S(1).dir 'Fits\fit_gambLearn_' model outprefix];
fprintf('... Saving RL model\n')
fprintf('    File: %s\n',fn)
save(fn,'results')

gnu = 1;
