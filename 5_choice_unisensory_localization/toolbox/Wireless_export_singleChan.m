function [wireless] = Wireless_export_singleChan(ferret)
try
    
    if strcmp(ferret, 'K')
        F = 'F1504_Kiwi';
        
    elseif strcmp(ferret, 'E')
        F = 'F1507_Emu';
        
    elseif strcmp(ferret, 'B')
        F = 'F1510_Beaker';
        
    elseif strcmp(ferret, 'A')
        F = 'F1511_Animal';
        
    end
    
    savePath = ['E:\Soraya Data\' F '\Wireless_exported\'];
    
     if ~ exist (savePath, 'dir')
            mkdir(savePath)
     end
        
    saveDir = dir(savePath);
    savedFiles = {saveDir(:).name};
    
    WLpath = ['F:\Wireless\MATLAB_matched\' F ];
    pathdir = dir(WLpath);
    
    % find .h5 in directory
    h5Idx = ~cellfun('isempty',strfind({pathdir.name},'h5'));
    h5Dir = pathdir(h5Idx);
    
    for i = 114 : length(h5Dir)
        
        rec = h5Dir(i).name;
        file= fullfile(WLpath , rec);
        
        underscores = strfind(rec, '_');
        Bidx = strfind(rec, 'B');
        block = rec(Bidx:underscores(2)-1);
        
        
        check = cellfun( @(x) strcmp(x, block), savedFiles );
            
            if sum(check) == 1
                continue
            else
            end
            
        saveFolder = fullfile(savePath, block);
        mkdir(saveFolder)
        
        info= h5info(file);
        %h5disp(file);
        
        tracelength = info.Groups.Groups.Groups(1).Groups(2).Datasets(1).Dataspace.Size(1);
        
        nChan = info.Groups.Groups.Groups(1).Groups(3).Datasets(1).Dataspace.Size(2);
       
        %nChan = 32;
        
        disp([rec ' ' num2str(nChan)])
        
        for j = 1 : nChan
            
            saveName = [rec(1:end-3) '_Chan_' num2str(j) '_extracted.mat'];
            
            
                
                wireless.recording = saveName(1: length(saveName) - 14);
                
                
                wireless.block = block;
                wireless.channel = j;
                sideIdx = strfind(rec, 'HS');
                wireless.side = rec(sideIdx-1);
                
                % % Extract neural recordings
                
               
                
                wireless.trace = h5read(file, '/Data/Recording_0/AnalogStream/Stream_2/ChannelData', [1 j], [tracelength, 1]);
                %
                % Extract time info
                % wireless.timestamps = h5read(file, '/Data/Recording_0/AnalogStream/Stream_0/ChannelDataTimeStamps');
                %
                % % Extract digital waveforms
                % wireless.digital = h5read(file, '/Data/Recording_0/AnalogStream/Stream_2/ChannelData');
                %
                % Extract digital event streams
                % wireless.events = h5read(file, '/Data/Recording_0/EventStream/Stream_0/EventEntity_0');
                %
                % % Extract analogue stream
                % wireless.sine= h5read(file, '/Data/Recording_0/AnalogStream/Stream_0/ChannelData');
                
                % wireless.H020map = uint8([16 18 14 20 15 17 13 19 1 31 3 29 2 32 5 27 4 30 7 25 6 28 9 23 8 26 11 21 10 24 12 22]);
                % wireless.H008map = uint8([17 15 19 13 18 16 20 14 32 2 30 4 31 1 28 6 29 3 26 8 27 5 24 10 25 7 22 12 23 9 21 11]);
                
                % time = linspace (0, double(wireless.timestamps(3)), length(wireless.trace));
                % wireless.time = int32(time);
                
                
                save(fullfile(saveFolder, saveName), 'wireless','-v7.3')
                
                disp([rec ' Channel: ' num2str(j)])
                
                clear wireless
            
        end
        
        
    end
    
catch err
    err
    keyboard
end

end