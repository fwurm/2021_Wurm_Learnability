function [cms] = plotConfusion(modrecov,dir,prefix)

fprintf('Processing confusion matrix simulation...\n')

nModel = length(modrecov.models);

plotinput = input('      Which recovery? Type folder name.>','s');
outfix = [dir.dir_simulation '\' plotinput '\']

for jModel = 1:nModel
    for iModel = 1:nModel
        reconstructionModel = modrecov.models{iModel};
        
        %load model fits
        inname = ['-to-data-' modrecov.models{jModel} '-' num2str(modrecov.nSample) 'Samples-'   modrecov.mode];
        fn_estimation = [outfix 'fit_' prefix reconstructionModel inname];
        load(fn_estimation)
        
        fit(iModel) = results;
       
        bic{jModel}(:,iModel) = [results.bic];
        aic{jModel}(:,iModel) = [results.aic];
        
    end
    
    %BIC
    [~,winmodel] = min(bic{jModel},[],2);
    binc = [1:length(modrecov.models)];
    countsBIC = hist(winmodel,binc);
    resultsBIC = [binc;countsBIC];
    confMatBIC(jModel,:) = countsBIC./modrecov.nSample;
    
    %AIC
    [~,winmodel] = min(aic{jModel},[],2);
    binc = [1:length(modrecov.models)];
    countsAIC = hist(winmodel,binc);
    resultsAIC = [binc;countsAIC];
    confMatAIC(jModel,:) = countsAIC./modrecov.nSample;
    
    %Laplace-informed BMS
    bms_results = mfit_bms(fit,0); %home    
    confMatPXP_LAP(jModel,:) = [bms_results.pxp];
    a = [bms_results.g]; %extract posterior probabilities
    [b, i] = max(a,[],2); %using argmax
    [gc, gr] = groupcounts(i);
    gprobs = zeros(size(a,2),1);
    gprobs(gr) = gc./sum(gc);    
    confMatGPP_LAP(jModel,:) = gprobs;
    
    %BIC-informed BMS
    bms_results = mfit_bms(fit,1);     
    confMatPXP_BIC(jModel,:) = [bms_results.pxp];
    a = [bms_results.g]; %extract posterior probabilities
    [b, i] = max(a,[],2); %using argmax
    [gc, gr] = groupcounts(i);
    gprobs = zeros(size(a,2),1);
    gprobs(gr) = gc./sum(gc);    
    confMatGPP_BIC(jModel,:) = gprobs;
    
end


cms(:,:,1) = confMatBIC;
cms(:,:,2) = confMatAIC;
cms(:,:,3) = confMatPXP_LAP;
cms(:,:,4) = confMatGPP_LAP;
cms(:,:,5) = confMatPXP_BIC;
cms(:,:,6) = confMatGPP_BIC;
