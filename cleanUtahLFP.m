function [badT, badTbyC, badC] = cleanUtahLFP( ...
    data, Zhigh, Zlow, nChanForBadT, dtForBadT, dtReject, ...
    nBadtoRejectC, GUIplot, arrayLayout)
% function [badT, badTbyC, badC] = cleanUtahLFP( ...
%    data, Zhigh, Zlow, nChanForBadT, dtForBadT, dtReject, ...
%    nBadtoRejectC, GUIplot, arrayLayout)
%
% Purpose: reject channels that are bad in neuroport data and the times
% that are bad for all channels or just single channels
%
% Required Input:
%   Zhigh: Minimum z-score for a timepoint to be marked as a bad time
%   (default 6)
%   Zlow: Minimum z-score of a channel to support the claim that a
%   timepoint is bad
%   nChanForBadT: The number of channels that need to ahve Z > Zlow in
%   order for a time point to be marked as bad for all channels
%   dtForBadT: The amount of time before or after a proposed bad
%   timepoint in which other channels are checked for potential rejection
%   dtReject: The amount of time before or after a confirmed bad timepoint
%   to ignore in the data
%   nBadtoRejectC: The number of bad periods on a channel to be present
%   for the whole channel to be marked as bad
%   GUIplot: Indicate if any data visualization is desired.
%       'rejects': scroll through electrodes and times and see where the
%       algorithm rejected times
%       'badT': select an electrode and see all the bad tiempoints for that
%       electrode
%   arrayLayout : matrix that represents the spatial distribution of the
%   channel numbers of the electrode array. Gaps in the array where no
%   recording electrode exists are indicated by a NaN.
%
% Output:
%   badT: list of bad time points general to all channels
%   badTbyC: Cell array of lists of bad time points specific to each
%   channel
%   badC: list of bad channels
%
% Created:   06/01/15 by Scott Cole

%% Calculate zscore of the data

C = size(data,1);
T = size(data,2);
dataZ = zeros(size(data));
for c=1:C
    dataZ(c,:) = zscore(data(c,:));
end
clear data

%% Find the timepoints at which each electrode goes above Z thresholds
Z_min2 = Zlow - 1;
zscore_thresh_t = cell(C,2);
zscore_thresh_n = zeros(C,2);
allT = 1:T;
for c=1:C
    temp_data = dataZ(c,:);
    zscore_thresh_t{c,1} = allT(abs(temp_data) > Zlow);
    zscore_thresh_n(c,1) = length(zscore_thresh_t{c,1});
    zscore_thresh_t{c,2} = allT(abs(temp_data) > Zhigh);
    zscore_thresh_n(c,2) = length(zscore_thresh_t{c,2});
end
clear temp_data

%% Detect time points that are bad over all channels
badT_allC = [];
for c=1:C
    badT_allC = [badT_allC, zscore_thresh_t{c,2}];
end

badT_allC = unique(badT_allC);
badT_gen = [];
for t=1:length(badT_allC)
    if mod(t,1000) == 0
        fprintf('Detect bad times %d/%d\n',t,length(badT_allC))
    end
    
    temp_reps = 0;
    for c=1:C
        chantimenear = any(abs(zscore_thresh_t{c,1} - badT_allC(t)) < dtForBadT);
        temp_reps = temp_reps + chantimenear;
    end
    
    if temp_reps > nChanForBadT
        badT_gen = [badT_gen, badT_allC(t)];
    end
end

%% Take out time periods around the general bad times
binary_badt1 = zeros(T,1);
binary_badt1(badT_gen) = 1;
badt_kernel = ones(dtReject*2+1,1);
binary_badt2 = conv(binary_badt1,badt_kernel,'same');
binary_badt2(binary_badt2~=0) = 1;
Tall = 1:T;
badT = Tall(binary_badt2>0); 

