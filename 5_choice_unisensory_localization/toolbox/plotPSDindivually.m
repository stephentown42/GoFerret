function [] = plotPSDindivually()

% choose ferret/ block to analyse
    
    F = 3;
    
   % blocks = {'Block10-126' };%, 'Block10-63', 'Block10-64'};% , 'Block10-59'};
        blocks = {'BlockA-23' , 'BlockA-21', 'BlockA-18' , 'BlockA-17', 'BlockA-16', 'BlockA-15', 'BlockA-14'};

    ferrets = {'F1510_Beaker', 'F1507_Emu', 'F1504_Kiwi', 'F1511_Animal'};
    
    ferret = ferrets{F};
    
    
    for B = 1 : length (blocks)
        
        block = blocks{B};
        
        
     %   savePath = ['D:\' ferret '\ROUGHdepthPSD\'];
        
        savePath = 'E:\Soraya Data\F1504_Kiwi\ROUGHdepthPSD';
        
         % Input paths
        path = savePath;
        pathDir = dir(fullfile(path, ['*' block '*_*PSDs_thresh5000.mat'])); 
        
        load(fullfile(path, pathDir.name));

        HS  = strfind(pathDir.name,'HS');
        side = pathDir.name(HS-1 : HS+1);
        
        red = (1/16):(1/16):1;
        sixteenones = ones(16,1);
        red = [red' ; sixteenones];
        blue = flipud(red);
        green = zeros(1,32)';
        cols2use = [red green blue];
        
        
   h = figure;
   
   annotation('textbox', [0.1 0.1 1 0], ...
    'String', [ferret ' ' block ' ' side], ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center')
   
        for i = 1 : 32
            subplot(6, 6, i)
            
            plot(allPSD(i).channel_f, allPSD(i).channelPSD, 'color', cols2use(i,:))
            hold on  
            title(['Unmapped channel ' num2str(i)])    
            xlim([0 160])
            hold off
        end
%         xlabel('Frequency (Hz)')
%         ylabel('Power/Frequency (dB/Hz)')
       
savefig(h, fullfile(savePath, [block '_' side '_PSD_indivualPlot_fig.fig']))
       
       
map1 =[16 18 14 20 15 17 13 19 1 31 3 29 2 32 5 27 4 30 7 25 6 28 9 23 8 26 11 21 10 24 12 22];
map2 = [17 15 19 13 18 16 20 14 32 2 30 4 31 1 28 6 29 3 26 8 27 5 24 10 25 7 22 12 23 9 21 11];

mapped1 = allPSD(map1);

h2 = figure;

 annotation('textbox', [0.1 0.1 1 0], ...
    'String', [ferret ' ' block ' ' side: 'MAP 1'], ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center')
   
        for i = 1 : 32
            subplot(6, 6, i)
            
            plot(mapped1(i).channel_f, mapped1(i).channelPSD, 'color', cols2use(i,:))
            hold on  
            title(['MAP 1- channel ' num2str(i)])    
            xlim([0 160])
            hold off
        end

             
savefig(h2, fullfile(savePath, [block '_' side '_PSD_indivualPlot_MAP1_fig.fig']))
      
mapped2 = allPSD(map2);

h3 = figure;

 annotation('textbox', [0.1 0.1 1 0], ...
    'String', [ferret ' ' block ' ' side: 'MAP 2'], ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center')
   
        for i = 1 : 32
            subplot(6, 6, i)
            
            plot(mapped2(i).channel_f, mapped2(i).channelPSD, 'color', cols2use(i,:))
            hold on  
            title(['MAP 2- channel ' num2str(i)])    
            xlim([0 160])
            hold off
        end

             
savefig(h3, fullfile(savePath, [block '_' side '_PSD_indivualPlot_MAP2_fig.fig']))
              


    end

end