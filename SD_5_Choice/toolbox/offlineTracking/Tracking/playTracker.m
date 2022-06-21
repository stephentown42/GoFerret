function playTracker(green, red, video, block, saveDir, method)

% Inputs (all optional): 
% green - n x 3 matrix with x and y pixels of putative green led, where n is the number of frames
% red   - n x 3 matrix with x and y pixels of putative red led, where n is the number of frames
% video - can be:   videoReader object
%                   mmRead object
%                   pathname specifying a video file
% method - can be mmread or videoReader (default)

%% Organize inputs
   
% Request tracking data if not input argument
if ~exist('green','var') || ~exist('red','var')
   
    [trkFile, trkDir, ~] = uigetfile('C:\Data\Owen\Blocks\*.mat');
    
    load( fullfile( trkDir, trkFile));            
end

% Request string if video doesn't exist
if ~exist('video','var')        
    [vidFile, dataDir, ~] = uigetfile('C:\Data\Owen\Blocks\*.avi');
    video = fullfile( dataDir, vidFile);
end


% Default method
if ~exist('method','var')
    method = 'VideoReader';
end

% If string
if isa( video, 'char')
       
    switch method
        case 'VideoReader'
            video = VideoReader(video);
        case 'mmRead'
            video = mmread(video);
    end
end

obj = video; clear video

% If video reader
if isa( obj, 'VideoReader')
        
    frameInt = 3000;                        % ~ 2.75 GB (11 GB for 4 processors); ~ 12 seconds to load
    nFrames  = get(obj,'NumberOfFrames');
    nI       = ceil(nFrames / frameInt);
    startIdx = 1 : frameInt : nFrames;
    endIdx   = [startIdx(2:end)-1  nFrames];
else
    nFrames = obj.nrFramesTotal;
end
    



%% Set up

% % Request save directory
% [saveName, savePath, ~] = uiputfile('*.mp4', 'Result');
% saveName  = fullfile(savePath, saveName);

saveVid = [block '.mp4'];
saveName = fullfile(saveDir, saveVid);

% Set up target movie
writerObj = VideoWriter(saveName,'MPEG-4');

% Set frame rate
switch method
    case 'VideoReader'        
        writerObj.FrameRate = get(obj,'frameRate');
    case 'mmRead'
        writerObj.FrameRate = obj.rate;
end

% Open write 
open(writerObj);

% Create figure and axes
f = figure('MenuBar',   'none',...
    'Units',    'pixels',...
    'position', [1270 50 640 480],...
    'Toolbar',  'none');

ax = axes('position',[0 0 1 1]);


% Set up progress report
h  = waitbar(0, saveName);


%% VideoReader
if strcmp(method,'VideoReader')

    fCount = 0;

    % For each set of frames 
    for i = 1 : nI

        % Report progress
        waitbar((i/nI), h, sprintf('Tracking frames %d to %d of %d',startIdx(i), endIdx(i), nFrames))

        
        % Load video
        video = read(obj,[startIdx(i) endIdx(i)]);

        % For each frame (I don't know how to vectorize this)
        for j = 1 : 1+endIdx(i)-startIdx(i)

            fCount = fCount + 1;        

            % Plot figure        
            cla
            hold on
            image(video(:,:,:,j))

            eval( sprintf('fRange = %d : %d;', max([1 fCount-100]), fCount)) % Get range for line plot

            if all( ~isnan( green(fCount,2:3))),
                plot( green(fCount,2), green(fCount,3), 'xg')
                plot( green(fRange,2), green(fRange,3), 'Color',[0.5 1 0.5])
            end

            if all( ~isnan( red(fCount,2:3))),
                plot( red(fCount,2),   red(fCount,3),   'xr')
                plot( red(fRange,2),   red(fRange,3),   'Color',[1 0.5 0.5])
            end

            set(ax,'xtick',[],'ytick',[],'box', 'off','ylim',[0 480],'xlim',[0 640])

            % Save as frame
            frame = getframe(f);
            writeVideo(writerObj, frame)
        end
    end
end


%% mmRead
if strcmp(method,'mmRead')

    fCount = 0;

    % For each set of frames 
    for i = 1 : nFrames

        % Report progress
        waitbar((i/nFrames), h, sprintf('Tracking frames %d of %d',i, nFrames))

        % Load video
        video = obj.frames(i).cdata;   
       
        % Plot figure
        cla
        hold on
        image(video)
        
        eval( sprintf('fRange = %d : %d;', max([1 i-100]), i)) % Get range for line plot
        
        if all( ~isnan( green(i,2:3))),
            plot( green(i,2), green(i,3), 'xg')
            plot( green(fRange,2), green(fRange,3), 'Color',[0.5 1 0.5])
        end
        
        if all( ~isnan( red(i,2:3))),
            plot( red(i,2),   red(i,3),   'xr')
            plot( red(fRange,2),   red(fRange,3),   'Color',[1 0.5 0.5])
        end
        
        set(ax,'xtick',[],'ytick',[],'box', 'off','ylim',[0 480],'xlim',[0 640])
        
        % Save as frame
        frame = getframe(f);
        writeVideo(writerObj, frame)
        
    end
end

%% Close video object
close(writerObj);
close(f)

% Close progress bar
close(h)
