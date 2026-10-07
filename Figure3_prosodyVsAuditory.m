%% Definitions
project_dir = '/Users/tamaregev/Library/CloudStorage/Dropbox/postdoc/Fedorenko/Prosody/Localizer/PUBLIC';%replace this with the location where the PUBLIC data directory exists
results_dir = [project_dir filesep 'Results'];
figures_dir = [project_dir filesep 'Figures'];

% The scripts (and helper functions, Gerber_toolbox) live in Analysis-Results_PUBLIC,
% which is NOT inside PUBLIC. Take its location from this script's own location.
analysis_dir = fileparts(mfilename('fullpath'));
if isempty(analysis_dir), analysis_dir = pwd; end   % fallback, e.g. when code is pasted into the command window
addpath(genpath(analysis_dir));                       % helper functions: lme2table, plotmROI_prosLoc, barwitherr, suptitle, plotVol2Surf

% make sure the output folders for the stats tables exist
for sd = {'RegionsOther_EffectsOther','RegionsOther_EffectsProsody','RegionsProsody_EffectsOther','InteractionsRegionsEffects','spcorr'}
    if ~exist([results_dir filesep 'stats' filesep sd{1}],'dir'), mkdir([results_dir filesep 'stats' filesep sd{1}]); end
end

%functions needed:
%   Confidence.m
%   barwitherror.m
%   plotmROI_prosLoc.m
%   suptitle.m
%   lme2table.m   (version with the optional 'satterthwaite' argument)
%   plotVol2Surf.m (brain plots only)

results_toolbox_dir = [results_dir '/toolbox_results_important'];
spcorr_dir = [results_dir filesep 'spcorr'];   % toolbox output: expt1_tasks_spcorr_within/between_evenodd_table.csv (spatial-correlation inputs)

%prosody parcels:
pros_fROI_anatomy = readtable([results_dir filesep 'Prosody_SUM_ROIs.xlsx']);
N=51;
parcels_dir = [results_dir '/n' num2str(N) '_results' filesep 'SUM_percent01'];
GSS_dir = [parcels_dir '/prosLocLoc_A-B_C-D_sum_top10percent_n51_20240212'];
stats_file = 'spm_ss_GcSS_results_0001.Stats.csv';
statsT = readtable([GSS_dir filesep stats_file]);
overlap_th = 0.9;
overlapstr=num2str(overlap_th);
allselected = statsT.ROI(statsT.inter_subjectOverlap>=0.5);
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);
selected_R = selected(ismember(selected,pros_fROI_anatomy.ROI(strcmp(pros_fROI_anatomy.Hemisphere,'RH'))));
selected_L = selected(ismember(selected,pros_fROI_anatomy.ROI(strcmp(pros_fROI_anatomy.Hemisphere,'LH'))));

selected_temporal = selected(ismember(selected,pros_fROI_anatomy.ROI(strcmp(pros_fROI_anatomy.Lobe,'Temporal'))));
selected_frontal = selected(ismember(selected,pros_fROI_anatomy.ROI(strcmp(pros_fROI_anatomy.Lobe,'Frontal'))));
selected_medial = selected(ismember(selected,pros_fROI_anatomy.ROI(strcmp(pros_fROI_anatomy.Lobe,'Frontal-Medial'))));

% The 18 prosody fROIs analysed in the paper = the selected parcels that belong to one of
% the six hemisphere x lobe groups (LH/RH x temporal, lateral-frontal, medial-frontal), as in
% Figure1_prosody.m. 'selected' (overlap >= 0.9) alone appears to contain
% 20 parcels. Two of them are cerebellar parcels (15 and 27) and are left out of the main analysis, which focuses on the cortex.
inSixGroups = ismember(pros_fROI_anatomy.Hemisphere,{'LH','RH'}) & ...
              ismember(pros_fROI_anatomy.Lobe,{'Temporal','Frontal','Frontal-Medial'});
selected18 = selected(ismember(selected, pros_fROI_anatomy.ROI(inSixGroups)));
fprintf('Prosody parcels with overlap >= %.1f: %d. In the six hemisphere x lobe groups: %d\n', ...
        overlap_th, numel(selected), numel(selected18));
