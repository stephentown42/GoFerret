function [TDT] = Extract_TDT_batch()  %tankDir, blockName)

% % Get duration for extraction from tracking video
% RV2video = VideoReader('C:\Users\Soraya\Documents\Data\F1504_Kiwi neural practice\TDT Wireless comparison\08-07-15\Block10-35\F1504_Kiwi_Block10-35_Vid0.avi'); %Use video to find out recording duration
% info =get(RV2video);
% duration = ceil(RV2video.Duration);
try
    
    savePath = 'E:\Soraya Data\Beaker\TDT_sync';
    
    tankPath = 'C:\TDT\OpenEx\Tanks\Beaker_Extraction';
    
    blockDir = dir(fullfile(tankPath,'*Block10*'));

    fileID = fopen(fullfile(savePath,'Empty_blocks.txt'), 'wt+');    % create file for list of failed blocks be written

        
    %Sort by date
%     S = [blockDir(:).datenum].';
%     [~, SIdx] = sort(S);
%     blockDir = blockDir(SIdx,:);
    
    
    % % % Default arguments
    % % if ~nargin
    % %     tankPath = 'C:\Users\Soraya\Documents\Data\Beaker practice';
    % %     blockName = 'Block10-13';
    % % end
    
    
    for i = 3 : length(blockDir)
        
        blockName = blockDir(i).name;
        
        TDT.blockName = blockName;
        
        % Calculate nMax from recording duration - make nMax exceed number of buffers in recording to ensure all trace extracted
        RZ2sampleRate = 24414.0625;
        
        RX8sampleRate = 48828.125;
        
        % nMax = (recordingDuration * sampleRate) / 2048;
        % nMax = ceil(nMax); Just set nMax v high to extract all data(recDur=~5hrs)
        nMax = 220000;
        % Define store names based on filter choice
        
        %%
        
        % Connect to TDT
        TTfig = figure('visible','off');
        TT = actxcontrol('TTank.X');
        TT.ConnectServer('Local','Me')
        TT.OpenTank(tankPath , 'R' )   % R-Read, W-Write, C-Control, M-Monitor
        
        % Open block
        TT.SelectBlock(blockName);
        fprintf('%s\n',blockName)
        
        %% RV2(from from RZ2)
        
        R= [];
        
        for channel= 1:3
            ev4 = TT.ReadEventsV(nMax,'RV_2', channel, 0, 0, 0, 'All');
            fprintf('\t%d events\n',ev4)
            r  = TT.ParseEvV(0, ev4);
            r = reshape(r, numel(r), 1);
            R(:,((channel-1)*3) + channel) = r;
        end
        
        TDT.RV2 = R;
        
        timestamps_RZ2 = TT.ParseEvInfoV(0, ev4, 6);
        
        %% Sine synchronising pulse (RX8)
        
        X=[];
        % for channel = 1:2
        ev = TT.ReadEventsV(nMax,'sine', 1, 0, 0, 0, 'All');
        x  = TT.ParseEvV(0, ev);
        x  = reshape(x, numel(x), 1);
        X(:,1) = double(x);
        % end
        
        TDT.sine = X;
        
        
        %% DOut pulse from RX8 (start & end pulses & stimulus times)
        
        ev2 = TT.ReadEventsV(nMax,'DOut', 1, 0, 0, 0, 'All');
        z  = TT.ParseEvV(0, ev2);
        z = reshape(z, numel(z), 1);
        
        %   y(:,((channel-1)*3) + channel) = double(x);
        
        TDT.digital = z;
        %timestamps2 = TT.ParseEvInfoV(0, ev2, 6);
        
        %% Centre spout activaton
        
        C=[];
        for chan = 1:2
            ev3 = TT.ReadEventsV(nMax,'CSpt', chan, 0, 0, 0, 'All');
            c  = TT.ParseEvV(0, ev3);
            c = reshape(c, numel(c), 1);
            C(:,chan)=double(c);
        end
        
        TDT.centreSpout = C;
        %timestamps3 = TT.ParseEvInfo(0, ev3, 6);
        
        % Extract timestamps (now everything on RX8, can just extract one time vector)
        
        timestamps_RX8 = TT.ParseEvInfoV(0, ev2, 6);
        
        if isnan(z)   % If block is empty, write blockname to text file
            fprintf(fileID,'%s\n',blockName);
            continue
        end
        if isnan(r)   % If block is empty, write blockname to text file
            fprintf(fileID,'%s\n',blockName);
            continue
        end
        
        %% Close connection
        TT.CloseTank
        TT.ReleaseServer
        close(TTfig)
        
        
        %% Interpolate time when SR=48k (RX8)
        y = reshape(z, 4096, length(timestamps_RX8));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
        t = NaN(size(y)); %create empty time matrix same size as reshaped trace matrix
        
        steps = (0:4095)/RX8sampleRate; %vector of time increments
        
        for i=1:4096
            t(i,:)=timestamps_RX8+steps(i).*ones(size(timestamps_RX8)); %add step to each row (ones to ensure length stays correct?)
        end
        
        t = reshape(t,length(z),1); %put into 1xN shape
        TDT.time_48k = linspace(timestamps_RX8(1),timestamps_RX8(end)+steps(end),length(z));%make sure all points have equal spacing
        
        
        %% Interpolate time points for SR=24k (RZ2)
        
        y2 = reshape(r, 2048, length(timestamps_RZ2));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
        t2 = NaN(size(y2)); %create empty time matrix same size as reshaped trace matrix
        
        steps = (0:2047)/RZ2sampleRate; %vector of time increments
        
        for i=1:2048
            t2(i,:)=timestamps_RZ2+steps(i).*ones(size(timestamps_RZ2)); %add step to each row (ones to ensure length stays correct?)
        end
        
        t2 = reshape(t2,length(r),1); %put into 1xN shape
        TDT.time_24k = linspace(timestamps_RZ2(1),timestamps_RZ2(end)+steps(end),length(r));%make sure all points have equal spacing
        
        % %% Interpolate time points for RX8
        % % For stim times
        % y2 = reshape(z, 4096, length(timestamps2));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
        % t2 = NaN(size(y2)); %create empty time matrix same size as reshaped trace matrix
        %
        % steps = (0:4095)/RX8sampleRate; %vector of time increments
        %
        % for i=1:2048
        %     t2(i,:)=timestamps2+steps(i).*ones(size(timestamps2)); %add step to each row (ones to ensure length stays correct?)
        % end
        %
        % t2 = reshape(t2,length(z),1); %put into 1xN shape
        % TDT.RX8_digitaltime = linspace(timestamps2(1),timestamps2(end)+steps(end),length(z));%make sure all points have equal spacing
        %
        % % % For centre spout times
        % % y3 = reshape(c, 4096, length(timestamps2));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
        % % t3 = NaN(size(y3)); %create empty time matrix same size as reshaped trace matrix
        % %
        % % for i=1:2048
        % %     t3(i,:)=timestamps3+steps(i).*ones(size(timestamps3)); %add step to each row (ones to ensure length stays correct?)
        % % end
        % %
        % % t3 = reshape(t3,length(c),1); %put into 1xN shape
        % % data.centretime = linspace(timestamps3(1),timestamps3(end)+steps(end),length(c));%make sure all points have equal spacing
        % %
        
        
        save([savePath '\' blockName '_TDT_out.mat'], '-struct', 'TDT', '-v7.3');
        
        keep savePath tankPath blockDir fileID
        
    end
    
    close(fileID);
    
catch err
    err
    keyboard
end
end
