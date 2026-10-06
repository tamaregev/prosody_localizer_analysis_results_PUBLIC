%% Definitions
project_dir = '/Users/tamaregev/Dropbox/postdoc/Fedorenko/Prosody/Localizer/PUBLIC';%replace this with the location where this directory exists
results_dir = [project_dir filesep 'Results'];
figures_dir = [project_dir filesep 'Figures'];
analysis_dir = [project_dir filesep 'Analysis-Results_PUBLIC'];

%addpath(genpath('/Users/tamaregev/Dropbox/MATLAB/lab/myFunctions'))
%addpath('/Users/tamaregev/Dropbox/MATLAB/lab/CommonResources')%for suptitle

% functions needed:
%   Confidence.m
%   barwitherror.m
%   plotmROI_prosLoc.m
%   suptitle.m

N=51;
results_toolbox_dir = [results_dir '/n' num2str(N) '_results'];
parcels_dir = [results_toolbox_dir filesep 'SUM_percent01'];
GSS_dir = [parcels_dir '/prosLocLoc_A-B_C-D_sum_top10percent_n51_20240212'];

stats_file = 'spm_ss_GcSS_results_0001.Stats.csv';
statsT = readtable([GSS_dir filesep stats_file]);
allROIs = statsT.ROI(statsT.inter_subjectOverlap>=0.5);
ROIanaT = readtable([results_dir filesep 'Prosody_SUM_ROIs.xlsx']);

overlap_th = 0.9;
overlapstr=num2str(overlap_th);

% group ROIs
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);
rois_RH = ROIanaT.ROI(strcmp(ROIanaT.Hemisphere,{'RH'}));
rois_LH = ROIanaT.ROI(strcmp(ROIanaT.Hemisphere,{'LH'}));

%lobes
rois_frontal = ROIanaT.ROI(strcmp(ROIanaT.Lobe,{'Frontal'}));
rois_temporal = ROIanaT.ROI(strcmp(ROIanaT.Lobe,{'Temporal'}));
rois_medial = ROIanaT.ROI(strcmp(ROIanaT.Lobe,{'Frontal-Medial'}));

%sub-lobes
rois_frontal_medial = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Frontal-Medial'}));
rois_frontal_lateral = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Frontal-Lateral'}));
rois_frontal_inferior = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Frontal-Inferior'}));
rois_temporal_lateral = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Temporal-Lateral'}));
rois_temporal_inferior = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Temporal-Inferior'}));
rois_temporal_parietal = ROIanaT.ROI(strcmp(ROIanaT.Sub_lobe,{'Temporal-Parietal'}));

%hemispheres
selected_RH = selected(ismember(selected,rois_RH));
selected_LH = selected(ismember(selected,rois_LH));

selected_RH_frontal = selected_RH(ismember(selected_RH,rois_frontal));
selected_LH_frontal = selected_LH(ismember(selected_LH,rois_frontal));
selected_RH_temporal = selected_RH(ismember(selected_RH,rois_temporal));
selected_LH_temporal = selected_LH(ismember(selected_LH,rois_temporal));
selected_RH_medial = selected_RH(ismember(selected_RH,rois_medial));
selected_LH_medial = selected_LH(ismember(selected_LH,rois_medial));

selected_RH_frontal_medial = selected_RH_medial;
selected_LH_frontal_medial = selected_LH_medial;
selected_RH_frontal_lateral = selected_RH_frontal(ismember(selected_RH_frontal,rois_frontal_lateral));
selected_LH_frontal_lateral = selected_LH_frontal(ismember(selected_LH_frontal,rois_frontal_lateral));
selected_RH_frontal_inferior = selected_RH_frontal(ismember(selected_RH_frontal,rois_frontal_inferior));
selected_LH_frontal_inferior = selected_LH_frontal(ismember(selected_LH_frontal,rois_frontal_inferior));
selected_RH_temporal_lateral = selected_RH_temporal(ismember(selected_RH_temporal,rois_temporal_lateral));
selected_LH_temporal_lateral = selected_LH_temporal(ismember(selected_LH_temporal,rois_temporal_lateral));
selected_RH_temporal_inferior = selected_RH_temporal(ismember(selected_RH_temporal,rois_temporal_inferior));
selected_LH_temporal_inferior = selected_LH_temporal(ismember(selected_LH_temporal,rois_temporal_inferior));
selected_RH_temporal_parietal = selected_RH_temporal(ismember(selected_RH_temporal,rois_temporal_parietal));
selected_LH_temporal_parietal = selected_LH_temporal(ismember(selected_LH_temporal,rois_temporal_parietal));