fprintf('Left out: %s\n', mat2str(setdiff(selected, selected18)'));
if numel(selected18) ~= 18
    warning('Expected 18 prosody fROIs, found %d. Check Prosody_SUM_ROIs.xlsx.', numel(selected18));
end
selected_temporal = selected_temporal(ismember(selected_temporal, selected18));   % NEW: should be 9


%% load and plot effect sizes

% Prosody temporal regions
results_file = [results_toolbox_dir filesep 'ProsParcel_toolbox_results_allexpt.csv'];
Tpros = readtable(results_file);

% Pitch regions
results_file = [results_toolbox_dir filesep 'PitchParcel_toolbox_results_allexpt.csv'];
Tpitch = readtable(results_file);

% speech regions
results_file = [results_toolbox_dir filesep 'SpeechParcel_toolbox_results_allexpt.csv'];
Tspeech = readtable(results_file);

% prep
Effects = {{'A','B','C','D','E','F'},{'spN','spT'},{'pitH','pitN'}};
    %{'EngSpeech','ForSpeech','HumVoc','HumNonVoc','Music','Mechanical','EnvSound'}};
colors = {{[1 0 0],[1 0.5000 0.5000],[0 0 1],[0.5000 0.5000 1],[0.5 0.5 0.5],[0.8 0.8 0.8]},{[0 1 1],[0 0.5 0.5]},{[0 1 0],[0 0.5 0]}};

Ts = {Tpros,Tspeech,Tpitch};

whichROIss = {selected_temporal,1:2,1:2};
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;

titles = {'Pros effects','Speech effects','Pitch effects'};
ylabels = {'Pros parcels','Speech parcels','Pitch parcels'};
legends = {{'SP+','SP-','NP+','NP-','InvP+','InvP-'},{'Sp','T'},{'H','N'}};

figure
set(gcf,'Position',[100 100 500 600])
subplot_indices = {1:3,4:5,6:7;8:10,11:12,13:14;15:17,18:19,20:21};

for iloc = 1:length(Ts)
    for ieffect = 1:length(Effects)
        subplot(3,7,subplot_indices{iloc,ieffect})
        whichROIs = whichROIss{iloc};
        ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names

        [h,hE,hl] = plotmROI_prosLoc(Ts{iloc},Effects{ieffect},whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors{ieffect});
        legend off
        if iloc==1
            title(titles{ieffect})
        else
            title([''])
        end
        if ieffect==1
            ylabel(ylabels{iloc})
            yticks([0 2 4 6 8])
        else
            ylabel(' ')
            yticks([0 2 4 6 8])
            yticklabels({'','','','',''})
        end
        set(gca,'fontsize',16)
        ylim([-1 8])
        xticks((1:length(Effects{ieffect})))
        xticklabels(legends{ieffect});
        pause([1])
    end
end
saveas(gcf,[figures_dir filesep 'Prosody_versus_auditory_ylim-8'],'pdf')

figure
set(gcf,'Position',[100 100 500 600])

for iloc = 1:length(Ts)
    for ieffect = 1:length(Effects)

        subplot(3,7,subplot_indices{iloc,ieffect})
        whichROIs = whichROIss{iloc};
        ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names

        [h,hE,hl] = plotmROI_prosLoc(Ts{iloc},Effects{ieffect},whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors{ieffect});
        legend off
        if iloc==1
            title(titles{ieffect})
        else
            title([''])
        end
        if ieffect==1
            ylabel(ylabels{iloc})
            yticks([0 1 2])
        else
            ylabel(' ')
            yticks([0 1 2])
            yticklabels({'','',''})
        end
        set(gca,'fontsize',16)
        ylim([-0.5 2.5])
         xticks((1:length(Effects{ieffect})))
        xticklabels(legends{ieffect});
        pause([0.5])
    end
end
saveas(gcf,[figures_dir filesep 'Prosody_versus_auditory_ylim-2'],'pdf')

%% LME - effect sizes - pitch

Tpitch.ROI = categorical(Tpitch.ROI);

% pitch effect in pitch parcels
Tpitch_pitch = Tpitch(strcmp(Tpitch.ExpName,'pitchLoc'),:);
Tpitch_pitch.Effect = categorical(Tpitch_pitch.Effect);
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tpitch_pitch,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsOther' filesep 'LME_pitch_pitch.csv'])


% prosody effects in pitch parcels
Tpitch_pros = Tpitch(strcmp(Tpitch.ExpName,'prosodyLoc') & ismember(Tpitch.Effect,{'A','B','C','D','E','F'}),:);
Tpitch_pros.Effect = categorical(Tpitch_pros.Effect);
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tpitch_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_pitch_pros_refSP+.csv'])


 %relative to NP+
%categories(Tpitch_pros.Effect)
Tpitch_pros.Effect = reordercats(Tpitch_pros.Effect, [3 4 1 2 5 6]);
%categories(Tpitch_pros.Effect)
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tpitch_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_pitch_pros_refNP+.csv'])


% overall prosody effect - abcd
Tpitch_pros = Tpitch(strcmp(Tpitch.ExpName,'prosodyLoc') & ismember(Tpitch.Effect,{'A','B','C','D','E','F'}),:);

Tpitch_pros_abcd = Tpitch_pros(ismember(Tpitch_pros.Effect,{'A','B','C','D'}),:);
isProsody = Tpitch_pros_abcd.Effect;
isProsody(ismember(Tpitch_pros_abcd.Effect,{'A','C'})) = {'Pros+'};
isProsody(ismember(Tpitch_pros_abcd.Effect,{'B','D'})) = {'Pros-'};

Tpitch_pros_abcd = [Tpitch_pros_abcd, table(isProsody)];
Tpitch_pros_abcd.isProsody = categorical(Tpitch_pros_abcd.isProsody);
formula = 'EffectSize ~ isProsody  + (isProsody|Subject) + (isProsody|ROI)';

lme = fitlme(Tpitch_pros_abcd,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_pitch_pros_overall.csv'])



%% LME - effect sizes - speech

Tspeech.ROI = categorical(Tspeech.ROI);

% speech effect in speech parcels
Tspeech_speech = Tspeech(strcmp(Tspeech.ExpName,'speechLoc'),:);
Tspeech_speech.Effect = categorical(Tspeech_speech.Effect);
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tspeech_speech,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsOther' filesep 'LME_speech_speech.csv'])


% prosody effects in speech parcels
    %relative to SP+
Tspeech_pros = Tspeech(strcmp(Tspeech.ExpName,'prosodyLoc') & ismember(Tspeech.Effect,{'A','B','C','D','E','F'}),:);
Tspeech_pros.Effect = categorical(Tspeech_pros.Effect);
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tspeech_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_speech_pros_refSP+.csv'])


    %relative to NP+
%categories(Tspeech_pros.Effect)
Tspeech_pros.Effect = reordercats(Tspeech_pros.Effect, [3 4 1 2 5 6]);
%categories(Tspeech_pros.Effect)
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tspeech_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_speech_pros_refNP+.csv'])


    %relative to NP-
%categories(Tspeech_pros.Effect)
Tspeech_pros.Effect = reordercats(Tspeech_pros.Effect, [2 1 3 4 5 6]);
%categories(Tspeech_pros.Effect)
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tspeech_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_speech_pros_refNP-.csv'])


% overall prosody effect - abcd
Tspeech_pros = Tspeech(strcmp(Tspeech.ExpName,'prosodyLoc') & ismember(Tspeech.Effect,{'A','B','C','D','E','F'}),:);
Tspeech_pros_abcd = Tspeech_pros(ismember(Tspeech_pros.Effect,{'A','B','C','D'}),:);
isProsody = Tspeech_pros_abcd.Effect;
isProsody(ismember(Tspeech_pros_abcd.Effect,{'A','C'})) = {'Pros+'};
isProsody(ismember(Tspeech_pros_abcd.Effect,{'B','D'})) = {'Pros-'};

Tspeech_pros_abcd = [Tspeech_pros_abcd, table(isProsody)];
Tspeech_pros_abcd.isProsody = categorical(Tspeech_pros_abcd.isProsody);
formula = 'EffectSize ~ isProsody  + (isProsody|Subject) + (isProsody|ROI)';
lme = fitlme(Tspeech_pros_abcd,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_speech_pros_overall.csv'])


% overall speech reversal effect - abcd vs. ef
Tspeech_pros = Tspeech(strcmp(Tspeech.ExpName,'prosodyLoc') & ismember(Tspeech.Effect,{'A','B','C','D','E','F'}),:);
isReversed = Tspeech_pros.Effect;
isReversed(ismember(Tspeech_pros.Effect,{'E','F'})) = {'Backward'};
isReversed(ismember(Tspeech_pros.Effect,{'A','B','C','D'})) = {'Forward'};

Tspeech_pros = [Tspeech_pros, table(isReversed)];
Tspeech_pros.isReversed = categorical(Tspeech_pros.isReversed);
formula = 'EffectSize ~ isReversed + (isReversed|Subject) + (isReversed|ROI)';
lme = fitlme(Tspeech_pros,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsProsody' filesep 'LME_speech_pros_reversalEffect.csv'])


% overall language effect - abcd
Tspeech_pros = Tspeech(strcmp(Tspeech.ExpName,'prosodyLoc') & ismember(Tspeech.Effect,{'A','B','C','D','E','F'}),:);
Tspeech_pros_abcd = Tspeech_pros(ismember(Tspeech_pros.Effect,{'A','B','C','D'}),:);
isLang = Tspeech_pros_abcd.Effect;
isLang(ismember(Tspeech_pros_abcd.Effect,{'A','B'})) = {'Lang+'};
isLang(ismember(Tspeech_pros_abcd.Effect,{'C','D'})) = {'Lang-'};

Tspeech_pros_abcd = [Tspeech_pros_abcd, table(isLang)];
Tspeech_pros_abcd.isLang = categorical(Tspeech_pros_abcd.isLang);
formula = 'EffectSize ~ isLang  + (isLang|Subject) + (isLang|ROI)';
lme = fitlme(Tspeech_pros_abcd,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsOther_EffectsOther' filesep 'LME_speech_audLangEffect.csv'])


%% LME - effect sizes - prosody
stats_file = 'spm_ss_GcSS_results_0001.Stats.csv';
statsT = readtable([GSS_dir filesep stats_file]);
ROIanaT = readtable([results_dir filesep 'Prosody_SUM_ROIs.xlsx']);
overlap_th = 0.9;
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);

% CHANGED: restrict to the 18 fROIs (previously 'selected', which gave 20 ROIs in Table S3/S5)
inSixGroups = ismember(ROIanaT.Hemisphere,{'LH','RH'}) & ...
              ismember(ROIanaT.Lobe,{'Temporal','Frontal','Frontal-Medial'});
selected18 = selected(ismember(selected, ROIanaT.ROI(inSixGroups)));
Tpros = Tpros(ismember(Tpros.ROI,selected18),:);
fprintf('Prosody fROIs used in the LMEs: %d (should be 18)\n', numel(unique(Tpros.ROI)));
Tpros.ROI = categorical(Tpros.ROI);

% pitch effect in prosody parcels
Tpros_pitch = Tpros(strcmp(Tpros.ExpName,'pitchLoc'),:);
Tpros_pitch.Effect = categorical(Tpros_pitch.Effect);
fprintf('pitch effect in prosody fROIs: %d ROIs, %d participants, %d rows (expect 18, 17, 612)\n', numel(unique(Tpros_pitch.ROI)), numel(unique(Tpros_pitch.Subject)), height(Tpros_pitch));   % NEW check
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tpros_pitch,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsOther' filesep 'LME_prosody_pitch.csv'])


% speech effect in prosody parcels
Tpros_speech = Tpros(strcmp(Tpros.ExpName,'speechLoc'),:);
Tpros_speech.Effect = categorical(Tpros_speech.Effect);
fprintf('speech effect in prosody fROIs: %d ROIs, %d participants, %d rows (expect 18, 37, 1332)\n', numel(unique(Tpros_speech.ROI)), numel(unique(Tpros_speech.Subject)), height(Tpros_speech));   % NEW check
formula = 'EffectSize ~ Effect + (Effect|Subject) + (Effect|ROI)';
lme = fitlme(Tpros_speech,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsOther' filesep 'LME_prosody_speech.csv'])

%%%%interaction between speech and prosody regions for their responses to
%%%%the speech localizer:

whichRegions = Tpros_speech.Effect;
whichRegions(:) = {'Pros'};
Tpros_speech = [Tpros_speech, table(whichRegions)];

whichRegions = Tspeech_speech.Effect;
whichRegions(:) = {'Speech'};
Tspeech_speech = [Tspeech_speech, table(whichRegions)];

T_inter = [Tpros_speech; Tspeech_speech];


T_inter.Effect = categorical(T_inter.Effect);
T_inter.whichRegions = categorical(T_inter.whichRegions);
T_inter.whichRegions = removecats(categorical(T_inter.whichRegions));
T_inter.Subject = categorical(T_inter.Subject);
T_inter.ROI = categorical(T_inter.ROI);
T_inter.ROIcat = categorical(strcat(string(T_inter.whichRegions), "_", string(T_inter.ROI)));

formula = 'EffectSize ~ Effect*whichRegions + (Effect|Subject) + (Effect|ROIcat)';

%formula = 'EffectSize ~ Effect*whichRegions + (1|Subject) + (1|ROIcat)';
%formula = 'EffectSize ~ whichRegions';

lme = fitlme(T_inter,formula); LMER_tab = lme2table(lme,'satterthwaite'); writetable(LMER_tab,[results_dir filesep 'stats' filesep 'InteractionsRegionsEffects' filesep 'LME_interaction_RegionsProsSpeech_EffectSpeech.csv'])


%% plot parcels - prosody temporal
%for this part, spm and freesurfer need to be installed on your machine

%init spm and evlab toolbox:
addpath('/Users/tamaregev/Dropbox/MATLAB/Toolbox/spm-main')%spm folder
fs_dir = '/Applications/freesurfer/7.4.1/';%freesurfer folder
addpath(genpath(fs_dir));

gerber_toolbox_path = [analysis_dir filesep 'Gerber_toolbox'];
addpath(genpath(gerber_toolbox_path));


% SUM percent 10
surf_dir = [GSS_dir filesep 'surf'];
mkdir(surf_dir)

parcels_image=[GSS_dir filesep 'fROIs.nii'];


parcels_dir = [project_dir filesep 'Parcels'];



%read parcels nifti:
HeaderInfo = spm_vol(parcels_image);
a = spm_read_vols(HeaderInfo);

%plot
bash_path=getenv('PATH');
setenv('PATH',[bash_path,':/Applications/freesurfer/7.4.1/',':/Applications/freesurfer/7.4.1/bin',':/Applications/freesurfer/7.4.1/subjects']);

numROIs = length(unique(a))-1;
colors = [218, 3, 252]./255;
% light_pink = [218, 3, 252]./255;
% purple = [218, 3, 252]./255;
% R = linspace(purple(1),light_pink(1),numROIs);
% G = linspace(purple(2),light_pink(2),numROIs);
% B = linspace(purple(3),light_pink(3),numROIs);
% colors = [R', G', B'];

clim = [1 max(selected)];

%whichROIs = 1:numROIs;
whichROIs = selected_temporal;

inflated = true;


%%%%%%% Lateral view
h=figure;set(h,'position',[10 10 1000 600])
whichHemi = 'lh';
subplot(1,2,1)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'lateral');

whichHemi = 'rh';
subplot(1,2,2)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'lateral');
hs=suptitle(['Temporal prosody parcels - SUM percent10 ' 'selected overlap th: ' num2str(overlap_th) ' , ' num2str(length(whichROIs))]);
set(hs,'fontsize',20)

saveas(gcf,[figures_dir filesep 'GSS_prosody_temporal_parcels_lateral_SUM01_overlap_th_0' overlapstr(end) '_magenta'],'fig')
saveas(gcf,[figures_dir filesep 'GSS_prosody_temporal_parcels_lateral_SUM01_overlap_th_0' overlapstr(end) '_magenta'],'png')


%% plot parcels - speech

%for this part, spm and freesurfer need to be installed on your machine

%init spm and evlab toolbox:
addpath('/Users/tamaregev/Dropbox/MATLAB/Toolbox/spm-main')%spm folder
fs_dir = '/Applications/freesurfer/7.4.1/';%freesurfer folder
addpath(genpath(fs_dir));

gerber_toolbox_path = [analysis_dir filesep 'Gerber_toolbox'];
addpath(genpath(gerber_toolbox_path));


parcels_dir = [project_dir filesep 'Parcels'];

surf_dir = [parcels_dir filesep 'surf'];
mkdir(surf_dir)

parcels_image=[parcels_dir filesep 'speech_LH_1_mirrored_conjunction_final.nii'];

%read parcels nifti:
HeaderInfo = spm_vol(parcels_image);
a = spm_read_vols(HeaderInfo);

%plot
bash_path=getenv('PATH');
setenv('PATH',[bash_path,':/Applications/freesurfer/7.4.1/',':/Applications/freesurfer/7.4.1/bin',':/Applications/freesurfer/7.4.1/subjects']);

numROIs = length(unique(a))-1;
colors = [0 1 1];
% light_pink = [218, 3, 252]./255;
% purple = [218, 3, 252]./255;
% R = linspace(purple(1),light_pink(1),numROIs);
% G = linspace(purple(2),light_pink(2),numROIs);
% B = linspace(purple(3),light_pink(3),numROIs);
% colors = [R', G', B'];

clim = [1 max(allselected)];

%whichROIs = 1:numROIs;
whichROIs = 1:2;

inflated = true;


%%%%%%% Lateral view
h=figure;set(h,'position',[10 10 1000 600])
whichHemi = 'lh';
subplot(1,2,1)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'lateral');

whichHemi = 'rh';
subplot(1,2,2)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'lateral');
hs=suptitle('Speech symmetric');
set(hs,'fontsize',22)

saveas(gcf,[figures_dir filesep 'Speech_symmetric_parcels_lateral'],'fig')
saveas(gcf,[figures_dir filesep 'Speech_symmetric_parcels_lateral'] ,'png')



%% plot parcels - pitch

%for this part, spm and freesurfer need to be installed on your machine

%init spm and evlab toolbox:
addpath('/Users/tamaregev/Dropbox/MATLAB/Toolbox/spm-main')%spm folder
fs_dir = '/Applications/freesurfer/7.4.1/';%freesurfer folder
addpath(genpath(fs_dir));

gerber_toolbox_path = [analysis_dir filesep 'Gerber_toolbox'];
addpath(genpath(gerber_toolbox_path));


parcels_dir = [project_dir filesep 'Parcels'];

surf_dir = [parcels_dir filesep 'surf'];
mkdir(surf_dir)

parcels_image=[parcels_dir filesep 'pitchLoc_RH_mirrored_conjunction_final.nii'];

%read parcels nifti:
HeaderInfo = spm_vol(parcels_image);
a = spm_read_vols(HeaderInfo);

%plot
bash_path=getenv('PATH');
setenv('PATH',[bash_path,':/Applications/freesurfer/7.4.1/',':/Applications/freesurfer/7.4.1/bin',':/Applications/freesurfer/7.4.1/subjects']);

numROIs = length(unique(a))-1;
colors = [0 1 0];
% light_pink = [218, 3, 252]./255;
% purple = [218, 3, 252]./255;
% R = linspace(purple(1),light_pink(1),numROIs);
% G = linspace(purple(2),light_pink(2),numROIs);
% B = linspace(purple(3),light_pink(3),numROIs);
% colors = [R', G', B'];

clim = [1 max(allselected)];

%whichROIs = 1:numROIs;
whichROIs = 1:2;

inflated = true;


%%%%%%% Lateral view
h=figure;set(h,'position',[10 10 1000 600])
whichHemi = 'lh';
subplot(1,2,1)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'lateral');

whichHemi = 'rh';
subplot(1,2,2)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'lateral');
hs=suptitle('Pitch symmetric');
set(hs,'fontsize',22)

saveas(gcf,[figures_dir filesep 'Pitch_symmetric_parcels_lateral'],'fig')
saveas(gcf,[figures_dir filesep 'Pitch_symmetric_parcels_lateral'] ,'png')

%% spatial correlations - split half runs

T_within = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_within_evenodd_table.csv'], 'Delimiter',',');
T_between = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_between_evenodd_table.csv'], 'Delimiter',',');
T = [T_within;T_between];

hemis = {'LH','RH'};
lobes = {'Temporal'};
locs = {'SpSp','PiPi','PrPr','SpPi','SpPr','PiPr'};
nCond = length(locs)*length(hemis)*length(lobes);
locations = [1 2 3 4 5 6  8 9 10 11 12 13];
colors = {[0 1 1],[0 1 0],[1 0 1],[0 1 0.5],[0.5 0.5 1],[1 0.5 1]};

subjects = {'837_FED_20220414a_3T1_PL2017',...
'881_FED_20220506a_3T1_PL2017',...
'882_FED_20220512a_3T1_PL2017',...
'883_FED_20220512b_3T1_PL2017',...
'884_FED_20220513a_3T1_PL2017',...
'885_FED_20220513b_3T1_PL2017',...
'886_FED_20220513c_3T1_PL2017',...
'890_FED_20220518b_3T1_PL2017',...
'831_FED_20220525a_3T1_PL2017',...
'842_FED_20220525b_3T1_PL2017',...
'891_FED_20220525c_3T1_PL2017',...
'684_FED_20220526a_3T1_PL2017',...
'892_FED_20220526b_3T1_PL2017',...
'893_FED_20220606a_3T1_PL2017',...
'865_FED_20220608b_3T1_PL2017',...
'894_FED_20220613a_3T1_PL2017',...
'895_FED_20220613b_3T1_PL2017'...
};


data = nan(length(subjects),nCond);
i=1;
for hemi = hemis
    for lobe = lobes
        Temp = T(strcmp(T.hemi,hemi) & ismember(T.lobe,lobe),:);
        if ~isempty(Temp)
            for loc=locs
                switch loc{1}
                    case 'SpSp'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'EVEN_N-T'),:);
                    case 'PiPi'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_H-N') & strcmp(Temp.Contrast2,'EVEN_H-N'),:);
                    case 'PrPr'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_PROS_ALL'),:);
                    case 'SpPr'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_N-T') | (strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_N-T')) | (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_N-T')) | (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_N-T'))),:);
                    case 'SpPi'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_N-T') & strcmp(Temp.Contrast2,'EVEN_H-N') | (strcmp(Temp.Contrast1,'EVEN_N-T') & strcmp(Temp.Contrast2,'ODD_H-N')) | (strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'ODD_H-N')) | (strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'EVEN_H-N'))),:);
                    case 'PiPr'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_H-N') | (strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_H-N')) | (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_H-N')) | (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_H-N'))),:);
   
                end
                for is=1:length(subjects)
                    subj=subjects{is};
                    Temp3 = Temp2(strcmp(Temp2.subject,subj),:);
                    data(is,i) = mean(Temp3.Coef);
                end
                i=i+1;
            end
        end
    end