%% Quantify the number of time periods each electrode above threshold
zscore_thresh_trmvbadtimes = cell(size(zscore_thresh_t));
zscore_thresh_nrmvbadtimes = zeros(size(zscore_thresh_n));
badperchanN = zeros(C,size(zscore_thresh_t,2));
badperchanT = cell(C,size(zscore_thresh_t,2));
badperchanL = cell(C,size(zscore_thresh_t,2));
for c=1:C
    for z2=1:size(zscore_thresh_t,2)
        zscore_thresh_trmvbadtimes{c,z2} = setdiff(zscore_thresh_t{c,z2},badT_gen);
        zscore_thresh_nrmvbadtimes(c,z2) = length(zscore_thresh_trmvbadtimes{c,z2});
        % Define the number of time segments that each electrode went above the
        % zscore threshold
        [badperchanN(c,z2),badperchanT{c,z2},badperchanL{c,z2}] = ...
            fnPeriods(zscore_thresh_trmvbadtimes{c,z2},dtReject);
    end
end

%% Declare channels that are bad
allC = 1:C;

N_Zthresh = badperchanN(:,2);
badC = allC(N_Zthresh > nBadtoRejectC);

%% Mark bad time periods for individual channels
badTbyC = cell(C,1);
for c=1:C
    % Identify bad times for that channel
    c_bt = badperchanT{c,end};
    BT = length(c_bt);
    temp_bt = [];
    for bt=1:BT
        temp2_bt = c_bt(bt)-dtReject:c_bt(bt)+dtReject;
        temp_bt = [temp_bt, temp2_bt];
    end
    badTbyC{c} = temp_bt;
end

%% Find adjacent electrodes if plotting
if strcmp(GUIplot,'badT') || strcmp(GUIplot,'rejects')
    adj_elec = cell(C,1);
    for c=1:C
        % find index of electrode
        [row, col] = find(arrayLayout == c);

        % record values of the electrodes surrounding the current electrode
        adj_elec{c} = fadjacentChans([row,col],arrayLayout,[1,1]);
    end
end

%% Plot GUIs if desired
if strcmp(GUIplot,'badT')

%% Visualize timepoints that are bad for each electrode (not time points that are bad for all electrodes)
Ntimeperiods = 100;
Trangetoplot = 5000; %10 sec total; 5sec before and after
figure('Position', [0, 0, 1000, 600])