%% GSS pros fROI = pros, Effect = prosLoc
%% Parcel selection - Fraction of subject overlap vs. average localizer mask size - Supplementary Fig. 1

overlap_th = 0.5;
overlapstr=num2str(overlap_th);

allselected = statsT.ROI(statsT.inter_subjectOverlap>=0.5);
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);
idx=ismember(allselected,selected);

whichROIs = allselected(idx);%should match T

figure
colormap jet
scatter(statsT.averageLocalizerMaskSize(idx),statsT.inter_subjectOverlap(idx),60,selected,'filled')%color chronological 
set(gca,'fontsize',20)
xlabel('Average localizer mask size')
ylabel('Fraction of subject overlap')
h=colorbar;
ylabel(h,'T value')
hold on
xlims = get(gca,'xlim');
line([xlims],[0.9 0.9],'Color','k','LineStyle','-.')
text(statsT.averageLocalizerMaskSize(idx)+10,statsT.inter_subjectOverlap(idx)+0.01,num2str(statsT.ROI(idx)),'fontsize',14)
saveas(gcf,[figures_dir filesep 'ParcelsSizeOverlapScatter_Overlap>0' overlapstr(end)],'fig')
saveas(gcf,[figures_dir filesep 'ParcelsSizeOverlapScatter_Overlap>0' overlapstr(end)],'png')
saveas(gcf,[figures_dir filesep 'ParcelsSizeOverlapScatter_Overlap>0' overlapstr(end)],'pdf')

%% Prosody 6 conds, all participants, all ROIs - prep

overlap_th = 0.9;
overlapstr=num2str(overlap_th);

selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);

Parcels = 'FullExpt_prosLocn51SUM';
LocName = 'prosLoc';
LocContrast = 'PROS_ALL';
EffectsName = 'prosLoc';
EffectsContrast = 'ABCDEF';
date = '20240221';

effects = {'A','B','C','D','E','F'};
colors = {[1 0 0],[1 0.5 0.5],[0 0 1],[0.5 0.5 1],[0.5 0.5 0.5],[0.8 0.8 0.8]};

ylims = [-1 2.5];

%%%%%%%%%%%% always the same:
tag = [Parcels 'Parcels_' LocName 'Loc_' LocContrast '_' EffectsName 'Effect_' EffectsContrast '_n' num2str(N) '_' date];

folder = [parcels_dir filesep tag];
filename = 'spm_ss_mROI_data.csv';
T = readtable([folder filesep filename]);

condition_names = {'SP+','SP-','NP+','NP-','InvP+','InvP-'};

%% Average all
whichROIs = selected;%should match T

ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';

avgfROIs = true;
displayStats = false;
displayIndividuals = true;


figure
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
set(gcf,'Position',[10 10 400 500])

ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')

title(['All selected ROIs. Overlap th = ' num2str(overlap_th)] )

saveas(gcf,[figures_dir filesep 'Prosody_parcels_prosodyEffects_fROIs_All_OverlapTh' strrep(num2str(overlap_th),'.','_')],'pdf')

%% Average LH and RH
figure
set(gcf,'Position',[10 10 1100 400])

ylims = [-1 3.2];

subplot(1,2,1)

whichROIs = selected_LH;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',20)
legend(condition_names,'Location','northeastoutside')
title('LH' )

pause(0.5)

subplot(1,2,2)

whichROIs = selected_RH;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
yticklabels({});
ylabel('')
legend off
set(gca,'fontsize',20)
legend(condition_names,'Location','northeastoutside')

title('RH' )

pause(0.5)

hs=suptitle(['Selected ROIs: Overlap th = ' num2str(overlap_th)] );
set(hs,'fontsize',20)

saveas(gcf,[figures_dir filesep 'Prosody_parcels_prosodyEffects_fROIs_byHemi_OverlapTh' strrep(num2str(overlap_th),'.','_')],'pdf')