end

means = mean(data);
means_mat = reshape(means,[6,2]);
errs = std(data)./sqrt(length(subjects));
errs_mat = reshape(errs,[6,2]);

h=figure;
set(h,'Position',[100 100 700 300])
[h, hE]=barwitherr(errs_mat',means_mat');

for ib=1:length(h)   
    h(ib).FaceColor=colors{ib};
    h(ib).LineWidth=1;              
end

set(hE,'Linewidth',1)
set(gca,'fontsize',18)
labels = {'Temporal'};
xticklabels(gca,{'LH','RH'})
ylabel('Spatial correlations')
legend(locs,'fontsize',18)
title('N=17 split half runs spcorr')
grid on

saveas(gcf,[figures_dir filesep 'spcorr_n17_splitHalfRuns_ProsSpeechPitch'],'png')
saveas(gcf,[figures_dir filesep 'spcorr_n17_splitHalfRuns_ProsSpeechPitch'],'pdf')

%% spcorr - no SpPi

T_within = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_within_evenodd_table.csv'], 'Delimiter',',');
T_between = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_between_evenodd_table.csv'], 'Delimiter',',');
T = [T_within;T_between];

hemis = {'LH','RH'};
lobes = {'Temporal'};
locs = {'SpSp','PiPi','PrPr','SpPr','PiPr'};
nCond = length(locs)*length(hemis)*length(lobes);
locations = [1 2 3 4 5 7 8 9 10 11 12];
colors = {[0 1 1],[0 1 0],[1 0 1],[0.5 0.5 1],[1 0.5 1]};

