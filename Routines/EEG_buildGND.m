function fw_singletrial_buildGND(S,dir,options,model,infix)

filedir = [S(1).dir_rpe infix];
mkdir(filedir)

nS = length(S);
nChan = 67;

% labels for the different regression models
outprefixes = {'RL-fullByRPE' 'RLvalence-learn' 'RLvalence-gamb' 'RLsurprise-learn' 'RLsurprise-gamb' 'RLsurprise-win' 'RLsurprise-los' };    


%prepare regression outputs
for iVP = 1:nS
    
    %load regression data
    fn = [filedir '\singletrial-' S(iVP).EEGfn '-'  model '.mat'];
    load(fn)
    
    RPEs(iVP) = data;
    
    iX = 0; %number of overall coefficients
    for iOut = 1:length(outprefixes) %number of regression models
        for iFact = 1:length(RPEs(1).coefname{iOut}) %number of coefficients per model
            iX = iX + 1;
            
            %normalize beta values by their respective SD
            rpevalues = RPEs(iVP).bvals{iOut}(1:nChan,:,iFact);
            rpestd = std(reshape(rpevalues,numel(rpevalues),1));
            RPEdat{iX}(:,:,iVP) = rpevalues./rpestd; %beta normalization
            
            condnames{iX} = [outprefixes{iOut} '-' strrep(RPEs(1).coefname{iOut}{iFact},':','By')];
            
        end
    end        
end
condcount = iX;

%construct timeline
timewin = cell2mat(cellfun(@(x) x(end) - x(1),{RPEs.times},'UniformOutput',false))./1000;
freqrate = timewin./cellfun(@length,{RPEs.times});
srates = floor(1./freqrate);
if length(unique(srates)) > 1
    error('differente sampling rates')
else
    srate = unique(srates);
end
framewin = [-0.5 1];
timepnts = 1000.*(framewin(1):1/srate:framewin(2));
times.framewin_sec = framewin;
times.srate = srate;
times.pnts = timepnts;


%load musterGND file (MassUnivariateToolbox)
fn = '.\Routines\musterGND.GND';
load(fn,'-mat');
GND_rpe = musterGND;

%load EEG set (to get chanlocs)
fn = [S(1).EEGfn '.set'];
raw = pop_loadset('filename',fn,'filepath',[S(1).EEGdir]);
chanlocs = raw.chanlocs(1:67);
clear raw

%% Construct GND for reward prediction errors

fout = ['GND-RPE-' model];

GND_rpe.exp_desc = 'RPEweights for all VPs';
GND_rpe.filename = fout;
GND_rpe.filepath = filedir;

GND_rpe.grands = [];
GND_rpe.grands_stder = [];
GND_rpe.grands_t = [];
GND_rpe.bin_info = [];
indiv_erps = [];

for i = 1:length(RPEdat)
    grands(:,:,i) = squeeze(mean(RPEdat{i}(:,:,:),3));
    grands_stder(:,:,i) = squeeze(std(RPEdat{i}(:,:,:),[],3)) / sqrt(size(RPEdat{i},3));
    
    GND_rpe.bin_info(i).bindesc = condnames{i};
    GND_rpe.bin_info(i).condcode = 1;
    
    for iVP = 1:nS
        indiv_erps(:,:,i,iVP) = RPEdat{i}(:,:,iVP);
    end
end

grands_t =  grands ./ grands_stder;

GND_rpe.grands = grands;
GND_rpe.grands_stder = grands_stder;
GND_rpe.grands_t = grands_t;
GND_rpe.sub_ct = ones(1,condcount(1))*nS; %VP
GND_rpe.chanlocs = chanlocs;
GND_rpe.time_pts = times.pnts;
GND_rpe = rmfield(GND_rpe,'bsln_wind');
GND_rpe.srate = srate;
GND_rpe.indiv_fnames = {S.EEGfn};
GND_rpe.indiv_subnames = {S.EEGfn};
GND_rpe.indiv_bin_ct = ones(nS,condcount(1));
GND_rpe.indiv_bin_raw_ct = ones(nS,condcount(1));
GND_rpe.indiv_erps = indiv_erps;
GND_rpe.indiv_art_ics = cell(1,nS);

% save GND
fout = [filedir '\GND-RPE-' model '.GND'];
save(fout,'GND_rpe');