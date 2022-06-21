function objectTracking_SD

global cam 

% Connect to webcam if matlab doesn't already have control
if ~isfield(cam,'webcam')
        
    camList = webcamlist;   % List cameras
    camIdx  = find(strcmp(camList,'USB_Camera'));
    cam.webcam = webcam(camIdx);    
end

% Open tcp/ip connection
cam.tcpip = tcpip('0.0.0.0', 30000, 'NetworkRole', 'server');
fprintf('Waiting for TCP / IP client (GoFerret)\n')
fopen(cam.tcpip);
fwrite(cam.tcpip, rand(1))

% Get initial frame, start time and time to analyse
cam.previousFrame = snapshot(cam.webcam);
cam.GFexit = false;
% cam.startTime = now;
% cam.timeLimit = 3600;     % Time limit in seconds
% cam.timeLimit = cam.timeLimit / (24*60*60); % Convert to days
 
% % Define region of interest
% roiFig = figure('Name','Define arena','NumberTitle','off');
% [cam.arena.mask, cam.arena.xi, cam.arena.yi] = roipoly(cam.previousFrame);
% set(roiFig, 'Name','Define  spout area')
% [cam.center.mask, cam.center.xi, cam.center.yi] = roipoly(cam.previousFrame);
% close(roiFig)

% Identify ROI automatically
BW = rgb2gray(cam.previousFrame);
BW = logical( BW>100);

blobs = regionprops(BW,'Area','ConvexHull','BoundingBox');

if numel(blobs) ==0
    error('Could not find white area in mask image - arena too dark!')
end

blobs(cat(1,blobs.Area)<1000) = [];  % eliminate small blobs
rectangularity = cat(1,blobs.BoundingBox);
rectangularity = rectangularity(:,4) ./ rectangularity(:,3);
idx = rectangularity < 1;
rectangularity(idx) = rectangularity(idx).^-1;
bestBlob = rectangularity == max(rectangularity);
blobs = struct2cell(blobs);
blobBoundary = blobs{3, bestBlob};

cam.center.xi = blobBoundary(:,1);
cam.center.yi = blobBoundary(:,2);
cam.center.mask = poly2mask(cam.center.xi, cam.center.yi,480,640); 

% Set up intensity of center region histogram
cam.center.intensity = [];
cam.center.histFig = figure('Name','Center Region Intensity','NumberTitle','off');
cam.center.histEdges = -1 : 0.1 : 1;
cam.center.histogram = cell(1,3);

fillerHist = histc(rand(1,100),cam.center.histEdges);
subplot(1,3,1); cam.center.histogram{1} = plot(cam.center.histEdges,fillerHist,'r'); title('Red')
subplot(1,3,2); cam.center.histogram{2} = plot(cam.center.histEdges,fillerHist,'g'); title('Green')
subplot(1,3,3); cam.center.histogram{3} = plot(cam.center.histEdges,fillerHist,'b'); title('Blue')


% % Load calibration image
% calibDir = 'C:\Users\Ferret\Pictures\Debut';
% calibIM = imread( fullfile( calibDir, 'calibIMfile.jpg'));
% 
% % Image registration
% [optimizer, metric] = imregconfig('Multimodal');
% registered = imregister(cam.previousFrame, calibIM, 'similarity', optimizer, metric);
% tform = imregtform(cam.previousFrame, calibIM, 'similarity', optimizer, metric);

% Build variance map
% Record a period of video under the current lighting conditions to give a
% variance measure to each pixel. Because lighting conditions vary through
% the box, it is more accurate to weight each pixel according to its noise
% characteristics to avoid confusions. 


% Set up players
cam.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
cam.maskFig = figure('Name','Mask');
cam.maskAxes = axes('xtick',[],'ytick',[]);
cam.maskIM  = imagesc( cam.previousFrame(:,:,1));


% set up saving video
t = fix(clock);
videofile = sprintf('%d_%d_%d-%d_%d_video.avi', t(1), t(2), t(3), t(4), t(5));
videoPath = 'F:\Video';
cam.writerObj = VideoWriter(fullfile(videoPath, videofile));
cam.writerObj.FrameRate = 20;
open(cam.writerObj);


