function [lerrbar] = fw_cousineau(data,varargin)
%data: m-by-n matrix with number of participants (m) und conditions (n)
%conditions: cell containing conditionnames (see ANOVAmodel)

if nargin < 2
    type = 'sem'; %default
elseif nargin == 2
    type = varargin;
else
    error('too many input arguments')
end

vpmean = squeeze(mean(data,2));
grandmean = mean(vpmean);

n = size(data);
nVP = n(1);
nCond = n(2);

data_norm = bsxfun(@minus, data, vpmean) + grandmean;

if strcmp(type,'sem')
    errbar(:,1) = mean(data,1) - std(data_norm)/sqrt(nVP);
    errbar(:,2) = mean(data,1) + std(data_norm)/sqrt(nVP);
    lerrbar = std(data_norm)/sqrt(nVP);
elseif strcmp(type,'ci95')
    errbar(:,1) = mean(data,1) - 1.96*std(data_norm)/sqrt(nVP);
    errbar(:,2) = mean(data,1) + 1.96*std(data_norm)/sqrt(nVP);
    lerrbar = 1.96*std(data_norm/sqrt(nVP));
elseif strcmp(type,'ci99')
    errbar(:,1) = mean(data,1) - 2.576*std(data_norm)/sqrt(nVP);
    errbar(:,2) = mean(data,1) + 2.576*std(data_norm)/sqrt(nVP);
    lerrbar = 2.576*std(data_norm/sqrt(nVP));    
else
    error('type is incorrect - either ''sem'' or ''ci''')
end








