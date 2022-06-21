function [] = depthPSD_singChan()
try
    
    % choose ferret/ block to analyse
    
    F = 3;
    
    blocks = {'BlockA-23' , 'BlockA-21', 'BlockA-18' , 'BlockA-17', 'BlockA-16', 'BlockA-15', 'BlockA-14'};
    
    ferrets = {'F1510_Beaker', 'F1507_Emu', 'F1504_Kiwi', 'F1511_Animal'};
    
    ferret = ferrets{F};
    
    
    for B = 1 : length (blocks)
        
        block = blocks{B};
        
        
        savePath = ['E:\Soraya Data\' ferret '\ROUGHdepthPSD\'];
        if ~exist(savePath,'dir')
        mkdir(savePath)
        end
        %     saveDir = dir(savePath);
        %     savedFiles = {saveDir(:).name};
        
        % Input paths
        WLpath = ['E:\Soraya Data\' ferret '\Wireless_exported\' block];
        blockDir = dir(fullfile(WLpath, ['*' block '*_extracted.mat']));            % dir of all channels in one block
        
        %             SRpath = ['D:\' ferret '\wirelessTDTcomp\' level];
        %             SRdir = dir(fullfile(SRpath,'*_SR_delay.mat'));
        
        HS  = strfind(blockDir(1).name,'HS');
        side = blockDir(1).name(HS-1 : HS+1);
        
        saveName = [block '_' side '_PSDs_thresh5000.mat'];
        %                 check = cellfun( @(x) strcmp(x, saveName), savedFiles );
        %
        %
        %                 if sum(check) == 1
        %                     continue
        %                 else
        %
        nChans = length(blockDir);
        
        for k = 1 : nChans
            
            
            channelMatch = strfind({blockDir.name},['Chan_' num2str(k) '_']);
            findchan = ~cellfun(@isempty,channelMatch);
            
            load(fullfile(WLpath, blockDir(findchan).name));
            
            chan = double(wireless.trace);
            clear wireless
            
            WL_SR = 20000;          % approximation
            
            % create filter
            RSR = WL_SR/20;
            
            b = fir1(round(RSR/2), [1 300]/(RSR/2),'bandpass');
            a = 1; %variable needed for filtfilt function, for finite filter a=1
            
            
            
            % remove artefacts
            clean = removeArtefact(chan);
            
            % resample channel & downsample time
            channelRS = resample(clean, 1, 20);
            
            %    Filter
            filtered  = filtfilt(b,a,channelRS);
            
            % Compute spectra
            nfft = 2048; %number of points in the fft for PSD
            [tracePSD,trace_f] = pwelch(filtered, hanning(nfft), [], nfft, RSR);
            trace_PSD = 10*log10(tracePSD);
            
            %    hanning(512) = window vector
            %    nfft, number of points in the fft
            %    RSR, the sampling rate
            %    [ ] = noverlap, defaults to 50% window overlap
            
            maxPeak.maxPeak(k,1) = max(trace_PSD(5:length(trace_PSD)));
            maxPeak.ferret = ferret;
            maxPeak.block = block;
            
            allPSD(k).channelPSD  = trace_PSD;
            allPSD(k).channel_f   = trace_f;
            allPSD(k).ferret = ferret;
            allPSD(k).block = block;
            
            allChans.cleaned(:,k) = filtered;
            allChans.ferret = ferret;
            allChans.block = block;
            
            disp([ferret ': ' block '- channel ' num2str(k)])
            
        end
        
        clear channels chan clean channelRS filtered tracePSD trace_PSD trace_f
        
        save(fullfile(savePath, saveName), 'allChans', 'maxPeak', 'allPSD')
        
        
        map1 =[16 18 14 20 15 17 13 19 1 31 3 29 2 32 5 27 4 30 7 25 6 28 9 23 8 26 11 21 10 24 12 22];
        map2 = [17 15 19 13 18 16 20 14 32 2 30 4 31 1 28 6 29 3 26 8 27 5 24 10 25 7 22 12 23 9 21 11];
        
        mapped1 = allPSD(map1);
        mappedPeaks1 = maxPeak.maxPeak(map1);
        
        red = (1/16):(1/16):1;
        sixteenones = ones(16,1);
        red = [red' ; sixteenones];
        blue = flipud(red);
        green = zeros(1,32)';
        cols2use = [red green blue];
        
        h = figure;
        
        for i = 1 : 32
            subplot(2, 2, 1)
            title([ferret(7:end) ' ' block ' ' side ': Map 1'])
            plot(allPSD(1).channel_f, mapped1(i).channelPSD, 'color', cols2use(i,:))
            hold on
        end
        xlabel('Frequency (Hz)')
        ylabel('Power/Frequency (dB/Hz)')
        xlim([0 160])
        hold off
        
        subplot(2,2,3)
        plot(mappedPeaks1)
        xlabel('Channel number')
        ylabel('Max PSD peak')
        hold on
        for i = 1 : 32
            scatter(i, mappedPeaks1(i), 50, 'MarkerEdgeColor',cols2use(i,:),'MarkerFaceColor',cols2use(i,:), 'LineWidth',3)
        end
        hold off
        
        
        mapped2 = allPSD(map2);
        mappedPeaks2 = maxPeak.maxPeak(map2);
        
        for i = 1 : 32
            subplot(2, 2, 2)
            title('Map 2')
            plot(allPSD(1).channel_f, mapped2(i).channelPSD, 'color', cols2use(i,:))
            hold on
        end
        xlabel('Frequency (Hz)')
        ylabel('Power/Frequency (dB/Hz)')
        xlim([0 160])
        hold off
        
        subplot(2,2,4)
        plot(mappedPeaks2)
        xlabel('Channel number')
        ylabel('Max PSD peak')
        hold on
        for i = 1 : 32
            scatter(i, mappedPeaks2(i), 50, 'MarkerEdgeColor',cols2use(i,:),'MarkerFaceColor',cols2use(i,:), 'LineWidth',3)
        end
        hold off
        
        savefig(h, fullfile(savePath, [block '_' side '_PSD_thresh5000_fig.fig']))
        
        close all
        
        clear allChans maxPeak allPSD h
        
        
        
    end
    
    
    
catch err
    err
    keyboard
end


end
