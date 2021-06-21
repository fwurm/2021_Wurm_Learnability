function [mout, mout2] = fw_modelcomp(dir,models,BEHfn,varargin)

fprintf('\nModel comparison\n')

inprefix = '';
outprefix = '';

for i = 1:length(varargin)
    if strcmp(varargin{i}, 'in')
        if length(varargin)>i
            inprefix = ['_' varargin{i+1}];
            fprintf('   inprefix: %s\n',varargin{i+1})
        else
            disp('ERROR: Input for parameter ''outprefix'' is not valid!');
        end
    end
    if strcmp(varargin{i}, 'out')
        if length(varargin)>i
            outprefix = ['_' varargin{i+1}];
            fprintf('   outprefix: %s\n',varargin{i+1})
        else
            disp('ERROR: Input for parameter ''outprefix'' is not valid!');
        end
    end
end

for i = 1:length(models)
    load([dir.dir_fits 'fit_gambLearn_' models{i} inprefix '.mat'])
        
    fit(i) = results;
        
    LOGLIK(i,:) = [fit(i).loglik];
    BIC(i,:,:) = [fit(i).bic];
    AIC(i,:,:) = [fit(i).aic];
    gnu = 1;
    
end

fit_orig = fit;

[~,ind] = min(BIC);
ind = squeeze(ind);

% %%mfit comparison
% for i = 1:length(models)
%     fit(i).logpost = reshape(fit(i).logpost,1,prod(size(fit(i).logpost)));
%     fit(i).loglik = reshape(fit(i).loglik,prod(size(fit(i).loglik)),1);
%     fit(i).x = reshape(fit(i).x,prod(size(fit(i).logpost)),fit(i).K);
%     fit(i).H = reshape(fit(i).H,prod(size(fit(i).H)),1);
%     fit(i).bic = reshape(fit(i).bic,prod(size(fit(i).logpost)),1);
%     fit(i).aic = reshape(fit(i).aic,prod(size(fit(i).logpost)),1) ;   
% end
% fit = fit';


bms_results = mfit_bms(fit,0); %home
bms_results2 = mfit_bms(fit,1); %home


tabledata = [mean(LOGLIK,2) mean(BIC,2) fw_cousineau(BIC','sem')' mean(AIC,2) fw_cousineau(AIC','sem')' [bms_results.xp]'];
tabledata_round = tabledata;
tabledata_round(:,[1 2 4]) = round(tabledata_round(:,[1 2 4]));
tabledata_round(:,[3 5 6]) = round2(tabledata_round(:,[3 5 6]),2);



for i = 1:length(models)
    fprintf('   model %d: %s\n',i,models{i})
    fprintf('      alpha: %.2f\n',[bms_results.alpha(i)])
    fprintf('      expectation of p(m|y): %.2f\n',[bms_results.exp_r(i)])
    fprintf('      exceedence probability: %.2f\n',[bms_results.xp(i)])
    fprintf('      protected exceedence probability: %.2f\n',[bms_results.pxp(i)])    
    fprintf('      BIC[sum]: %.2f\n',sum(sum([fit(i).bic])))  
    fprintf('      AIC[sum]: %.2f\n',sum(sum([fit(i).aic])))
    fprintf('      -LL[sum]: %.2f\n',sum(sum([fit(i).loglik])))
    fprintf('      BIC[mean(sd)]: %.2f(%.2f)\n',mean([fit(i).bic]),std([fit(i).bic]))
    fprintf('      AIC[mean(sd)]: %.2f(%.2f)\n',mean([fit(i).aic]),std([fit(i).aic]))
    fprintf('      -LL[mean(sd)]: %.2f(%.2f)\n',mean([fit(i).loglik]),std([fit(i).loglik]))
end

%% Compare learning and gambling blocks separate

for i = 1:length(models)
    
    disp('################')
    
    plot = 1;
    if ~isempty(strfind(models{i},'mixture'))
        para2compare = {'RL-basedness learn' 'RL-basedness gamb'};
        paraname = 'RL-basedness';
    elseif ~isempty(strfind(models{i},'freeLR'))
        para2compare = {'learning rate learn' 'learning rate gamb'};
        paraname = 'Learning rate';
    elseif ~isempty(strfind(models{i},'freeIT'))
        para2compare = {'inverse temperature learn' 'inverse temperature gamb'};
        paraname = 'Inverse temperature';
    else
        warning('no parameters found for comparison')
        plot = 0;
    end
    
    if plot==1
         
        fprintf('Comparison for model ''%s'':\n',models{i})
        fprintf('   %s\n',paraname)
        
        paraFit = [fit(i).x];
        paraName = {fit(i).param.name};
        
        idx_learn = find(ismember(paraName,para2compare{1}));
        idx_gamb = find(ismember(paraName,para2compare{2}));
        
        para_learn = paraFit(:,idx_learn);
        para_gamb = paraFit(:,idx_gamb);
        
        [h,p,ci,stats] = ttest(para_learn,para_gamb);
        
        fprintf('   %s:\n',para2compare{1})
        fprintf('      mean: %.2f\n',mean(para_learn))
        fprintf('      sd: %.2f\n',std(para_learn))
        fprintf('   %s:\n',para2compare{2})
        fprintf('      mean: %.2f\n',mean(para_gamb))
        fprintf('      sd: %.2f\n',std(para_gamb))
        fprintf('   Test statistics: t(%d) = %.2f, p = %.3f\n',stats.df,stats.tstat,p)
    end
        

    

end

disp('################')


mout = bms_results;
mout.mnames = models;

mout2 = bms_results2;
mout2.mnames = models;
gnu = 1;