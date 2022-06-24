function varargout = trackLEDsOffline_mmRead2(varargin)

try
    
    Dropbox = fullfile('C:\Users', getenv('USERNAME'),'Dropbox');
    
    if nargin < 2,
        switch getenv('COMPUTERNAME')
            case 'ROCKEFELLER-HP2'
                vidDir = 'K:\F1201_FlorenceWE';
            case 'TOWN'
                vidDir = 'C:\Data\Owen\Blocks';
            case 'RVC-HP1'
                vidDir = 'C:\Data\UCL_Behaving\F1201_FlorenceWE';   
            case 'RVC_OPTIPLEX'
                vidDir = 'D:\FlorenceWE';  
        end
        
        [vidFile, dataDir, ~] = uigetfile('*.avi','Select video', vidDir);
        
        % Select block directory with tracking data
%         dataDir = uigetdir('C:\Data\Owen','Please select directory to find .AVI in');
% 
%         % Load video
%         vidFile = ls( fullfile( dataDir, '*.avi'));
    else
        dataDir = varargin{1};
        vidFile = varargin{2};
    end 
    
    
    % Ensure mmread library available
    mmPath = fullfile( Dropbox, 'MATLAB\lib\MMRead\');
    
    if ~isdir(mmPath), error('mm path not defined'); end
    
    addpath(mmPath)
    
    % Read in video
    [obj, ~] = mmread( fullfile( dataDir, vidFile));
       
    % Define parameters for loop
    nFrames  = obj.nrFramesTotal;    
        
    % Define output parameters
    green = nan(nFrames,3);
    red   = nan(nFrames,3);
    fCount = 0;
    
    % Set up progress report    
    h  = waitbar(0, vidFile);
    
    for i = 1 : nFrames

        % Report progress
        waitbar((i/nFrames), h, sprintf('Tracking frames %d of %d',i, nFrames))
       
        % Load video
        video = obj.frames(i).cdata;
        
        % Find max on red and green chans
        gIM = video(:,:,2,:) - video(:,:,3,:) - video(:,:,1,:);
        rIM = video(:,:,1,:) - video(:,:,2,:) - video(:,:,3,:);
        
        % Liberate memory
        clear video
        
        % Find max values
        green(i,1) = max(gIM(:));
        red(i,1)  = max(rIM(:));            
        
        % get Centroid
        [green(i,2), green(i,3)] = getCentroid(gIM,  green(i,1));
        [red(i,2), red(i,3)] = getCentroid(rIM, red(i,1) );                 
    end

    % Close progress bar
    close(h)
    
    %% Fit bimodal distribution to maximum values to predict threshold
    
    % Create anonymous function
    pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
                         p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
    
    % Constants
    pStart = .5;
    lb     = [0 -Inf -Inf 0 0];
    ub     = [1 Inf Inf Inf Inf];

    % Estimate distribution parameters for green LED
    muStart    = quantile(green(:,1),[.25 .75]);
    sigmaStart = sqrt(var(green(:,1)) - .25*diff(muStart).^2);
    start      = [pStart muStart sigmaStart sigmaStart];    
    options    = statset('MaxIter',3000, 'MaxFunEvals',6000);
    gParamEsts = mle(green(:,1), 'pdf',pdf_normmixture, 'start',start, ...
                          'lower',lb, 'upper',ub, 'options',options);

    % Estimate distribution parameters for red LED
    muStart    = quantile(red(:,1),[.25 .75]);
    sigmaStart = sqrt(var(red(:,1)) - .25*diff(muStart).^2);
    start      = [pStart muStart sigmaStart sigmaStart];    
    options    = statset('MaxIter',3000, 'MaxFunEvals',6000);
    rParamEsts = mle(red(:,1), 'pdf',pdf_normmixture, 'start',start, ...
                          'lower',lb, 'upper',ub, 'options',options);
                      
    % Calculate thresholds based on midpoint between means
    greenThresh = mean(gParamEsts(2:3));
    redThresh   = mean(rParamEsts(2:3));
    
    % Check thresholds are reasonable based on standard deviations
    if abs((greenThresh-gParamEsts(3)) / gParamEsts(5)) < 2,
        warning('Green threshold less than 2 standard deviations from mean')
    end
    
    if abs((redThresh-rParamEsts(3)) / rParamEsts(5)) < 2,
        warning('Red threshold less than 2 standard deviations from mean')
    end
    
    %% Supervision of thresholding (and intervention if necessary)
    
    % Plot threshold for green LED
    fT = figure; 
    hold on
    plot( single(green(:,1)),'g')
    gp = plot( [1 nFrames], [greenThresh greenThresh], 'color', [0 0.4 0]); 
    
    % Query user
    happy = questdlg('Are you happy with the green threshold?');
    
    while strcmp('No',happy)
        delete(gp)
        [~, greenThresh] = ginput(1);
        
        gp    = plot( [1 nFrames], [greenThresh greenThresh], 'color', [0 0.4 0]);
        happy = questdlg('Are you happy with the green threshold?');
    end
       
    % Plot threshold for red LED
    plot( single(red(:,1)),'r')
    rp = plot( [1 nFrames], [redThresh redThresh], 'color', [0.4 0 0]);
    
    % Query user
    happy = questdlg('Are you happy with the red threshold?');
    
    while strcmp('No',happy)
        delete(rp)
        [~, redThresh] = ginput(1);
        
        % Replot and rethrow query
        rp    = plot( [1 nFrames], [redThresh redThresh], 'color', [0.4 0 0]);
        happy = questdlg('Are you happy with the red threshold?');
    end
    
    plot( [1 nFrames], [redThresh redThresh], 'color', [0.4 0 0])
    saveas( fT, fullfile( dataDir, 'TrackingThreshold.fig'))
    close(fT)
    clear fT
    
    % Apply threshold    
    green(green(:,1) < greenThresh, 2:3) = NaN;
    red(red(:,1) < redThresh, 2:3) = NaN;
    
    
%% Check tracking data
    trk = v2struct(green, red, greenThresh, redThresh);

    [green, red, mask] = checkTrackingData(trk);
    
%% Rethrow tracking for missing frames using mask to hide reflections
    frameList = find(isnan(red(:,2)));
    nFrames   = length(frameList);

    % Invert mask 
    mask = mask==0;
    mask = repmat(mask,[1,1,3]);
    
    % Set up progress report    
    h  = waitbar(0, 'Recovering masked frames');   
    
    % For each frame
    for i = 1 : nFrames
        
        fIdx = frameList(i);
        
        % Report progress
        waitbar((i/nFrames), h, sprintf('Tracking frames %d of %d',i, nFrames))
        
        % Load video
        video = obj.frames(fIdx).cdata;        
%         video = read(obj,fIdx);
        
        % Apply mask
        video = video .* uint8(mask);
        
         % Find max on red and green chans
        gIM = video(:,:,2,:) - video(:,:,3,:) - video(:,:,1,:);
        rIM = video(:,:,1,:) - video(:,:,2,:) - video(:,:,3,:);
        
        % Liberate memory
        clear video
        
        % Find max values
        green(fIdx,1) = max(gIM(:));
        red(fIdx,1)  = max(rIM(:));            
        
        % get Centroid
        [green(fIdx,2), green(fIdx,3)] = getCentroid(gIM,  green(fIdx,1));
        [red(fIdx,2), red(fIdx,3)] = getCentroid(rIM, red(fIdx,1) );  
        
    end    
    
    % Close progress bar
    close(h)
    
    %% Check tracking data
    trk = v2struct(green, red, greenThresh, redThresh);

    [green, red, mask] = checkTrackingData(trk);
    

    %% Repeat LED detection with thresholding    
    playTracker(green, red, obj,'mmRead');
    
%     % Set up target movie
%     saveName  = fullfile(dataDir,'Result.mp4');
%     writerObj = VideoWriter(saveName,'MPEG-4');
%     writerObj.FrameRate = get(obj,'frameRate');
%     open(writerObj);
%     
%     f = figure('MenuBar',   'none',...
%         'Units',    'pixels',...
%         'position', [200 200 640 480],...
%         'Toolbar',  'none');
%     
%     ax = axes('position',[0 0 1 1]);
%     
%     
%     % Set up progress report    
%     h  = waitbar(0, vidFile);
%     
%     for i = 1 : nI
% 
%         % Report progress
%         waitbar((i/nI), h, sprintf('Tracking frames %d to %d of %d',startIdx(i), endIdx(i), nFrames))
%         
%         % Load video
%         video = read(obj,[startIdx(i) endIdx(i)]);
%         
%         % Find max on red and green chans
%         gIM = video(:,:,2,:) - video(:,:,3,:) - video(:,:,1,:);
%         rIM = video(:,:,1,:) - video(:,:,2,:) - video(:,:,3,:);        
%                 
%         % Threshold
%         gIM(gIM < greenThresh) = 0;
%         rIM(rIM < redThresh)   = 0;
%         
%         % Convert image to binary (is max? 0|1)
%         gMax = max(gIM, [], 1);
%         rMax = max(rIM, [], 1);        
%         gMax = squeeze( max(gMax, [], 2));
%         rMax = squeeze( max(rMax, [], 2));
%         
%         % For each frame (I don't know how to vectorize this)
%         for j = 1 : length(gMax),
%                        
%             fCount = fCount + 1;
%             
%             % get Centroid
%             [green(fCount,2), green(fCount,3)] = getCentroid(gIM(:,:,1,j), gMax(j));
%             [red(fCount,2), red(fCount,3)] = getCentroid(rIM(:,:,1,j), rMax(j));
%             
%             % Plot figure
%             axes(ax)
%             cla
%             hold on
%             image(video(:,:,:,j))            
%                        
%             eval( sprintf('fRange = %d : %d;', max([1 fCount-100]), fCount)) % Get range for line plot
%             
%             if all( ~isnan( green(fCount,2:3))),
%                 plot( green(fCount,2), green(fCount,3), 'xg')                    
%                 plot( green(fRange,2), green(fRange,3), 'Color',[0.5 1 0.5])   
%             end
%             
%             if all( ~isnan( red(fCount,2:3))),
%                 plot( red(fCount,2),   red(fCount,3),   'xr')
%                 plot( red(fRange,2),   red(fRange,3),   'Color',[1 0.5 0.5])
%             end
%                                     
%             set(ax,'xtick',[],'ytick',[],'box', 'off','ylim',[0 480],'xlim',[0 640])
% 
%             % Save as frame
%             frame = getframe(f);
%             writeVideo(writerObj, frame)
%         end
%     end
% 
%     % Close video object
%     close(writerObj);
%     close(f)
%     
%     % Close progress bar
%     close(h)
    
    % Save output
    if nargout < 2,
        save( fullfile( dataDir, 'offlineTracking.mat'), 'green','red', 'greenThresh','redThresh')
    else
        varargout{1} = green;
        varargout{2} = red;
    end

    
    
catch err
%     close(h)
%     close(writerObj);
    
    err
    keyboard
end


function [x, y] = getCentroid(IM, iMax)

[x, y] = deal(nan);

% Create binary image
isMax = IM == iMax;   

if any(isMax(:)),
    
    % Get blob properties
    RP = regionprops(isMax,'Centroid','Area');
    
    % Choose the blob closest to the center of the arena
%     if numel( RP) > 1,
%         keyboard
%     end
    
%     % Choose the largest blob
    blobArea = cat(1,RP.Area);
    blobIdx  = find(blobArea == max(blobArea));
        
    % Throw away the losers
    centroid = cat(1,RP.Centroid);
    
    % If there's a clear winner (give up otherwise)
    if sum(blobIdx) == 1,        
        
        % Assign the winner
        x = centroid(blobIdx, 1);
        y = centroid(blobIdx, 2);
        
    else
        x = mean(centroid(:,1));
        y = mean(centroid(:,2));
    end
end

if x == 320.5; x = nan; end
if y == 240.5; y = nan; end
