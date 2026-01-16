function [h,hs] = plotVol2Surf(fs_dir,surf_dir,fname,clim,colors,inflated,whichHemi,whichROIs,showColorbar,view)
%PLOTVOL2SURF reads a volumetric .nii file, converts it to
%a surface .nii file (using MNI152) and plots one or both hemispheres using Gerber visualization toolbox.
% Tamar Regev, for bug reports send me an email: tamarr@mit.edu
% 
% Instructions before use:
% 1. Download the Gerber toolbox and add to matlab path.
% 2. Install freesurefer and locate its path. Pass to this function as
% input (see inputs below)
%
%
% For Openmind users: Gerber Vis works best when using matlab with virtual
% GL. See https://github.mit.edu/MGHPCC/OpenMind/issues/2894
%
% inputs:
%   fs_dir : freesurfer directory;
%       example: '/cm/shared/openmind/freesurfer/5.3.0'
%   surf_dir : directory to save the surfaces transformed from the volumetric representation 
%   fname  : full path to nifti file, including nii extension 
%       example: '/mindhive/evlab/u/jaffourt/masks/allParcels_language.nii';
%   clim = [cmin cmax]      : color limits, determines number of entries in colormap
%       example: [1 12]
%   colors : obligatory.
%            - in the case of continuous activation data, colors should be a
%            string. It can either be just 'cont' and then the colormap
%            will be the default (parula). If you wish to change the
%            colormap, e.g. to jet, assign colors = 'jet'; etc. You could
%            also play with colormap names for discrete data and see
%            whether it selects nice colors.
%            - in the case of discrete data (like masks), colors should be a
%            nx3 matrix of rgb colors with the number and order of colors
%            corresponding to the values in the .nii file
%            If colors is an 1x3 matrix, with only 1 RGB color, then all ROIs will have the same color  
%   inflated : true/false to plot inflated brain. optional, default = true.
%   whichHemi : 'rh', 'lh', or 'both' (default: 'both')
%   whichROIs : to plot. Example: 1:5. Optional. If not passed, all ROIs will be plotted
%               if working with continuous data (defined by variable
%               colors) whichROIs will not be used even if exists as input.
%   showColorbar : true/false to display olorbar. optional, default=true.
%   view :    visual angle of presentation of the brain. Options: 'lateral', 'medial'        

%Tamar Regev June 20 2020: For masks containing only
%1 number use clim=[0 1] and don't display the colorbar showColorbar=false.
%
% Tamar Regev July 22 2020: transform 0 to nan such that it will not be
% colored
%
% Tamar Regev Sept 2021: if colors input is just 1 color, make all parcels
% same color
% Tamar Regev Sept 2024: fixed bug for MD parcels which are not integer in
% the evlab parcels nii file. whichROIs = single(whichROIs) fixed it.



addpath(genpath(fs_dir))

%Manage inputs:
if ~exist('showColorbar','var')
    showColorbar=true;
end
if ~exist('inflated','var')
    inflated=true;
end

if ~exist('whichHemi','var')
    whichHemi='both';
end
if ~exist('view','var')
    view='lateral';
end
if ischar(colors)%continuous data
    contFlag = true;
    if strcmp(colors,'cont')
        cmname = 'parula';
    else
        cmname = colors;
    end
else
    contFlag = false;
end 
whichROIs = single(whichROIs);

cmin=clim(1);cmax=clim(2);

    %load MNI152 template surface given by freesurfer 
    fs_subject_dir = [fs_dir filesep 'subjects' filesep 'cvs_avg35_inMNI152'];
    [brain_data, vertex_data] = read_freesurfer_brain(fs_subject_dir, fs_dir);

    %convert a volumetric nii fROI file into a surface registered to MNI: 
    filename_in = fname;
    [~,name,~] = fileparts(fname);
    fs_shell_initialize_cmd = ['export FREESURFER_HOME=' fs_dir '; source $FREESURFER_HOME/SetUpFreeSurfer.sh; '];
    switch whichHemi
        case 'both'
            for hem = {'rh','lh'}
                filename_out = [surf_dir filesep name '_surf_' hem{1} '.nii'];
                command = [fs_shell_initialize_cmd 'mri_vol2surf --mov ' filename_in ' --o ' filename_out...
                ' --hemi ' hem{1} ' --regheader cvs_avg35_inMNI152 --projdist  1.2'];
                system(command)
            end
        otherwise
                filename_out = [surf_dir filesep name '_surf_' whichHemi '.nii'];
                command = [fs_shell_initialize_cmd 'mri_vol2surf --mov ' filename_in ' --o ' filename_out...
                ' --hemi ' whichHemi ' --regheader cvs_avg35_inMNI152 --projdist  1.2'];
                system(command)
    end
    
    %plot
    %h=figure;
    h=nan;
    hemis={'lh','rh'};
    switch whichHemi
        case 'both'
            ihemis =1:2;
        otherwise     
            ihemis = find(strcmp(hemis,whichHemi));
    end

    switch view
        case 'lateral'
            angle_lh = [-110 0];
            angle_rh = [110 0];
        case 'medial'
            angle_lh = [110 0];
            angle_rh = [-110 0];
            
    end
    for ih = ihemis
        if strcmp(hemis,'both')
            hs{ih}=subplot(1,2,ih);
        else 
            hs = gca;
        end
        hemi=hemis{ih};

        %read surface into matlab
        filename = [surf_dir filesep name '_surf_' hemi '.nii'];

        data_surf = read_gzip_nifti(filename);
        % convert to single to decrease data size:
        data_surf = single(data_surf);
        data_surf(~data_surf)=nan;
        if exist('whichROIs','var')
            if ~contFlag
                % rounding done for the case of MD parcels that have a
                % weird non integer value, presumably due to interpolation
                data_surf = round(data_surf);
                whichROIs = round(whichROIs);
                data_surf(~ismember(data_surf,whichROIs))=nan;
            end
        end
        % Plot on inflated anatomy
        switch hemi
           case 'lh'
               curv = vertex_data.left.vertex_curvature_index;
           case 'rh'
               curv = vertex_data.right.vertex_curvature_index;
        end
        % The sulci are the negative values
        curv = -sign(curv);
        %figure;
        switch inflated
            case true
                switch hemi
                    case 'lh'
                        plot_mesh_brain(brain_data.inflated_left,angle_lh, -curv); 
                    case 'rh'
                        plot_mesh_brain(brain_data.inflated_right,angle_rh, -curv);
                end
            case false
                switch hemi
                    case 'lh'
                        plot_mesh_brain(brain_data.pial_left,angle_lh, -curv); 
                    case 'rh'
                        plot_mesh_brain(brain_data.pial_right,angle_rh, -curv);
                end
        end
        
        
        caxis([-7 1]);
        colormap gray
        transparency = 0;
        paint_mesh(data_surf,transparency);
        caxis([cmin cmax]);
        if contFlag
            colormap(cmname)
        else
            if exist('colors','var')
                colormap(colors)
            else
                colormap(jet(cmax-cmin+1)) 
            end
        end
    end
    if showColorbar
        hc=colorbar;
        if strcmp(whichHemi,'both')
            set(hc,'position',[0.5 0.1 0.02 0.6],'ytick',cmin:cmax)
        else
            set(hc,'ytick',cmin:cmax)
        end
    end
      %     %Plot on non inflated brain
        %     figure;
        %     plot_mesh_brain(brain_data.pial_left,[-110 0]); 
        %     paint_mesh(clust_idx_surf,0.1);
        %     caxis([1 k]);
        %     colormap jet
end