subjects = {'837_FED_20220414a_3T1_PL2017',...
'881_FED_20220506a_3T1_PL2017',...
'882_FED_20220512a_3T1_PL2017',...
'883_FED_20220512b_3T1_PL2017',...
'884_FED_20220513a_3T1_PL2017',...
'885_FED_20220513b_3T1_PL2017',...
'886_FED_20220513c_3T1_PL2017',...
'890_FED_20220518b_3T1_PL2017',...
'831_FED_20220525a_3T1_PL2017',...
'842_FED_20220525b_3T1_PL2017',...
'891_FED_20220525c_3T1_PL2017',...
'684_FED_20220526a_3T1_PL2017',...
'892_FED_20220526b_3T1_PL2017',...
'893_FED_20220606a_3T1_PL2017',...
'865_FED_20220608b_3T1_PL2017',...
'894_FED_20220613a_3T1_PL2017',...
'895_FED_20220613b_3T1_PL2017'...
};

data = nan(length(subjects),nCond);
i = 1;
for hemi = hemis
    for lobe = lobes
        Temp = T(strcmp(T.hemi,hemi) & ismember(T.lobe,lobe),:);
        if ~isempty(Temp)
            for loc = locs
                switch loc{1}
                    case 'SpSp'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'EVEN_N-T'),:);
                    case 'PiPi'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_H-N') & strcmp(Temp.Contrast2,'EVEN_H-N'),:);
                    case 'PrPr'
                        Temp2 = Temp(strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_PROS_ALL'),:);
                    case 'SpPr'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_N-T')) | ...
                                     (strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_N-T')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_N-T')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_N-T')),:);
                    case 'SpPi'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_N-T') & strcmp(Temp.Contrast2,'EVEN_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'EVEN_N-T') & strcmp(Temp.Contrast2,'ODD_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'ODD_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_N-T') & strcmp(Temp.Contrast2,'EVEN_H-N')),:);
                    case 'PiPr'
                        Temp2 = Temp((strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'EVEN_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'ODD_H-N')) | ...
                                     (strcmp(Temp.Contrast1,'ODD_PROS_ALL') & strcmp(Temp.Contrast2,'EVEN_H-N')),:);
                end

                for is = 1:length(subjects)
                    subj = subjects{is};
                    Temp3 = Temp2(strcmp(Temp2.subject,subj),:);
                    data(is,i) = mean(Temp3.Coef);
                end
                i = i + 1;
            end
        end
    end
end

if any(isnan(data(:)))
    error('data contains NaN values; check missing subject/condition/hemi combinations before plotting.');
end

means = mean(data);
means_mat = reshape(means,[5,2]);

errs = std(data)./sqrt(length(subjects));
errs_mat = reshape(errs,[5,2]);

% data columns are ordered by locs within hemisphere:
% LH: SpSp, PiPi, PrPr, SpPr, PiPr
% RH: SpSp, PiPi, PrPr, SpPr, PiPr

% Speech benchmark: sqrt(SpSp * PrPr) on raw-r scale, then back to Fisher z
z_SpSp = [data(:,1), data(:,6)];
z_PrPr = [data(:,3), data(:,8)];
r_SpSp = tanh(z_SpSp);
r_PrPr = tanh(z_PrPr);
comparison_speech_subj = atanh(sqrt(r_SpSp .* r_PrPr));
comparison_speech = mean(comparison_speech_subj);

% Pitch benchmark: sqrt(PiPi * PrPr) on raw-r scale, then back to Fisher z
z_PiPi = [data(:,2), data(:,7)];
r_PiPi = tanh(z_PiPi);
comparison_pitch_subj = atanh(sqrt(r_PiPi .* r_PrPr));
comparison_pitch = mean(comparison_pitch_subj);

h = figure;
set(h,'Position',[100 100 700 300])
[h, hE] = barwitherr(errs_mat',means_mat');

for ib = 1:length(h)
    h(ib).FaceColor = colors{ib};
    h(ib).LineWidth = 1;
end

hold on
plot([1.25 1.35],[comparison_pitch(1) comparison_pitch(1)],'Color',colors{5},'LineWidth',3)
plot([2.25 2.35],[comparison_pitch(2) comparison_pitch(2)],'Color',colors{5},'LineWidth',3)
plot([1.10 1.20],[comparison_speech(1) comparison_speech(1)],'Color',colors{4},'LineWidth',3)
plot([2.10 2.20],[comparison_speech(2) comparison_speech(2)],'Color',colors{4},'LineWidth',3)

set(hE,'Linewidth',1)
set(gca,'fontsize',18)
labels = {'Temporal'};
xticklabels(gca,{'LH','RH'})
ylabel('Spatial correlation (Fisher z)')
legend(locs,'fontsize',18)
title('N=17 split half runs spcorr')
grid on

saveas(gcf,[figures_dir filesep 'spcorr_n17_splitHalfRuns_ProsSpeechPitch_noSpPi'],'png')
saveas(gcf,[figures_dir filesep 'spcorr_n17_splitHalfRuns_ProsSpeechPitch_noSpPi'],'pdf')


%% LME spcorr - pitch-pros

lobe = 'Temporal';

T_within = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_within_evenodd_table.csv'], 'Delimiter',',');
T_between = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_between_evenodd_table.csv'], 'Delimiter',',');
T = [T_within; T_between];

condition = cell(height(T),1);
condition(strcmp(T.Contrast1,'ODD_PROS_ALL') & strcmp(T.Contrast2,'EVEN_PROS_ALL')) = {'PrPr'};
condition(strcmp(T.Contrast1,'ODD_H-N') & strcmp(T.Contrast2,'EVEN_H-N')) = {'PiPi'};

condition(strcmp(T.Contrast1,'EVEN_PROS_ALL') & strcmp(T.Contrast2,'EVEN_H-N')) = {'PiPr'};
condition(strcmp(T.Contrast1,'ODD_PROS_ALL')  & strcmp(T.Contrast2,'EVEN_H-N')) = {'PiPr'};
condition(strcmp(T.Contrast1,'EVEN_PROS_ALL') & strcmp(T.Contrast2,'ODD_H-N'))  = {'PiPr'};
condition(strcmp(T.Contrast1,'ODD_PROS_ALL')  & strcmp(T.Contrast2,'ODD_H-N'))  = {'PiPr'};

% Safely add/replace condition column
if ismember('condition', T.Properties.VariableNames)
    T.condition = condition;
else
    T = [T, table(condition)];
end

% find empty cells
emptyCells = cellfun(@isempty, T.condition);

% remove empty cells
Tn = T;
Tn(emptyCells,:) = [];

Tn.condition = categorical(Tn.condition);

%%%%% Create one observed PiPr value and one Geometric reference per subject x hemi
Tnn = table;

% table to keep track of excluded subject/hemi cases
excluded_cases = table('Size',[0 5], ...
    'VariableTypes', {'string','string','double','double','string'}, ...
    'VariableNames', {'subject','hemi','r_PrPr','r_PiPi','reason'});

subjects = unique(Tn.subject(Tn.condition=='PiPr'));
hemis = unique(Tn.hemi);

for si = 1:length(subjects)
    for hi = 1:length(hemis)

        subj = subjects{si};
        hemi = hemis{hi};

        % ----- observed PiPr: average across the 4 odd/even combinations -----
        PiPr_vals = Tn.Coef(strcmp(Tn.subject,subj) & ...
                            strcmp(Tn.hemi,hemi) & ...
                            Tn.condition=='PiPr');

        if isempty(PiPr_vals)
            error('Missing PiPr values for subject %s, hemi %s.', subj, hemi);
        end

        if numel(PiPr_vals) ~= 4
            error('Expected 4 PiPr values for subject %s, hemi %s, found %d.', ...
                subj, hemi, numel(PiPr_vals));
        end

        z_PiPr_mean = mean(PiPr_vals);

        Temp_PiPr = Tn(strcmp(Tn.subject,subj) & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='PiPr', :);
        Temp_PiPr = Temp_PiPr(1,:);
        Temp_PiPr.condition = {'PiPr'};
        Temp_PiPr.Contrast1 = {'mean_PiPr'};
        Temp_PiPr.Contrast2 = {'mean_PiPr'};
        Temp_PiPr.Coef = z_PiPr_mean;

        % ----- expected benchmark from PrPr and PiPi -----
        PrPr = Tn.Coef(strcmp(Tn.subject,subj) & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='PrPr');

        PiPi = Tn.Coef(strcmp(Tn.subject,subj) & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='PiPi');

        if isempty(PrPr)
            error('Missing PrPr value for subject %s, hemi %s.', subj, hemi);
        end
        if isempty(PiPi)
            error('Missing PiPi value for subject %s, hemi %s.', subj, hemi);
        end
        if numel(PrPr) ~= 1
            error('Expected one PrPr value for subject %s, hemi %s, found %d.', ...
                subj, hemi, numel(PrPr));
        end
        if numel(PiPi) ~= 1
            error('Expected one PiPi value for subject %s, hemi %s, found %d.', ...
                subj, hemi, numel(PiPi));
        end

        % PrPr and PiPi are already Fisher z values
        r_PrPr = tanh(PrPr);
        r_PiPi = tanh(PiPi);

        % Exclude if either within-task raw correlation is non-positive
        if r_PrPr <= 0 || r_PiPi <= 0
            excluded_cases = [excluded_cases; ...
                {string(subj), string(hemi), r_PrPr, r_PiPi, "non-positive within-task correlation"}];
            warning('Excluding subject %s, hemi %s from pitch-prosody spcorr benchmark comparison because r_PrPr=%.4f, r_PiPi=%.4f.', ...
                subj, hemi, r_PrPr, r_PiPi);
            continue
        end

        % Geometric benchmark is defined on the raw-r scale
        r_geom = sqrt(r_PrPr * r_PiPi);
        z_geom = atanh(r_geom);

        Temp_G = Tn(strcmp(Tn.subject,subj) & ...
                    strcmp(Tn.hemi,hemi) & ...
                    Tn.condition=='PrPr', :);
        Temp_G = Temp_G(1,:);
        Temp_G.condition = {'Geometric'};
        Temp_G.Contrast1 = {'none'};
        Temp_G.Contrast2 = {'none'};
        Temp_G.Coef = z_geom;

        % append only valid subject/hemi pairs
        Tnn = [Tnn; Temp_PiPr; Temp_G];
    end
end

% Show excluded cases in command window
disp('Excluded subject/hemi cases for pitch-prosody spcorr benchmark comparison:')
disp(excluded_cases)

% Save excluded cases to file for reporting
writetable(excluded_cases, [results_dir filesep 'stats' filesep 'spcorr' filesep 'excluded_cases_Pitch_' lobe '.csv'])

Tnn.subject = categorical(Tnn.subject);
Tnn.condition = categorical(Tnn.condition);
Tnn.condition = removecats(Tnn.condition);
Tnn.condition = reordercats(Tnn.condition, {'Geometric','PiPr'});

Tnn_R = Tnn(strcmp(Tnn.hemi,'RH'), :);
Tnn_L = Tnn(strcmp(Tnn.hemi,'LH'), :);

% sanity check: equal counts of PiPr and Geometric within each hemisphere
disp('Condition counts, LH:')
tabulate(Tnn_L.condition)
disp('Condition counts, RH:')
tabulate(Tnn_R.condition)

% Random intercept only: with exactly 2 rows per participant (observed, Geometric), a random
% slope for condition cannot be separated from the residual. This model is equivalent to a
% paired t-test; with Satterthwaite DF = N - 1.
formula = 'Coef ~ condition + (1|subject)';

lme_R = fitlme(Tnn_R, formula);
LMER_tab = lme2table(lme_R,'satterthwaite');
writetable(LMER_tab, [results_dir filesep 'stats' filesep 'spcorr' filesep 'LME_Pitch_R_' lobe '.csv'])

lme_L = fitlme(Tnn_L, formula);
LMEL_tab = lme2table(lme_L,'satterthwaite');
writetable(LMEL_tab, [results_dir filesep 'stats' filesep 'spcorr' filesep 'LME_Pitch_L_' lobe '.csv'])

%%%%%% Save N summary for combined paper table

% Included = unique subjects that remained in each final hemisphere table
nIncluded_L = numel(unique(string(Tnn_L.subject)));
nIncluded_R = numel(unique(string(Tnn_R.subject)));

% Excluded = rows in excluded_cases for each hemisphere
nExcluded_L = sum(strcmp(excluded_cases.hemi, "LH"));
nExcluded_R = sum(strcmp(excluded_cases.hemi, "RH"));

summary_L = table(nIncluded_L, nExcluded_L, ...
    'VariableNames', {'nIncluded','nExcluded'});
summary_R = table(nIncluded_R, nExcluded_R, ...
    'VariableNames', {'nIncluded','nExcluded'});

writetable(summary_L, [results_dir filesep 'stats' filesep 'spcorr' filesep 'summary_LME_Pitch_L_' lobe '.csv'])
writetable(summary_R, [results_dir filesep 'stats' filesep 'spcorr' filesep 'summary_LME_Pitch_R_' lobe '.csv'])

%% LME spcorr - speech-pros

lobe = 'Temporal';

T_within = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_within_evenodd_table.csv'], 'Delimiter',',');
T_between = readtable([spcorr_dir filesep 'expt1_tasks_spcorr_between_evenodd_table.csv'], 'Delimiter',',');
T = [T_within; T_between];

condition = cell(height(T),1);
condition(strcmp(T.Contrast1,'ODD_PROS_ALL') & strcmp(T.Contrast2,'EVEN_PROS_ALL')) = {'PrPr'};
condition(strcmp(T.Contrast1,'ODD_N-T') & strcmp(T.Contrast2,'EVEN_N-T')) = {'SpSp'};

condition(strcmp(T.Contrast1,'EVEN_PROS_ALL') & strcmp(T.Contrast2,'EVEN_N-T')) = {'SpPr'};
condition(strcmp(T.Contrast1,'ODD_PROS_ALL')  & strcmp(T.Contrast2,'EVEN_N-T')) = {'SpPr'};
condition(strcmp(T.Contrast1,'EVEN_PROS_ALL') & strcmp(T.Contrast2,'ODD_N-T'))  = {'SpPr'};
condition(strcmp(T.Contrast1,'ODD_PROS_ALL')  & strcmp(T.Contrast2,'ODD_N-T'))  = {'SpPr'};

% Safely add/replace condition column
if ismember('condition', T.Properties.VariableNames)
    T.condition = condition;
else
    T = [T, table(condition)];
end

% find empty cells
emptyCells = cellfun(@isempty, T.condition);

% remove empty cells
Tn = T;
Tn(emptyCells,:) = [];

Tn.condition = categorical(Tn.condition);

% add UIDs - to handle subjects who did speech and prosody in different sessions
UIDs = regexp(Tn.subject, '^\d+', 'match', 'once');
UIDs = categorical(UIDs);
Tn.UID = UIDs;

%%%%% Create one observed SpPr value and one Geometric reference per UID x hemi
Tnn = table;

% table to keep track of excluded UID/hemi cases
excluded_cases = table('Size',[0 5], ...
    'VariableTypes', {'string','string','double','double','string'}, ...
    'VariableNames', {'UID','hemi','r_PrPr','r_SpSp','reason'});

subjects = unique(Tn.UID(Tn.condition=='SpPr'));
hemis = unique(Tn.hemi);

for si = 1:length(subjects)
    for hi = 1:length(hemis)

        uid = subjects(si);
        hemi = hemis{hi};

        % ----- observed SpPr: average across the 4 odd/even combinations -----
        SpPr_vals = Tn.Coef(Tn.UID==uid & ...
                            strcmp(Tn.hemi,hemi) & ...
                            Tn.condition=='SpPr');

        if isempty(SpPr_vals)
            error('Missing SpPr values for UID %s, hemi %s.', char(uid), hemi);
        end

        if numel(SpPr_vals) ~= 4
            error('Expected 4 SpPr values for UID %s, hemi %s, found %d.', ...
                char(uid), hemi, numel(SpPr_vals));
        end

        z_SpPr_mean = mean(SpPr_vals);

        Temp_SpPr = Tn(Tn.UID==uid & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='SpPr', :);
        Temp_SpPr = Temp_SpPr(1,:);
        Temp_SpPr.condition = {'SpPr'};
        Temp_SpPr.Contrast1 = {'mean_SpPr'};
        Temp_SpPr.Contrast2 = {'mean_SpPr'};
        Temp_SpPr.Coef = z_SpPr_mean;

        % ----- expected benchmark from PrPr and SpSp -----
        PrPr = Tn.Coef(Tn.UID==uid & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='PrPr');

        SpSp = Tn.Coef(Tn.UID==uid & ...
                       strcmp(Tn.hemi,hemi) & ...
                       Tn.condition=='SpSp');

        if isempty(PrPr)
            error('Missing PrPr value for UID %s, hemi %s.', char(uid), hemi);
        end
        if isempty(SpSp)
            error('Missing SpSp value for UID %s, hemi %s.', char(uid), hemi);
        end
        if numel(PrPr) ~= 1
            error('Expected one PrPr value for UID %s, hemi %s, found %d.', ...
                char(uid), hemi, numel(PrPr));
        end
        if numel(SpSp) ~= 1
            error('Expected one SpSp value for UID %s, hemi %s, found %d.', ...
                char(uid), hemi, numel(SpSp));
        end

        % PrPr and SpSp are already Fisher z values
        r_PrPr = tanh(PrPr);
        r_SpSp = tanh(SpSp);

        % Exclude if either within-task raw correlation is non-positive
        if r_PrPr <= 0 || r_SpSp <= 0
            excluded_cases = [excluded_cases; ...
                {string(char(uid)), string(hemi), r_PrPr, r_SpSp, "non-positive within-task correlation"}];
            warning('Excluding UID %s, hemi %s from speech-prosody spcorr benchmark comparison because r_PrPr=%.4f, r_SpSp=%.4f.', ...
                char(uid), hemi, r_PrPr, r_SpSp);
            continue
        end

        % Geometric benchmark is defined on the raw-r scale
        r_geom = sqrt(r_PrPr * r_SpSp);
        z_geom = atanh(r_geom);

        Temp_G = Tn(Tn.UID==uid & ...
                    strcmp(Tn.hemi,hemi) & ...
                    Tn.condition=='PrPr', :);
        Temp_G = Temp_G(1,:);
        Temp_G.condition = {'Geometric'};
        Temp_G.Contrast1 = {'none'};
        Temp_G.Contrast2 = {'none'};
        Temp_G.Coef = z_geom;

        % append only valid UID/hemi pairs
        Tnn = [Tnn; Temp_SpPr; Temp_G];
    end
end

% Show excluded cases in command window
disp('Excluded UID/hemi cases for speech-prosody spcorr benchmark comparison:')
disp(excluded_cases)

% Save excluded cases to file for reporting
writetable(excluded_cases, [results_dir filesep 'stats' filesep 'spcorr' filesep 'excluded_cases_Speech_' lobe '.csv'])

Tnn.subject = categorical(Tnn.subject);
Tnn.condition = categorical(Tnn.condition);
Tnn.condition = removecats(Tnn.condition);
Tnn.condition = reordercats(Tnn.condition, {'Geometric','SpPr'});

Tnn_R = Tnn(strcmp(Tnn.hemi,'RH'), :);
Tnn_L = Tnn(strcmp(Tnn.hemi,'LH'), :);

% sanity check: equal counts of SpPr and Geometric within each hemisphere
disp('Condition counts, LH:')
tabulate(Tnn_L.condition)
disp('Condition counts, RH:')
tabulate(Tnn_R.condition)

% Random intercept only (see the pitch section), grouped by UID rather than by the
% session-specific subject string: for participants who did the speech and prosody tasks in
% different sessions, the SpPr and Geometric rows can carry different subject strings,
% which would break the pairing.
formula = 'Coef ~ condition + (1|UID)';

lme_R = fitlme(Tnn_R, formula);
LMER_tab = lme2table(lme_R,'satterthwaite');
writetable(LMER_tab, [results_dir filesep 'stats' filesep 'spcorr' filesep 'LME_Speech_R_' lobe '.csv'])

lme_L = fitlme(Tnn_L, formula);
LMEL_tab = lme2table(lme_L,'satterthwaite');
writetable(LMEL_tab, [results_dir filesep 'stats' filesep 'spcorr' filesep 'LME_Speech_L_' lobe '.csv'])

%%%%%% Save N summary for combined paper table

% Included = unique UIDs that remained in each final hemisphere table
nIncluded_L = numel(unique(string(Tnn_L.UID)));
nIncluded_R = numel(unique(string(Tnn_R.UID)));

% Excluded = rows in excluded_cases for each hemisphere
nExcluded_L = sum(strcmp(excluded_cases.hemi, "LH"));
nExcluded_R = sum(strcmp(excluded_cases.hemi, "RH"));

summary_L = table(nIncluded_L, nExcluded_L, ...
    'VariableNames', {'nIncluded','nExcluded'});
summary_R = table(nIncluded_R, nExcluded_R, ...
    'VariableNames', {'nIncluded','nExcluded'});

writetable(summary_L, [results_dir filesep 'stats' filesep 'spcorr' filesep 'summary_LME_Speech_L_' lobe '.csv'])
writetable(summary_R, [results_dir filesep 'stats' filesep 'spcorr' filesep 'summary_LME_Speech_R_' lobe '.csv'])