% GUI: channel and period sliders
chanGUI= uicontrol(gcf,...
    'Style','slider',...
    'Min',1,'Max',C,...
    'Value',1, ...
    'SliderStep',[1/(C-1) 1/(C-1)], ...
    'Position',[60,0,200,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
channel_chosen = 1;

while true
    % Stop the program if the figure is closed
    if ~ishandle(chanGUI)
        break
    end
    
    % If the edit textboxes have changed, reload the plots
    chanfromGUI = round(get(chanGUI, 'Value'));
    if chanfromGUI ~= channel_chosen
        channel_chosen = chanfromGUI;
        arrayfun(@cla,findall(0,'type','axes')) %Clear all axes so no old graphs are there
    end    
    
    % Select time points of interest
    T_plot = fplotBadT(badperchanN(chanfromGUI,Z_bad-Z_min2:end),{badperchanT{chanfromGUI,Z_bad-Z_min2:end}},Ntimeperiods);
    if T_plot > 0
        % Don't plot outside the range of the data
        T_plot(T_plot < Trangetoplot + 1) = Trangetoplot + 1;
        T_plot(T_plot > T) = T - Trangetoplot - 1;

        % Plot the z-scored data for that channel and all adjacent channels at
        % each time point
        channel_adj = adj_elec{channel_chosen};
        cm = colormap(parula(length(channel_adj)));
        legend_entries = cell(1,length(channel_adj)+1);
        for ac = 1:length(channel_adj)
            legend_entries{ac} = num2str(channel_adj(ac));
        end
        legend_entries{length(legend_entries)} = num2str(channel_chosen);

        for pl = 1:length(T_plot)
            subplot(2,ceil(length(T_plot)/2),pl)
            period_t = (T_plot(pl)-Trangetoplot):(T_plot(pl)+Trangetoplot);
            for ac = 1:length(channel_adj)
                plot(period_t/1000,dataZ(channel_adj(ac),period_t),'color',cm(ac,:)); hold on
            end
            plot(period_t/1000,dataZ(channel_chosen,period_t),'k','linewidth',2)
            legend(legend_entries,'Location','best')
            xlabel('time (seconds)')
            ylabel('zscore')
            xlim([T_plot(pl)-Trangetoplot,T_plot(pl)+Trangetoplot]/1000);
        end
    else
        t=0:.01:2*pi;
        subplot(1,1,1)
        plot(t,sin(t));
        title(sprintf('No bad times for electrode %d',channel_chosen),'fontsize',22)
    end
    
    
    
    uiwait;
end

elseif strcmp(GUIplot,'rejects')
%% Visualize adjacent channels over time with shade around rejected times (red = all electrode), (blue=single electrode)

% Variables to use: 'badchan_highv','badtimes','badtimesbychan'
Nelec_atonce = 6;


figure('Position', [0, 0, 1000, 600])

% Define total # of periods for easy scrolling (30 sec)
L = 30000;
P = floor(T/L);

% GUI: channel and period sliders
chanGUI= uicontrol(gcf,...
    'Style','slider',...
    'Min',1,'Max',C-Nelec_atonce+1,...
    'Value',1, ...
    'SliderStep',[1/(C-Nelec_atonce) 1/(C-Nelec_atonce)], ...
    'Position',[60,0,200,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
channel_chosen = 1;
perGUI= uicontrol(gcf,...
    'Style','slider',...
    'Min',1,'Max',P,...
    'Value',1, ...
    'SliderStep',[1/(P-1) 1/(P-1)], ...
    'Position',[60,30,200,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
period_chosen = 1;

% GUI: Start and end times
tsGUI= uicontrol(gcf,...
    'Style','edit',...
    'String','0',...
    'Position',[360,0,30,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
ts_chosen = 0;
durGUI= uicontrol(gcf,...
    'Style','edit',...
    'String','30',...
    'Position',[360,30,30,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
dur_chosen = 30;
zrGUI= uicontrol(gcf,...
    'Style','edit',...
    'String','0',...
    'Position',[360,60,30,30], ... %[left, bottom, right, top] (or horz, vert)
    'CallBack', 'uiresume;');
zr_chosen = 0;

% Labels
lab_chan = uicontrol(gcf,'Style','text','String','channel','Position',[0,0,60,30]);
lab_period = uicontrol(gcf,'Style','text','String','30-sec period (240 total)','Position',[0,30,60,30]);

lab_ts = uicontrol(gcf,'Style','text','String','start time (s)','Position',[300,0,60,30]);
lab_dur = uicontrol(gcf,'Style','text','String','duration (s)','Position',[300,30,60,30]);
lab_zr = uicontrol(gcf,'Style','text','String','zrange','Position',[300,60,60,30]);

lab_cur_chan = uicontrol(gcf,'Style','text','String',num2str(1),'Position',[260,0,30,30]);
lab_cur_period = uicontrol(gcf,'Style','text','String',num2str(1),'Position',[260,30,30,30]);

while true
    % Stop the program if the figure is closed
    if ~ishandle(chanGUI)
        break
    end
    
    % If the edit textboxes have changed, reload the plots
    chanfromGUI = round(get(chanGUI, 'Value'));
    perfromGUI = round(get(perGUI, 'Value'));
    tsfromGUI = str2double(get(tsGUI, 'String'));
    durfromGUI = str2double(get(durGUI, 'String'));
    zrfromGUI = str2double(get(zrGUI, 'String'));
    if chanfromGUI ~= channel_chosen || perfromGUI ~= period_chosen || tsfromGUI ~= ts_chosen || durfromGUI ~= dur_chosen || zrfromGUI ~= zr_chosen
        channel_chosen = chanfromGUI;
        period_chosen = perfromGUI;
        ts_chosen = tsfromGUI;
        dur_chosen = durfromGUI;
        zr_chosen = zrfromGUI;
        arrayfun(@cla,findall(0,'type','axes')) %Clear all axes so no old graphs are there
        set(lab_cur_chan,'String',num2str(channel_chosen))
        set(lab_cur_period,'String',num2str(period_chosen))
    end
    
    % Plot electrode chosen and the 5 after that
    for ne=1:Nelec_atonce
        subplot_tight(Nelec_atonce+1,1,ne,[.05,.05])
        c = channel_chosen + ne - 1;
    
        % Plot the raw voltage for the specified channel and its adjacent
        % channels for the specified time period
        channel_adj = adj_elec{c};
        cm = colormap(parula(length(channel_adj)));
        ts_chosen_idx = (period_chosen-1)*L + 1 + ts_chosen*1000;
        te_chosen_idx = min(ts_chosen_idx + dur_chosen*1000,size(dataZ,2));
        period_idx = ts_chosen_idx:te_chosen_idx;
        period_t = ts_chosen_idx/1000:.001:te_chosen_idx/1000;
        legend_entries = cell(1,length(channel_adj)+1);

        for ac = 1:length(channel_adj)
            legend_entries{ac} = num2str(channel_adj(ac));
            plot(period_t,dataZ(channel_adj(ac),period_idx),'color',cm(ac,:)); hold on
        end
        legend_entries{length(legend_entries)} = num2str(c);
        plot(period_t,dataZ(c,period_idx),'k','linewidth',2); hold on
        legend(legend_entries,'Location','EastOutside')
        xlim([min(period_t), max(period_t)])
        ylabel('Voltage (Z score)')
        if ne == Nelec_atonce
            xlabel('time (seconds)')
        end
        
        % Add note to plot (TITLE) if the channel is rejected
        if any(badC==c)
            title(sprintf('ELECTRODE %d was marked as bad',c))
        else
            title(sprintf('ELECTRODE %d',c))
        end
        
        if zrfromGUI
            ylim([-zrfromGUI,zrfromGUI])
        end
        
        % Are there any bad times for all chan being plotted (period_idx)?
        shade_red = intersect(period_idx,badT);
        cur_ylim = ylim;
        if ~isempty(shade_red)
            shade_red_per = fchunkInts(shade_red,1)/1000;
            SHP = size(shade_red_per,1);
            shade_red_LR = [];
            % Add red shading to plot if it goes over a bad time for all chan
            for sh=1:SHP
                hA1 = area([shade_red_per(sh,1),shade_red_per(sh,2)],[cur_ylim(2),cur_ylim(2)]); hold on;
                hA2 = area([shade_red_per(sh,1),shade_red_per(sh,2)],[cur_ylim(1),cur_ylim(1)]); hold on;
                set(hA1,'EdgeColor','None','FaceColor','r')
                set(hA2,'EdgeColor','None','FaceColor','r')
                alpha(.3)
            end
        end
        
        % Add blue shading to plot if it goes over a bad time for that chan
        shade_blue = intersect(period_idx,badTbyC{c});
        if ~isempty(shade_blue)
            shade_blue_per = fchunkInts(shade_blue,1)/1000;
            SHP = size(shade_blue_per,1);
            shade_blue_LR = [];
            shade_top = max(dataZ(c,period_idx));
            shade_bottom = min(dataZ(c,period_idx));
            % Add blue shading to plot if it goes over a bad time for that chan
            for sh=1:SHP
                hA3 = area([shade_blue_per(sh,1),shade_blue_per(sh,2)],[cur_ylim(2),cur_ylim(2)]); hold on;
                hA4 = area([shade_blue_per(sh,1),shade_blue_per(sh,2)],[cur_ylim(1),cur_ylim(1)]); hold on;
                set(hA3,'EdgeColor','None','FaceColor','b')
                set(hA4,'EdgeColor','None','FaceColor','b')
                alpha(.3)
            end
        end
        
    end
    
    hold off
    uiwait;
end
end