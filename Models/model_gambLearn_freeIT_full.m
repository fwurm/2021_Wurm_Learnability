function output = model_gambLearn_freeIT_full(x,data)

% Reinforcement learning model with variable inverse temperature and full updating
%
% USAGE: lik = model_postCAT(x,data)
%
% INPUTS:
%   x - parameters:
%       x(1) - learning rate
%       x(2) - inverse temperature for learning task
%       x(3) - inverse temperature for gambling task
%       x(4) - perseveration
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

%catch parameters
lr = x(1); %learning rate
b_learn = x(2); %inverse temperature learning
b_gamb = x(3); %inverse temperature gambling
p = x(4); %perseveration

if isfield(data,'d')
    actiontype = 'decision_given';
else
    actiontype = 'sample_decision';
end

info = [data.info];

C = 3; % number of all options
S = data.nS; %number of sets

%initialize values
lik = 0; %likelihood

for iB = 1:data.nB
    
    %initialize values
    ind = zeros(S,C); %indicator for perseveration
    v = zeros(S,C);  %action values
    v(:,3) = -10;
       
    for iT = 1:data.nT
        
        %catch decision and reward
        s = data.s(iB,iT); %set
        y = data.y(iB,iT); %task condition (yoked)
         
        
        %update log likelihood
        if y == 0
                q = b_learn*v(s,:)  + p*ind(s,:); 
            elseif y == 1
                q = b_gamb*v(s,:)  + p*ind(s,:);
            else
                error('no yoking condition detected')
        end
            
        ap = exp(q - logsumexp(q,2)); %softmax action probability
        
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
        
        data_model.Q(iB,iT,:) = v(s,:);
        data_model.Q_notupdated(iB,iT,:) = v(s,c);
        
        Paction = ap(c);
        lik_temp = log(ap(c));
        if isinf(log(ap))
            lik_temp = -(10^5);
        end
        lik = lik + lik_temp; %log likelihood
        
        if c ~= 3
            %calculate reward prediction error
            rpe = r-v(s,c);
            
            % update values
            v(s,c) = v(s,c) + lr*rpe;
            v(s,3-c) = v(s,3-c) - lr*rpe;
        else
            rpe = nan;
        end
        
        % forgetting
%         possib = [1:C];
%         possib(union(c,3)) = [];
%         v(s,possib) = (1-lr).*v(s,possib);


        % update perseveration
        ind(s,:) = zeros(1,C);
        ind(s,c) = 1;
        
        
        data_model.c(iB,iT,1) = c;
        data_model.r(iB,iT,1) = r;
        data_model.y(iB,iT,1) = y;
        data_model.s(iB,iT,1) = s;
        data_model.rpe(iB,iT,1) = rpe;
        data_model.Q_updated(iB,iT,1) = v(s,c);
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

% sumlik = mean(pred);


gnu = 1;