%% Average (LH, RH) x (Medial, Frontal, Temporal)

ylims = [-2 3.6];

figure
set(gcf,'Position',[10 10 600 800])

pause(0.5)


subplot(3,2,1)

whichROIs = selected_LH_temporal;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')
title('LH Temporal' )

pause(0.5)

subplot(3,2,2)

whichROIs = selected_RH_temporal;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')
title('RH Temporal' )
pause(0.5)

subplot(3,2,3)

whichROIs = selected_LH_frontal;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')
title('LH Frontal' )
pause(0.5)

subplot(3,2,4)

whichROIs = selected_RH_frontal;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);

set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')

title('RH Frontal' )

pause(0.5)

%%%%%%%%%%%medial
subplot(3,2,5)

whichROIs = selected_LH_medial;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);
set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')
title('LH Medial' )
pause(0.5)

subplot(3,2,6)

whichROIs = selected_RH_medial;%should match T
ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
whicherr = 'stderr';
avgfROIs = true;
displayStats = false;
displayIndividuals = true;
[h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
ylim(ylims)
xticks((1:6))
xticklabels(condition_names);

set(gca,'fontsize',16)
legend(condition_names,'Location','northeastoutside')

title('RH Medial' )

pause(0.5)


hs=suptitle(['Selected ROIs: Overlap th = ' num2str(overlap_th)] );
set(hs,'fontsize',20)

saveas(gcf,[figures_dir filesep 'Prosody_parcels_prosodyEffects_fROIs_byHemiLobe_OverlapTh' strrep(num2str(overlap_th),'.','_')],'pdf')

%% Each ROI effects

ylims = [-0.4 2.3];


for roi = allROIs'
 %for roi = [13,6]   
    figure
    set(gcf,'Position',[10 10 400 800])
      
    whichROIs = roi;
    ROIstring = arrayfun(@num2str,whichROIs,'Uni',0);%if want to give names
    whicherr = 'stderr';
    avgfROIs = false;
    displayStats = false;
    displayIndividuals = false;
    [h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors);
    ylim(ylims)
    xticks((1:6))
    xticklabels(condition_names);
    set(gca,'fontsize',16)
    legend(condition_names,'Location','northeastoutside')
    title(['ROI ' num2str(roi)])
    
    pause(0.5)
    saveas(gcf,[figures_dir filesep 'Prosody_parcels_prosodyEffects_fROI_' num2str(roi)],'pdf')

end

%% plot prosody parcels on the brain
%for this part, spm and freesurfer need to be installed on your machine

%init spm and evlab toolbox:
addpath('/Users/tamaregev/Dropbox/MATLAB/Toolbox/spm-main')%spm folder
fs_dir = '/Applications/freesurfer/7.4.1/';%freesurfer folder
addpath(genpath(fs_dir));

gerber_toolbox_path = [pwd filesep 'Gerber_toolbox'];
addpath(genpath(gerber_toolbox_path));

% SUM percent 10
surf_dir = [GSS_dir filesep 'surf'];
mkdir(surf_dir)

parcels_image=[GSS_dir filesep 'fROIs.nii'];
stats_file = 'spm_ss_GcSS_results_0001.Stats.csv';

statsT = readtable([GSS_dir filesep stats_file]);

overlap_th = 0.9;
overlapstr=num2str(overlap_th);

allselected = statsT.ROI(statsT.inter_subjectOverlap>=0.5);
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);

%read parcels nifti:
HeaderInfo = spm_vol(parcels_image);
a = spm_read_vols(HeaderInfo);

%plot
bash_path=getenv('PATH');
setenv('PATH',[bash_path,':/Applications/freesurfer/7.4.1/',':/Applications/freesurfer/7.4.1/bin',':/Applications/freesurfer/7.4.1/subjects']);

numROIs = length(unique(a))-1;
colors = jet(numROIs);
% light_pink = [218, 3, 252]./255;
% purple = [218, 3, 252]./255;
% R = linspace(purple(1),light_pink(1),numROIs);
% G = linspace(purple(2),light_pink(2),numROIs);
% B = linspace(purple(3),light_pink(3),numROIs);
% colors = [R', G', B'];

clim = [1 max(allselected)];

%whichROIs = 1:numROIs;
whichROIs = selected;

inflated = true;


%%%%%%% Lateral view
h=figure;set(h,'position',[10 10 1000 600])
whichHemi = 'lh';
subplot(1,2,1)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'lateral');

