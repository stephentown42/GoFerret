function varargout = trackLEDsOffline_old_WIRELESS(varargin)

try
    
    homeDir = fullfile('C:\Users', getenv('USERNAME'),'homeDir');
    
    if nargin < 2,
        
        vidDir = 'C:\Users\Soraya\Documents\Data\Kiwi\RV2\Block8-58';
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
    
    
    obj = VideoReader( fullfile(dataDir, vidFile));
    
    % Define parameters for loop
    frameInt = 3000;                        % ~ 2.75 GB (11 GB for 4 processors); ~ 12 seconds to load
%    nFrames  = 3000; %get(obj,'NumberOfFrames');    
    nFrames  = get(obj,'NumberOfFrames');
%    warning('nFrames set manually to 3e3')
    nI       = ceil(nFrames / frameInt);
    startIdx = 1 : frameInt : nFrames;
    endIdx   = [startIdx(2:end)-1  nFrames];
    
    % Define output parameters
    blue = nan(nFrames,3);
    red   = nan(nFrames,3);
    fCount = 0;
    
    % Set up progress report    
    h  = waitbar(0, vidFile);
    
    for i = 1 : nI

        % Report progress
        waitbar((i/nI), h, sprintf('Tracking frames %d to %d of %d',startIdx(i), endIdx(i), nFrames))
        
        % Load video
        video = read(obj,[startIdx(i) endIdx(i)]);
        
        % Find max on red and green chans
        %gIM = video(:,:,2,:) - video(:,:,3,:) - video(:,:,1,:);
        bIM = video(:,:,3,:) - video(:,:,1,:) - video(:,:,2,:);
        rIM = video(:,:,1,:) - video(:,:,2,:) - video(:,:,3,:);
        
        % Liberate memory
        clear video
        
        % Find max values
        bMax = max(bIM, [], 1);
        rMax = max(rIM, [], 1);
        
        bMax = max(bMax, [], 2);
        rMax = max(rMax, [], 2);
        
        blue(startIdx(i):endIdx(i),1) = squeeze(bMax);
        red(startIdx(i):endIdx(i),1)   = squeeze(rMax); 
        
        for j = 1 : length(bMax),
                       
            fCount = fCount + 1;
            
            % get Centroid
            [blue(fCount,2), blue(fCount,3)] = getCentroid(bIM(:,:,1,j), bMax(j));
            [red(fCount,2), red(fCount,3)] = getCentroid(rIM(:,:,1,j), rMax(j));           
        end        
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
    muStart    = quantile(blue(:,1),[.25 .75]);
    sigmaStart = sqrt(var(blue(:,1)) - .25*diff(muStart).^2);
    start      = [pStart muStart sigmaStart sigmaStart];    
    options    = statset('MaxIter',3000, 'MaxFunEvals',6000);
    gParamEsts = mle(blue(:,1), 'pdf',pdf_normmixture, 'start',start, ...
                          'lower',lb, 'upper',ub, 'options',options);

    % Estimate distribution parameters for red LED
    muStart    = quantile(red(:,1),[.25 .75]);
    sigmaStart = sqrt(var(red(:,1)) - .25*diff(muStart).^2);
    start      = [pStart muStart sigmaStart sigmaStart];    
    options    = statset('MaxIter',3000, 'MaxFunEvals',6000);
    rParamEsts = mle(red(:,1), 'pdf',pdf_normmixture, 'start',start, ...
                          'lower',lb, 'upper',ub, 'options',options);
                      
    % Calculate thresholds based on midpoint between means
    blueThresh = mean(gParamEsts(2:3));
    redThresh   = mean(rParamEsts(2:3));
    
    % Check thresholds are reasonable based on standard deviations
    if abs((blueThresh-gParamEsts(3)) / gParamEsts(5)) < 2,
        warning('Green threshold less than 2 standard deviations from mean')
    end
    
    if abs((redThresh-rParamEsts(3)) / rParamEsts(5)) < 2,
        warning('Red threshold less than 2 standard deviations from mean')
    end
    
    %% Supervision of thresholding (and intervention if necessary)
    
    % Plot threshold for blue LED
    fT = figure; 
    hold on
    plot( single(blue(:,1)),'b')
    gp = plot( [1 nFrames], [blueThresh blueThresh], 'color', [0 0.4 0]); 
    
    % Query user
    happy = questdlg('Are you happy with the blue threshold?');
    
    while strcmp('No',happy)
        delete(gp)
        [~, blueThresh] = ginput(1);
        
        gp    = plot( [1 nFrames], [blueThresh blueThresh], 'color', [0 0.4 0]);
        happy = questdlg('Are you happy with the blue threshold?');
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
    blue(blue(:,1) < blueThresh, 2:3) = NaN;
    red(red(:,1) < redThresh, 2:3) = NaN;
    
    
%% Check tracking data
    trk = v2struct(blue, red, blueThresh, redThresh);

    [blue, red, mask] = checkTrackingData(trk);
    
%% Rethrow tracking for missing frames using mask to hide reflections
    frameList = find(isnan(red(:,2)));
    nFrames   = length(frameList);

    % Invert mask 
    mask = mask==0;
    mask = repmat(mask,[1,1,3]);
    
    % For each frame
    for i = 1 : nFrames
        
        fIdx = frameList(i);
        
        % Load video
        video = read(obj,fIdx);
        
        % Apply mask
        video = video .* uint8(mask);
        
        % Find max on red and green chans
        bIM = video(:,:,3,:) - video(:,:,1,:) - video(:,:,2,:);
        rIM = video(:,:,1,:) - video(:,:,2,:) - video(:,:,3,:);
        
        % Liberate memory
        clear video
        
        % Find max values
        bMax = max(bIM, [], 1);
        rMax = max(rIM, [], 1);
        
        bMax = max(bMax, [], 2);
        rMax = max(rMax, [], 2);
                        
        blue(fIdx,1) = bMax;
        red(fIdx,1)   = rMax; 
        
        % Get position
        [blue(fIdx,2), blue(fIdx,3)] = getCentroid(bIM(:,:), bMax);
        [red(fIdx,2),   red(fIdx,3)]   = getCentroid(rIM(:,:), rMax);
    end
    
    %% Check tracking data
    trk = v2struct(blue, red, blueThresh, redThresh);

    [blue, red, mask] = checkTrackingData_WIRELESS(trk);
    

    %% Repeat LED detection with thresholding    
    playTracker(blue, red, obj);
    
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
        save( fullfile( dataDir, 'offlineTracking.mat'), 'blue','red', 'blueThresh','redThresh')
    else
        varargout{1} = blue;
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