% Plot regions of interest on mask image
hold on
% plot(cam.arena.xi, cam.arena.yi,'w')
plot(cam.center.xi, cam.center.yi,'r')



% Setup timer
cam.tasktimer = timer( 'TimerFcn',         @(~,~)runAnalysis,...
                        'BusyMode',         'drop',...
                        'ExecutionMode',    'fixedRate',...
                        'Period',           0.05);
                
start(cam.tasktimer)



                
                
    function runAnalysis
        
        global cam
        
        % Get most recent image                 
        newFrame = snapshot(cam.webcam);       
        cam.videoPlayer.step(newFrame);
        
%         % Apply region of interest (roi) filters
%         newFrame(~cam.arena.mask) = 0;
%        
%         % Compare the two images 
%         changeF  = abs(cam.previousFrame - newFrame);    % Image subtraction
%         cam.previousFrame = newFrame;
%         
%         % Emphasize difference
%         changeF  = max(changeF, [],3);              % Find max difference across channels                     
%         changeF  = filter2(ones(32)./9, changeF);   % Low pass filter (smooth)
%         changeF( changeF<600 & changeF>100) = 100;  % Minimize noise caused by reflections in box
%         changeF(1) = 1e4;                           % Standardize for plotting
% 
%         % Update mask with motion
%         set(cam.maskIM,'CData',changeF) 

        % Split image up into rgb channels
        redFrame   = newFrame(:,:,1);
        greenFrame = newFrame(:,:,2);
        blueFrame  = newFrame(:,:,3);

        % Calculate intensity within region of interest
        redIntensity   = mean(redFrame(cam.center.mask));
        greenIntensity = mean(greenFrame(cam.center.mask));
        blueIntensity  = mean(blueFrame(cam.center.mask));
        
        % Calculate average intensity outside region of interest
        redAverage   = mean(redFrame(cam.center.mask==0));
        greenAverage = mean(greenFrame(cam.center.mask==0));
        blueAverage  = mean(blueFrame(cam.center.mask==0));
                
        % Normalize intensity relative to average outside ROI    
        redIntensityZ = (redIntensity-redAverage) / (redIntensity + redAverage);
        greenIntensityZ = (greenIntensity-greenAverage) / (greenIntensity + greenAverage);
        blueIntensityZ = (blueIntensity-blueAverage) / (blueIntensity + blueAverage);

        % Add to memory
        cam.center.intensity = [cam.center.intensity;
                                redIntensityZ, greenIntensityZ, blueIntensityZ];
                
        % Calculate intensity distribution in center region        
        redHist   = histc(cam.center.intensity(:,1), cam.center.histEdges);      
        greenHist = histc(cam.center.intensity(:,2), cam.center.histEdges);      
        blueHist  = histc(cam.center.intensity(:,3), cam.center.histEdges);      
        
        % Update graphs
        set(cam.center.histogram{1},'YData',redHist)
        set(cam.center.histogram{2},'YData',greenHist)
        set(cam.center.histogram{3},'YData',blueHist)
                
        % Return output to tcpip       
        fwrite(cam.tcpip,  double(blueIntensityZ < 0.5))
        
        % Get GoFerret status
        if cam.tcpip.BytesAvailable > 0    
            cam.GFexit = fread(cam.tcpip, cam.tcpip.BytesAvailable);
            cam.GFexit = logical(cam.GFexit);
        end
        
        %Save image to video
        writeVideo(cam.writerObj,newFrame); 
       
       
        if cam.GFexit
             
            fprintf('GoFerret closed - shutting down\n') 
            release(cam.videoPlayer)
            
            % Close all open figures
            close( findobj(0,'type','fig'))
            
            % close video file
            close(cam.writerObj);
            
            fclose(cam.tcpip);
            delete(cam.tcpip);
                        
            stop(cam.tasktimer)
            clear global cam               
        end
        