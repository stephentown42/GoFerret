function [MCS_sync] = Extract_MCS_sync(ferret)

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

WLpath = ['F:\Wireless\MATLAB_matched\' F];
WLdir = dir(fullfile(WLpath,'*Block*'));

savePath = ['E:\Soraya Data\' F '\MCS_sync'];
saveDir = dir(savePath);
savedFiles = {saveDir(:).name};


for i = 1 : length(WLdir)
    
    % % % path = 'C:\Users\Soraya\Documents\Data\Beaker practice';
    % % % pathdir = dir(path);
    % % %
    % % % % find .h5 in directory
    % % % h5Idx = ~cellfun('isempty',strfind({pathdir.name},'h5'));
    % % % h5Dir = pathdir(h5Idx);
    
    rec = WLdir(i).name;
    file = fullfile(WLpath , rec);
    
    saveName = [rec(1:end-3) '_SYNC.mat'];
    
    check = cellfun( @(x) strcmp(x, saveName), savedFiles );
    
    if sum(check) == 1
        continue
    else
    
    
    
    %info= h5info(file);
    % h5disp(file);
    
    MCS_sync.recording = rec(1:end-3);
    
    % % Extract neural recordings
    % wireless.trace = h5read(file, '/Data/Recording_0/AnalogStream/Stream_1/ChannelData');
    
    
    % Extract time info
    MCS_sync.timestamps = h5read(file, '/Data/Recording_0/AnalogStream/Stream_0/ChannelDataTimeStamps');
    
    % Extract digital waveforms
    MCS_sync.digital = h5read(file, '/Data/Recording_0/AnalogStream/Stream_2/ChannelData');
    
    % % Extract digital event streams
    % MCSsync.events = h5read(file, '/Data/Recording_0/EventStream/Stream_0/EventEntity_0');
    
    % Extract analogue stream
    MCS_sync.sine= h5read(file, '/Data/Recording_0/AnalogStream/Stream_0/ChannelData');
    
    % wireless.H020map = uint8([16 18 14 20 15 17 13 19 1 31 3 29 2 32 5 27 4 30 7 25 6 28 9 23 8 26 11 21 10 24 12 22]);
    % wireless.H008map = uint8([17 15 19 13 18 16 20 14 32 2 30 4 31 1 28 6 29 3 26 8 27 5 24 10 25 7 22 12 23 9 21 11]);
    
    timeline = linspace (0, double(MCS_sync.timestamps(3)), length(MCS_sync.digital));
    MCS_sync.timeline = int32(timeline);
    
    
    save([savePath '\' saveName], '-struct', 'MCS_sync','-v7.3')
    
    end
end

catch err
    err
    keyboard
end

end