whichHemi = 'rh';
subplot(1,2,2)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'lateral');
hs=suptitle(['SUM percent10 ' 'selected overlap th: ' num2str(overlap_th) ' , ' num2str(length(selected))]);
set(hs,'fontsize',22)

saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_lateral_SUM01_overlap_th_0' overlapstr(end) '_rainbow'],'fig')
saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_lateral_SUM01_overlap_th_0' overlapstr(end) '_rainbow'] ,'png')


%%%%%%% Medial view
h=figure;set(h,'position',[10 10 1000 600])
whichHemi = 'lh';
subplot(1,2,1)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'medial');

whichHemi = 'rh';
subplot(1,2,2)
[h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'medial');
hs=suptitle(['SUM percent10 ' 'selected overlap th: ' num2str(overlap_th) ' , ' num2str(length(selected))]);
set(hs,'fontsize',22)

saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_medial_SUM01_overlap_th_0' overlapstr(end) '_rainbow'],'fig')
saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_medial_SUM01_overlap_th_0' overlapstr(end) '_rainbow'],'png')

%% plot individual parcels
%must run after previous
overlap_th = 0.5;
overlapstr=num2str(overlap_th);

%selected = statsT.ROI;
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);

for iroi=2:length(selected)

    numROIs = length(unique(a))-1;
    colors = jet(numROIs);
    clim = [1 max(selected)];
    
    %whichROIs = 1:numROIs;
    whichROIs = selected(iroi);
    light_pink = [218, 3, 252]./255;
    purple = [218, 3, 252]./255;
    R = linspace(purple(1),light_pink(1),numROIs);
    G = linspace(purple(2),light_pink(2),numROIs);
    B = linspace(purple(3),light_pink(3),numROIs);
    colors = [R', G', B'];

    inflated = true;
    
    %%%%%%% Lateral view
    h=figure;set(h,'position',[10 10 1000 600])
    whichHemi = 'lh';
    subplot(1,2,1)
    [h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0);
    
    whichHemi = 'rh';
    subplot(1,2,2)
    [h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1);
    hs=suptitle(['SUM percent10 ' ' ROI , ' num2str(selected(iroi))]);
    set(hs,'fontsize',22)
    
    saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_SUM01_ROI_' num2str(selected(iroi)) '_lateral'],'fig')
    saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_SUM01_ROI_' num2str(selected(iroi)) '_lateral'],'png')

 %%%%%%% Medial view
    h=figure;set(h,'position',[10 10 1000 600])
    whichHemi = 'lh';
    subplot(1,2,1)
    [h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,0,'medial');
    
    whichHemi = 'rh';
    subplot(1,2,2)
    [h,hs] = plotVol2Surf(fs_dir,surf_dir,HeaderInfo.fname,clim,colors,inflated,whichHemi,whichROIs,1,'medial');
    hs=suptitle(['SUM percent10 ' ' ROI , ' num2str(selected(iroi))]);
    set(hs,'fontsize',22)
    
    saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_SUM01_ROI_' num2str(selected(iroi)) '_medial'],'fig')
    saveas(gcf,[figures_dir filesep 'GSS_prosody_parcels_SUM01_ROI_' num2str(selected(iroi)) '_medial'],'png')


end

%% STATS
%% prep table
stats_file = 'spm_ss_GcSS_results_0001.Stats.csv';
statsT = readtable([GSS_dir filesep stats_file]);
ROIanaT = readtable([results_dir filesep 'Prosody_SUM_ROIs.xlsx']);

overlap_th = 0.9;
selected = statsT.ROI(statsT.inter_subjectOverlap>=overlap_th);

Parcels = 'FullExpt_prosLocn51SUM';
LocName = 'prosLoc';
LocContrast = 'PROS_ALL';
EffectsName = 'prosLoc';
EffectsContrast = 'ABCDEF';
date = '20240221';

subj_info = readtable([project_dir filesep 'Participant_information/Prosody_subjects_unique51.xlsx']);

%%%%%%%%%%%% always the same:
tag = [Parcels 'Parcels_' LocName 'Loc_' LocContrast '_' EffectsName 'Effect_' EffectsContrast '_n' num2str(N) '_' date];
folder = [parcels_dir filesep tag];
filename = 'spm_ss_mROI_data.csv';
T = readtable([folder filesep filename]);
T_selected = T(ismember(T.ROI,selected),:);

UID = nan(size(T_selected.Subject));
ROI_hemi = cell(size(T_selected.Subject));
ROI_lobe = cell(size(T_selected.Subject));
Expt = cell(size(T_selected.Subject));

for is=1:length(UID)
    sp = strsplit(T_selected.Subject{is},'_');
    UID(is) = str2double(sp{1});
    Expt{is} = num2str(subj_info.EXPT(ismember(subj_info.UID,UID(is))));
    ROI_hemi{is} = ROIanaT.Hemisphere{ismember(ROIanaT.ROI,T_selected.ROI(is))};
    ROI_lobe{is} = ROIanaT.Lobe{ismember(ROIanaT.ROI,T_selected.ROI(is))};
end
T_selected.UID = categorical(UID);
T_selected = [T_selected, table(Expt), table(ROI_hemi), table(ROI_lobe)];
T_selected.ROIcat = categorical(T_selected.ROI);
%% test Prosody : A>B, C>D per hemi, lobe, overall

Tstats = table(cell(36,1), cell(36,1), cell(36,1), cell(36,1), ...
               nan(36,1), nan(36,1), nan(36,1), nan(36,1), nan(36,1), nan(36,1), nan(36,1), ...
               'VariableNames', {'Effects', 'Hemisphere', 'Lobe', 'Name', 'Estimate', 'SE', ...
                                 'tStat', 'DF', 'pValue', 'Lower', 'Upper'});

ind = 1;

% A>B
Tstats.Effects{ind} = 'A vs. B';

disp('A vs B')
ROIs = {selected_RH_frontal,selected_RH_medial,selected_RH_temporal,selected_LH_frontal,selected_LH_medial,selected_LH_temporal};
AllROIs = [selected_RH_frontal; selected_RH_medial; selected_RH_temporal; selected_LH_frontal; selected_LH_medial; selected_LH_temporal];
labels = {'RH_frontal','RH_medial','RH_temporal','LH_frontal','LH_medial','LH_temporal'};
hemi = {'RH','RH','RH','LH','LH','LH'};
lobe = {'Lateral frontal','Medial frontal','Temporal','Lateral frontal','Medial frontal','Temporal'};

lme_AB = cell(size(ROIs));
formula = 'EffectSize ~ Effect + (Effect|UID) + (Effect|ROIcat)';
for i=1:length(ROIs)
    Tstats.Hemisphere{ind} = hemi{i}; Tstats.Hemisphere{ind+1} = '';
    Tstats.Lobe{ind} = lobe{i}; Tstats.Lobe{ind+1} = '';

    Ttemp = T_selected(ismember(T_selected.ROI,ROIs{i}) & (strcmp(T_selected.Effect,{'A'}) | strcmp(T_selected.Effect,{'B'})) ,:);
    lme{i} = fitlme(Ttemp,formula);
    TAB{i} = lme2table(lme{i},'satterthwaite');writetable(TAB{i},[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsProsody' filesep 'LME_AB_' labels{i} '.csv'])
    Tstats(ind:ind+1,4:11) = TAB{i}(1:2,1:8);
    
    disp([labels{i} ' ' num2str(lme{i}.Coefficients.pValue(2))])

    ind = ind + 2;
end

% across all ROIs
Ttemp = T_selected(ismember(T_selected.ROI,AllROIs) & (strcmp(T_selected.Effect,{'A'}) | strcmp(T_selected.Effect,{'B'})) ,:);
lmeAllROIs{1} = fitlme(Ttemp,formula);
lme_Tab = lme2table(lmeAllROIs{1},'satterthwaite');
writetable(lme_Tab,[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsProsody' filesep 'LME_AB_AllRegions.csv'])
  


%C>D
Tstats.Effects{ind} = 'C vs. D';

disp('C vs D')
lme_CD = cell(size(ROIs));
formula = 'EffectSize ~ Effect + (Effect|UID) + (Effect|ROIcat)';

for i=1:length(ROIs)
    Tstats.Hemisphere{ind} = hemi{i}; Tstats.Hemisphere{ind+1} = '';
    Tstats.Lobe{ind} = lobe{i}; Tstats.Lobe{ind+1} = '';

    Ttemp = T_selected(ismember(T_selected.ROI,ROIs{i}) & (strcmp(T_selected.Effect,{'C'}) | strcmp(T_selected.Effect,{'D'})) ,:);
    lme{i} = fitlme(Ttemp,formula);
    TCD{i} = lme2table(lme{i},'satterthwaite');writetable(TCD{i},[results_dir filesep 'stats'  filesep 'RegionsProsody_EffectsProsody' filesep  'LME_CD_' labels{i} '.csv'])
    Tstats(ind:ind+1,4:11) = TCD{i}(1:2,1:8);

    disp([labels{i} ' ' num2str(lme{i}.Coefficients.pValue(2))])
    ind = ind + 2;

end
% across all ROIs
Ttemp = T_selected(ismember(T_selected.ROI,AllROIs) & (strcmp(T_selected.Effect,{'C'}) | strcmp(T_selected.Effect,{'D'})) ,:);
lmeAllROIs{2} = fitlme(Ttemp,formula);
lme_Tab = lme2table(lmeAllROIs{2},'satterthwaite');
writetable(lme_Tab,[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsProsody' filesep 'LME_CD_AllRegions.csv'])
  
%E>F
Tstats.Effects{ind} = 'E vs. F';

disp('E vs F')
lme_EF = cell(size(ROIs));
formula = 'EffectSize ~ Effect + (Effect|UID) + (Effect|ROIcat)';
for i=1:length(ROIs)
    Tstats.Hemisphere{ind} = hemi{i}; Tstats.Hemisphere{ind+1} = '';
    Tstats.Lobe{ind} = lobe{i}; Tstats.Lobe{ind+1} = '';

    Ttemp = T_selected(ismember(T_selected.ROI,ROIs{i}) & (strcmp(T_selected.Effect,{'E'}) | strcmp(T_selected.Effect,{'F'})) ,:);
    lme{i} = fitlme(Ttemp,formula);
    TEF{i} = lme2table(lme{i},'satterthwaite');
    writetable(TEF{i},[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsProsody' filesep 'LME_EF_' labels{i} '.csv'])
    Tstats(ind:ind+1,4:11) = TEF{i}(1:2,1:8);

    disp([labels{i} ' ' num2str(lme{i}.Coefficients.pValue(2))])
    ind = ind + 2;

end

% across all ROIs
Ttemp = T_selected(ismember(T_selected.ROI,AllROIs) & (strcmp(T_selected.Effect,{'E'}) | strcmp(T_selected.Effect,{'F'})) ,:);
lmeAllROIs{3} = fitlme(Ttemp,formula);
lme_Tab = lme2table(lmeAllROIs{3},'satterthwaite');
writetable(lme_Tab,[results_dir filesep 'stats' filesep 'RegionsProsody_EffectsProsody' filesep 'LME_EF_AllRegions.csv'])
    
%writetable(Tstats,[results_dir filesep 'stats' filesep 'LME_ProsodyEffectAll.csv'])

%% test intelligibility : A>C, B>D per hemi, lobe

outDir = [results_dir filesep 'stats' filesep 'RegionsProsody_EffectsIntelligibility'];   
if ~exist(outDir, 'dir'), mkdir(outDir); end                                               

% Tstats = table(cell(12,1), cell(12,1), cell(12,1), cell(12,1), ...
%                nan(12,1), nan(12,1), nan(12,1), nan(12,1), nan(12,1), nan(12,1), nan(12,1), ...
%                'VariableNames', {'Effects', 'Hemisphere', 'Lobe', 'Name', 'Estimate', 'SE', ...
%                                  'tStat', 'DF', 'pValue', 'Lower', 'Upper'});
Tstats = table(cell(24,1), cell(24,1), cell(24,1), cell(24,1), ...                          % CHANGED: 12 -> 24
               nan(24,1), nan(24,1), nan(24,1), nan(24,1), nan(24,1), nan(24,1), nan(24,1), ...
'VariableNames', {'Effects', 'Hemisphere', 'Lobe', 'Name', 'Estimate', 'SE', ...
'tStat', 'DF', 'pValue', 'Lower', 'Upper'});

ind = 1;

% A>C
Tstats.Effects{ind} = 'A vs. C';

disp('A vs C')
ROIs = {selected_RH_frontal,selected_RH_medial,selected_RH_temporal,selected_LH_frontal,selected_LH_medial,selected_LH_temporal};
labels = {'RH_frontal','RH_medial','RH_temporal','LH_frontal','LH_medial','LH_temporal'};
lme_AC = cell(size(ROIs));
formula = 'EffectSize ~ Effect + (Effect|UID) + (Effect|ROIcat)';
for i=1:length(ROIs)
    Tstats.Hemisphere{ind} = hemi{i}; Tstats.Hemisphere{ind+1} = '';
    Tstats.Lobe{ind} = lobe{i}; Tstats.Lobe{ind+1} = '';

    Ttemp = T_selected(ismember(T_selected.ROI,ROIs{i}) & (strcmp(T_selected.Effect,{'A'}) | strcmp(T_selected.Effect,{'C'})) ,:);
    lme{i} = fitlme(Ttemp,formula);
    TAC{i} = lme2table(lme{i},'satterthwaite');writetable(TAC{i},[results_dir filesep 'stats' filesep 'LME_AC_' labels{i} '.csv'])
    
    writetable(TAC{i},[outDir filesep 'LME_AC_' labels{i} '.csv'])           % CHANGED: folder

    disp([labels{i} ' ' num2str(TAC{i}.pValue(2))])                          % CHANGED: Satterthwaite p

    Tstats(ind:ind+1,4:11) = TAC{i}(1:2,1:8);
    ind = ind + 2;
end

% across all ROIs
Ttemp = T_selected(ismember(T_selected.ROI,AllROIs) & (strcmp(T_selected.Effect,{'A'}) | strcmp(T_selected.Effect,{'C'})) ,:);
lmeAllROIs_intel{1} = fitlme(Ttemp,formula);
lme_Tab = lme2table(lmeAllROIs_intel{1},'satterthwaite');                     % NEW
writetable(lme_Tab,[outDir filesep 'LME_AC_AllRegions.csv'])                  % NEW

%B>D
Tstats.Effects{ind} = 'B vs. D';

disp('B vs D')
lme_BD = cell(size(ROIs));
formula = 'EffectSize ~ Effect + (Effect|UID) + (Effect|ROIcat)';
for i=1:length(ROIs)
    Tstats.Hemisphere{ind} = hemi{i}; Tstats.Hemisphere{ind+1} = '';
    Tstats.Lobe{ind} = lobe{i}; Tstats.Lobe{ind+1} = '';

    Ttemp = T_selected(ismember(T_selected.ROI,ROIs{i}) & (strcmp(T_selected.Effect,{'B'}) | strcmp(T_selected.Effect,{'D'})) ,:);
    lme{i} = fitlme(Ttemp,formula);
    TBD{i} = lme2table(lme{i},'satterthwaite');writetable(TBD{i},[results_dir filesep 'stats' filesep 'LME_BD_' labels{i} '.csv'])
    writetable(TBD{i},[outDir filesep 'LME_BD_' labels{i} '.csv'])           % CHANGED: folder
    disp([labels{i} ' ' num2str(TBD{i}.pValue(2))])                          % CHANGED: Satterthwaite p
     
    Tstats(ind:ind+1,4:11) = TBD{i}(1:2,1:8);
    ind = ind + 2;
end
% across all ROIs
Ttemp = T_selected(ismember(T_selected.ROI,AllROIs) & (strcmp(T_selected.Effect,{'B'}) | strcmp(T_selected.Effect,{'D'})) ,:);
lmeAllROIs_intel{2} = fitlme(Ttemp,formula);
lme_Tab = lme2table(lmeAllROIs_intel{2},'satterthwaite');                     % NEW
writetable(lme_Tab,[outDir filesep 'LME_BD_AllRegions.csv'])                  % NEW
%writetable(Tstats,[results_dir filesep 'stats' filesep 'LME_IntelligibilityEffectAll.csv'])

%% test interaction


