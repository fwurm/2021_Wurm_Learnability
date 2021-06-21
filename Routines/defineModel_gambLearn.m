function [mstruct, param,f] = defineModel(modelname)
%build structure mstruct, which contains the hard-coded parameters in this
%function according to string input modelname

if strcmp(modelname,'mixture-full')
    mstruct.modelname = 'Extended Mixture model for each condition with perseveratio';
    mstruct.modelshort = 'mixture-full';
    mstruct.funhandle = @model_gambLearn_mixture_full;
    
    mstruct.name = {'learning rate' 'inverse temperature' 'RL-basedness learn' 'RL-basedness gamb' 'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 1.2; c2 = 1.2; %RL-basedness learn  
    d1 = 1.2; d2 = 1.2; %RL-basedness gamb
    e1 = 0; e2 = 2; %perseveration
    
    lb = [0 0 0.5 0 -1];
    ub = [1 5 1 0.5 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1) betarnd(c1,c2,x,1) betarnd(c1,c2,x,1) normrnd(d1,d2,x,1) ];   
    samplehandle_random = @(x) [unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0; param(1).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(2).name = 'inverse temperature';
    param(2).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(2).lb = 0; param(2).ub = 20; 
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(3).name = 'RL-basedness learn';
    param(3).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(3).lb = 0; param(3).ub = 1;
    param(4).name = 'RL-basedness gamb';
    param(4).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(4).lb = 0; param(4).ub = 1;
    a = 0; b = 1;   % parameters of gaussian prior
    param(5).name = 'perseveration';
    param(5).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(5).lb = -5; param(5).ub = 5;
    
    f = @model_gambLearn_mixture_full;  
    
elseif strcmp(modelname,'mixture-partial')
    mstruct.modelname = 'Extended Mixture model for each condition with perseveration';
    mstruct.modelshort = 'mixture-partial';
    mstruct.funhandle = @model_gambLearn_mixture_partial;
    
    mstruct.name = {'learning rate' 'inverse temperature' 'RL-basedness learn' 'RL-basedness gamb' 'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 1.2; c2 = 1.2; %RL-basedness learn  
    d1 = 1.2; d2 = 1.2; %RL-basedness gamb
    e1 = 0; e2 = 2; %perseveration
    
    lb = [0 0 0.5 0 -1];
    ub = [1 5 1 0.5 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1) betarnd(c1,c2,x,1) betarnd(c1,c2,x,1) normrnd(d1,d2,x,1) ];   
    samplehandle_random = @(x) [unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1) unifrnd(lb,ub,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0; param(1).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(2).name = 'inverse temperature';
    param(2).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(2).lb = 0; param(2).ub = 20; 
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(3).name = 'RL-basedness learn';
    param(3).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(3).lb = 0; param(3).ub = 1;
    param(4).name = 'RL-basedness gamb';
    param(4).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(4).lb = 0; param(4).ub = 1;
    a = 0; b = 1;   % parameters of gaussian prior
    param(5).name = 'perseveration';
    param(5).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(5).lb = -5; param(5).ub = 5;
    
    f = @model_gambLearn_mixture_partial; 
       
    
elseif strcmp(modelname,'freeLR-full')   
    mstruct.modelname = 'Basic learning model with variable learning rates and full updating';
    mstruct.modelshort = 'freeLR-full';
    mstruct.funhandle = @model_gambLearn_freeLR_full;
    
    mstruct.name = {'learning rate learn' 'learning rate gamb' 'inverse temperature' 'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 0; c2 = 1; %perseveration
    
    lb = [0.5 0 0 -1];
    ub = [1 0.5 5 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1) normrnd(c1,c2,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate learn';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0;
    param(1).ub = 1;
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(2).name = 'learning rate gamb';
    param(2).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(2).lb = 0;
    param(2).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(3).name = 'inverse temperature';
    param(3).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(3).lb = 0;    % lower bound
    param(3).ub = 20;   % upper bound
    a = 0; b = 1;   % parameters of gaussian prior
    param(4).name = 'perseveration';
    param(4).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(4).lb = -5; 
    param(4).ub = 5;
    
    f = @model_gambLearn_freeLR_full; 
       
    
elseif strcmp(modelname,'freeLR-partial')   
    mstruct.modelname = 'Basic learning model with variables learning rates and partial updating';
    mstruct.modelshort = 'freeLR-partial';
    mstruct.funhandle = @model_gambLearn_freeLR_partial;
    
    mstruct.name = {'learning rate learn' 'learning rate gamb' 'inverse temperature' 'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 0; c2 = 1; %perseveration
    
    lb = [0.5 0 0 -1];
    ub = [1 0.5 5 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1) normrnd(c1,c2,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate learn';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0;
    param(1).ub = 1;
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(2).name = 'learning rate gamb';
    param(2).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(2).lb = 0;
    param(2).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(3).name = 'inverse temperature';
    param(3).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(3).lb = 0;    % lower bound
    param(3).ub = 20;   % upper bound
    a = 0; b = 1;   % parameters of gaussian prior
    param(4).name = 'perseveration';
    param(4).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(4).lb = -5; 
    param(4).ub = 5;
    
    f = @model_gambLearn_freeLR_partial;      
    
    
elseif strcmp(modelname,'freeIT-full')   
    mstruct.modelname = 'Basic learning model with variables inverse temperature and full updating';
    mstruct.modelshort = 'freeIT-full';
    mstruct.funhandle = @model_gambLearn_freeIT_full;
    
    mstruct.name = {'learning rate' 'inverse temperature learn' 'inverse temperature gamb'  'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 0; c2 = 1;
    
    lb = [0 1 0 -1];
    ub = [1 5 1 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1)  gamrnd(b1,b2,x,1) normpdf(c1,c2,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0;
    param(1).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(2).name = 'inverse temperature learn';
    param(2).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(2).lb = 0;    % lower bound
    param(2).ub = 20;   % upper bound
    a = 2; b = 1;  % parameters of the gamma prior
    param(3).name = 'inverse temperature gamb';
    param(3).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(3).lb = 0;    % lower bound
    param(3).ub = 20;   % upper bound
    a = 0; b = 1;   % parameters of gaussian prior
    param(4).name = 'perseveration learn';
    param(4).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(4).lb = -5; param(4).ub = 5;
    
    f = @model_gambLearn_freeIT_full;   
    
    
elseif strcmp(modelname,'freeIT-partial')   
    mstruct.modelname = 'Basic learning model with variable inverse temperature and partial updating';
    mstruct.modelshort = 'freeIT-partial';
    mstruct.funhandle = @model_gambLearn_freeIT_partial;
    
    mstruct.name = {'learning rate' 'inverse temperature learn' 'inverse temperature gamb'  'perseveration'};          
    a1 = 1.2; a2 = 1.2; %learning rate   
    b1 = 2;  b2 = 1; %inverse temperature
    c1 = 0; c2 = 1;
    
    lb = [0 1 0 -1];
    ub = [1 5 1 1];
    samplehandle_empprior = @(x) [betarnd(a1,a2,x,1) gamrnd(b1,b2,x,1)  gamrnd(b1,b2,x,1) normpdf(c1,c2,x,1)];   
    
    
    a = 1.2; b = 1.2;   % parameters of beta prior
    param(1).name = 'learning rate';
    param(1).logpdf = @(x) sum(log(betapdf(x,a,b)));
    param(1).lb = 0;
    param(1).ub = 1;
    a = 2; b = 1;  % parameters of the gamma prior
    param(2).name = 'inverse temperature learn';
    param(2).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(2).lb = 0;    % lower bound
    param(2).ub = 20;   % upper bound
    a = 2; b = 1;  % parameters of the gamma prior
    param(3).name = 'inverse temperature gamb';
    param(3).logpdf = @(x) sum(log(gampdf(x,a,b)));  % log density function for prior
    param(3).lb = 0;    % lower bound
    param(3).ub = 20;   % upper bound
    a = 0; b = 1;   % parameters of gaussian prior
    param(4).name = 'perseveration learn';
    param(4).logpdf = @(x) sum(log(normpdf(x,a,b)));
    param(4).lb = -5; param(4).ub = 5;
    
    f = @model_gambLearn_freeIT_partial;        
        
else
    error('input parameter ill defined - model not found, check this function')
end


mstruct.lb = lb;
mstruct.ub = ub;
mstruct.samplehandle_empprior = samplehandle_empprior;
% mstruct.samplehandle_random = samplehandle_random;

gnu = 1;