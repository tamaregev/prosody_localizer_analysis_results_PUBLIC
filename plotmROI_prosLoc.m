
function [h,hE,hl] = plotmROI_prosLoc(T,effects,whichROIs,ROIstring,whicherr,avgfROIs,displayStats,displayIndividuals,colors)
    %% Inputs
    
    % Examples:
    
    %   T is a data table from toolbox output file:
    %          T=readtable('spm_ss_mROI_data.csv')
    %
    %     ROI                 Subject                 Effect    LocalizerSize    EffectSize
    %     ___    _________________________________    ______    _____________    __________
    % 
    %      1     {'018_FED_20151203a_3T1_PL2017' }    {'S' }         216            2.8993 
    %      1     {'018_FED_20151203a_3T1_PL2017' }    {'W' }         216            1.6395 
    %      1     {'018_FED_20151203a_3T1_PL2017' }    {'W1'}         216            1.5676 
    %      1     {'018_FED_20151203a_3T1_PL2017' }    {'W2'}         216            1.2778 
    %  
    %   effects = {'W','W1','W2','W3','W4'}; % should match names in Effect
    %   colors = [255 0 0; 6 12 186; 57 67 203; 108 121 221; 158 176 238;209 230 255]./255; RGB values, length should match effects
    %   whichROIs = 1:6; % should match their numbers in the table
    %   ROIstring =
    %   {'IFGorb','IFG','MFG','AntTemp','PostTemp','AngG','IFGorb-R','IFG-R','MFG-R','AntTemp-R','PostTemp-R','AngG-R'};%if want to give names
    %   whicherr = 'stderr' or 'confidence';
    %   avgfROIs = true or false. If true - plots the avg of all fROIs
    % . displayStats = true;% or false (TODO)
    %   displayIndividuals = true;%or false
    %   
    %% manage inputs
    if ~exist('effects','var')
        effects = unique(T.Effect);%display as text over figure
    end
    
    if ~exist('displayStats','var')
        displayStats = false;%display as text over figure
    end
    if ~exist('displayIndividuals','var')
        displayIndividuals = true;%display as text over figure
    end

    if ~exist('whichROIs','var')
        whichROIs = 1:6;
    end
    if ~exist('avgfROIs','var')
        avgfROIs = false;%select after reading data due to several criteria
    end
    if length(whichROIs)==1
        if avgfROIs
            error('Inputs not compatible: averaging fROIs is not compatible with passing only 1 fROI.')
        end
    end
    %% calc
        
