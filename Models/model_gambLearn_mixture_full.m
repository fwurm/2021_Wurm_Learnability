function output = model_gambLearn_mixture_full(x,data)

% Reinforcement learning model with mixture policy and full updating
%
% USAGE1: lik = model_postCAT(x,data) %if data.info.type=='behavioral fit'
% USAGE2: VARIABLES = model_postCAT(x,data) %if data.info.type=='simulation'
%
% INPUTS:
%   x - parameters:
%       x(1) - learning rate 
%       x(2) - inverse temperature
%       x(3) - RL-basedness (for learning blocks)
%       x(4) - RL-basedness (for gambling blocks)
%       x(5) - perseveration
%   data - structure with the following fields
%          .d - [nB x nT] choices/decisions
%          .r - [nB x nT] rewards
%          .s - [nB x nT] set/pair
%          .y - [nB x nT] yoked
%          .nT - number of trials (per block)
%          .nB - number of blocks
%          .nS - number of sets/pairs (per block)
%          .info - structure containing detailed information
%
% OUTPUTS:
%   lik - log-likelihood (if info.type = behavioral fit)
%   data_model - generated data (if info.type = simulation)
%
% Franz Wurm, June 2021
% adapted from Sam Gershman, June 2015

if isfield(data,'d')
    actiontype = 'decision_given';
else
    actiontype = 'sample_decision';
end

%catch parameters
lr = x(1); %learning rate
b = x(2); %inverse temperature
w_learn = x(3); %mixture proportion for learning task
w_gamb = x(4); %mixture proportion for gambling task
p = x(5); %perseveration

info = [data.info];

C = 3; % number of all options
S = data.nS;  %number of sets

%initialize likelihood
lik = 0;

%initialize random agent
v_gamb = [0 0 -10];

for iB = 1:data.nB
    
    %initialize values
    ind = zeros(S,C); %indicator for perseveration
    v_rl = zeros(S,C);  %action values
    v_rl(:,3) = -10;
    
  
    for iT = 1:data.nT
        
        %catch trial information
        s = data.s(iB,iT); %set
        y = data.y(iB,iT); %yoked
        
        data_model.Q(iB,iT,:) = v_rl(s,:);
                
        if y == 0 %learning task
            v_net = w_learn*v_rl(s,:) + (1-w_learn)*v_gamb;
        elseif y == 1 %gambling task
            v_net = w_gamb*v_rl(s,:) + (1-w_gamb)*v_gamb;
        else
            error('no yoking condition detected')
        end
        q_net = b*v_net + p*ind(s,:); %net action values
        ap = exp(q_net - logsumexp(q_net,2)); %softmax action probability
        
        
        
        if strcmp(info.type,'behavioral fit')
            c = data.d(iB,iT); %get choice 
            r = data.r(iB,iT); %get rewards  
        elseif strcmp(info.type,'simulation')           
            if strcmp(actiontype,'sample_decision')         
                c = 3;
                while c > 2
                    c = fastrandsample(ap);
                end
                if y == 0; r = data.r(iB,iT,c);
                elseif y == 1; r = data_model.r(iB-1,iT,1);
                end
            elseif strcmp(actiontype,'decision_given')              
                c = data.d(iB,iT);        
                r = data.r(iB,iT);          
            else
                error()
            end
        else
            error()
        end
        
        data_model.Q_notupdated(iB,iT,1) = v_rl(s,c);
        
        %update log likelihood
        Paction = ap(c);
        lik_temp = log(ap(c));
        if isinf(log(ap))
            lik_temp = -(10^5);
        end
        lik = lik + lik_temp; %log likelihood
        
        if c ~= 3
            %calculate reward prediction error
            rpe = r-v_rl(s,c);
            
            % update values
            v_rl(s,c) = v_rl(s,c) + lr*rpe; %chosen option
            v_rl(s,3-c) = v_rl(s,3-c) - lr*rpe; %forgone option
        else
            rpe = nan;
        end
        
        % forgetting
%         possib = [1:C];
%         possib(union(c,3)) = [];
%         v_rl(s,possib) = (1-lr).*v_rl(s,possib);
        
        % update perseveration indicator function
        ind(s,:) = zeros(1,C);
        ind(s,c) = 1;
        
        data_model.c(iB,iT,1) = c;
        data_model.r(iB,iT,1) = r;
        data_model.y(iB,iT,1) = y;
        data_model.s(iB,iT,1) = s;
        data_model.rpe(iB,iT,1) = rpe;
        data_model.Q_updated(iB,iT,1) = v_rl(s,c);
        data_model.ap(iB,iT,1) = Paction;
        
    end
end


if strcmp(info.type,'behavioral fit')
    output = lik;
elseif strcmp(info.type,'simulation')
    output  = data_model;
else
    error('no output specified')
end


gnu = 1;