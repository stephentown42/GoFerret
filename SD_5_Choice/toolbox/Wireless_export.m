function [wireless] = Wireless_export(ferret)
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
saveDir = dir(savePath);
savedFiles = {saveDir(:).name};

WLpath = ['F:\Wireless\MATLAB_matched\' F];
pathdir = dir(WLpath);

% find .h5 in directory
h5Idx = ~cellfun('isempty',strfind({pathdir.name},'h5'));
h5Dir = pathdir(h5Idx);

for i = 24%1: length(h5Dir)
    
    rec = h5Dir(i).name;
    file= fullfile(WLpath , rec);
    
    saveName = [rec(1:end-3) '_extracted.mat'];
    
   check = cellfun( @(x) strcmp(x, saveName), savedFiles );
     
     if sum(check) == 1
         continue
     else
    
    
    %info= h5info(file);
    %h5disp(file);
    
    wireless.recording = rec;
    
    % % Extract neural recordings
    wireless.trace = h5read(file, '/Data/Recording_0/AnalogStream/Stream_1/ChannelData');
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
    
    
    save([savePath, saveName], 'wireless','-v7.3')
    
    disp(rec)
    
     end
    clear wireless
    
end

% end