%    allEffects = [effects{1},effects{2},effects{3}];
    allEffects=effects;
    
    %whichExpPerEffect = nan(size(allEffects));
   

    meanE_all = nan(numel(allEffects),numel(whichROIs));
    err_all = nan(numel(allEffects),numel(whichROIs));
    meanE_allfROIs = nan(numel(allEffects),1);
    err_allfROIs = nan(numel(allEffects),1);
    
        plotT = T(ismember(T.ROI,whichROIs) & ismember(T.Effect,allEffects) ,:);
    
        for is=1:height(plotT)
            plotT.UID(is) = str2double(plotT.Subject{is}(1:3));
        end
        allSubj = unique(plotT.UID);
        nSubj=numel(allSubj);
        EffectSize=nan(numel(effects),nSubj,numel(whichROIs));
        
        for ii=1:height(plotT)
            ief=find(ismember(effects,plotT.Effect(ii)));
            isub=find(ismember(allSubj,plotT.UID(ii)));
            iroi=find(ismember(whichROIs,plotT.ROI(ii)));
            EffectSize(ief,isub,iroi)=plotT.EffectSize(ii);    
        end
        meanE = mean(EffectSize,2);
        
        stderr = (std(EffectSize,0,2)./sqrt(size(EffectSize,2)));
        conf = nan(size(stderr));
        for iroi=1:length(whichROIs)
            es=EffectSize(:,:,iroi)';
            conf(:,:,iroi) = Confidence(es);
        end
        meanE_all = squeeze(meanE);
        
        switch whicherr
            case 'confidence'
                err_all = squeeze(conf);
            case 'stderr'
                err_all = squeeze(stderr);
        end
        
        if length(whichROIs)>1 %this is calculated for the avgfROIs option
            meanE_perfROI = mean(EffectSize,3);
            switch whicherr
                case 'confidence'
                    errs = Confidence(meanE_perfROI');
                case 'stderr'
                    errs = std(meanE_perfROI,0,2)./sqrt(size(meanE_perfROI,2)); 
            end
            err_allfROIs = squeeze(errs);
        end
                        
    meanE_allfROIs = mean(meanE_all,2);
    
    %% plot
    %figure
    if avgfROIs
        EffectSize = mean(EffectSize,3);
        Plot(meanE_allfROIs,err_allfROIs,EffectSize)
    else
        Plot(meanE_all,err_all,EffectSize)
    end
    %% nested functions
    function Plot(means,errs,subjData)
        
        %calc significance
%         p = nan(length(whichROIs),1); H = nan(length(whichROIs),1); CI = cell(length(whichROIs),1); stats = cell(length(whichROIs),1);
%         for iroi = 1:length(whichROIs)
%             ROI = whichROIs(iroi);
%             [p(iroi),H(iroi),CI{iroi},stats{iroi}] = significance_mROI(T_ind,contrast1,contrast2, ROI);
%         end
%         mROIsig=table(whichROIs,p,H,CI,stats);
   
        
        if size(means,2)>1 %plot several fROIs
            [h, hE]=barwitherr(errs',1:length(whichROIs),means'); 
            for ib=1:length(h)
               
                    h(ib).FaceColor=colors{ib};
                    h(ib).LineWidth=1;
              
            end
            set(hE,'Linewidth',1)
            set(gca,'xtick',1:length(whichROIs))
            xticklabels(gca,strrep(ROIstring,'_',' '))
            xlabel('ROI')
            
        else %plot 1 or avg fROI % TODO
            for ib=1:length(errs) %length(err_all_wnan)
                %if find(ibMap==ib)
                    %h(ib) = bar(ib,meanE_all_wnan(ib)); 
                    h(ib) = bar(ib,means(ib)); 
                    %h(ib).FaceColor=colors(find(ibMap==ib),:);
                    h(ib).FaceColor=colors{ib};
                    hold on
                    %hE(ib) = errorbar(ib,meanE_all_wnan(ib),err_all_wnan(ib));
                    hE(ib) = errorbar(ib,means(ib),errs(ib));
                    set(hE(ib),'Color','k','HandleVisibility','off')
                    if avgfROIs
                        h(ib).LineWidth=1;
                        set(hE(ib),'linewidth',1)
                    else
                        h(ib).LineWidth=1;
                        set(hE(ib),'linewidth',1)
                    end
                   
                %end
            end
            %set(gca,'xtick',[1 5 9.5])
            %ExpString = {'Exp 1','Exp 2','Exp 3'};
            %Nstring = {'N=605','N=16','N=14'};
            %labelArray = [ExpString;Nstring];
            %tickLabels = strtrim(sprintf('%s\\newline%s\n', labelArray{:}));
            %set(gca,'xticklabels',tickLabels)

            if avgfROIs
                title('Averaged across fROIs')        
                ylabel('% BOLD signal change')
            
            end
        end
%        set(gca,'fontsize',12)
        

        hold on
        if displayIndividuals
            if size(means,2)>1 %plot several fROIs
                circleSize = [50];
                spreadScale = [30];
                alphaLevel = [0.4];
            elseif avgfROIs
                circleSize = [40];
                spreadScale = [3];    
                alphaLevel = [0.2];
            else %plot 1 fROI
                circleSize = [40];
                spreadScale = [3];
                alphaLevel = [0.2];
            end
            for ib=1:numel(h)
                
                XData = h(ib).XData+h(ib).XOffset;
                YData = h(ib).YData;
                   
                for iroi=1:numel(XData)
                    ind = squeeze(subjData(ib,:,iroi));

                    xx=repmat(XData(iroi),size(ind));
                       
                    hs=scatter((xx+(rand(size(xx))-0.5)/spreadScale),ind,circleSize,colors{ib}.*0.8,'filled','HandleVisibility','off');

                    hs.MarkerFaceAlpha=alphaLevel(1);
        %                     
    %                hE2=errorbar(XData(iroi),YData(iroi),stderr(ib,iroi),'Color','k');
    %                set(hE2,'linewidth',2)
                end
                
            end
            minind = min(min(min(subjData)));
            maxind = max(max(max(subjData)));
            ylim([minind, maxind])
            if size(means,2)==1 && ~avgfROIs
               %text(1,4,strrep(ROIstring,'_',' '),'fontsize',12,'fontweight','bold')
            end
            %ylim([-2, 4])
        end


        if displayStats
            if displayIndividuals
                dy=-2;dx=0;fs=10;
            else
                dy=-1;dx=0;fs=10;
            end

            for iroi=1:length(whichROIs)
                roi=whichROIs(iroi);
                %text(iroi,max(mean(iroi,:))+10*dy,num2str(roi))
                str = {['p mROI=' num2str(mROIsig.p(iroi),2)],[ 'overlap: ' num2str(T_GSS.inter_subjectOverlap(roi),2)],[ 'p GSS = ' num2str(T_GSS.p(roi),2)],['p fdr = ' num2str(T_GSS.p_fdr(roi),2)]};
                if mROIsig.H(iroi)
                    c = [1 0 0];
                elseif mROIsig.p(iroi) <= 0.1
                    c = [0 0 1];
                else
                    c = [0 0 0];
                end
                if numel(whichROIs) > 1
                    t=text(iroi-dx,dy,str,'fontsize',12,'fontweight','bold','horizontalalignment','center','Color',c);
                else
                    t=text(numel(whichEffects)/2+0.5,dy,str,'fontsize',12,'fontweight','bold','horizontalalignment','center','Color',c);
                end       
             end
             if ~displayIndividuals
                cy=get(gca,'ylim');
                ylim([2*dy, max(max(mean+stderr))])
             else
                cy=get(gca,'ylim');
                if cy(1) > 2*dy
                    ylim([2*dy, cy(2)])
                end
             end

        end

        hl=legend(allEffects,'Location','neo');
    ylabel('% BOLD signal change')
    %     for iexp = 1:length(effects)
    %         ieffects=find(whichExpPerEffect==iexp);
    %         hl(iexp)=legend([h(ibMap(ieffects))],strrep(allEffects(ieffects),'_',' '),'Location','neo');
    %         pos=get(hl(iexp),'Position');
    %         pos(2) = pos(2) - (iexp-1)/10;
    %         hold on
    %         set(hl(iexp),'Position',pos);
    %     end    
        %set(hl,'fontsize',8)
    end
end

