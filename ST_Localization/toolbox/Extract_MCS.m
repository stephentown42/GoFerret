function X = Extract_MCS(sourceDir, saveDir)

try

    % Define paths
    if nargin == 0
        sourceDir = 'E:\Multi Channel DataManager';
        saveDir   = 'E:\Data\Wireless Data';
        options   = struct('draw',true,'extractSpikes',true,...
                            'plotWaveforms',true,'save',false);
    end

    % Select file
    [filename, pathname, ~] = uigetfile([sourceDir filesep '*.h5']);
    filePath = fullfile( pathname, filename);
    
    % Get metadata
    info    = h5info(filePath);
    recDate = info.Groups.Attributes(6).Value;        
    % Datasets = (1) ChannelData, (2) ChannelDataTimeStamps, (3) InfoChannel
   
    
    % Extract time info
%     stamps0 = h5read(filePath, '/Data/Recording_0/AnalogStream/Stream_0/ChannelDataTimeStamps');
%     stamps1 = h5read(filePath, '/Data/Recording_0/AnalogStream/Stream_1/ChannelDataTimeStamps');
    
    % Extract digital waveforms
%     stream0 = h5read(filePath, '/Data/Recording_0/AnalogStream/Stream_0/ChannelData');
    stream1 = h5read(filePath, '/Data/Recording_0/AnalogStream/Stream_1/ChannelData');
    
    % Format
    stream1 = single(stream1);
    stream1 = transpose(stream1);
    
    % Save
    if options.save
        savePath = fullfile( saveDir, strrep(filename,'.h5','.mat'));
        save(savePath, '-struct', 'X','-v7.3')   
    end
    
    % Get spikes
    if options.extractSpikes
        
        [wv, t] = deal(cell(16,1));
        
        for chan  = 1 : 16           
            [wv{chan}, t{chan}] = getWaveforms(stream1(chan,:));
        end        
    end
    
    % Draw waveforms 
    if options.plotWaveforms              
        waveformPatch_cell(wv,2000,0.2)        
    end
    
    
    % Draw voltage traces
    if options.draw
        timeWindow  = 0.15;
        startWindow = 10.1;
        fRec        = 20e3;
        samps = fRec .* [startWindow startWindow+timeWindow];    

        figure('color','w')

        for chan = 1 : 16

            subplot(4,4,chan)
            plot(stream1( samps(1):samps(2), chan),'color',[0.2 0.2 0.2])
            axis tight
            ylim([-1 1].*250)
        end
        
        xlabel('Sample'); ylabel('mV')
    end

catch err
    err
    keyboard
end


function [wv, ev_t] = getWaveforms(trace)

% Settings
fRec         = 20000;
wInt         = 1;
interpFactor = 4;

interpInt  = wInt / interpFactor; 
window     = -15 : wInt : 16;
interpWind = -15 : interpInt  : 16;
nW         = numel(window)+1;               % These are regardless of method (interpolated or not)

alignmentZero = find(window == 0);

% Identify threshold crossings
threshold = std(trace);

lb = min([-20  -2 * threshold]);
ub = min([-500 -6 * threshold]);

% Identify thrshold crossings
lcIdx = find(trace < lb);
ucIdx = find(trace < ub);

% Remove events exceeding the upper threshold                    
lcIdx = setdiff(lcIdx,ucIdx);                                   %#ok<*FNDSB>

% Move to next trial if no events were found
if isempty(lcIdx); return; end

% Identify crossing points in samples
crossThreshold = lcIdx([0 diff(lcIdx)]~=1);

% Remove events where window cannot fit
crossThreshold(crossThreshold < nW) = [];
crossThreshold(crossThreshold > (length(trace)-nW)) = [];

% Make row vector
if iscolumn(crossThreshold),
    crossThreshold = crossThreshold';
end

% Get interim waveforms
wvIdx = bsxfun(@plus, crossThreshold', window);
wv    = trace(wvIdx);

% Move to next trial if no waveforms are valid
if isempty(wv); return; end

% Interpolate waveforms
wv = spline(window, wv, interpWind);

% Align events
[~, peakIdx]     = min(wv,[],2); 
peakIdx          = round(peakIdx / interpFactor);     % Return interpolated peakIdx to original sample rate
alignmentShift   = peakIdx' - alignmentZero;
alignedCrossings = crossThreshold + alignmentShift;

% Reset events where window cannot fit (i.e. don't
% throw away, just include without alignment)
alignedCrossings(alignedCrossings < nW) = crossThreshold(alignedCrossings < nW);                     
alignedCrossings(alignedCrossings > (length(trace)-nW)) = crossThreshold(alignedCrossings > (length(trace)-nW));

% Make row vector
if iscolumn(alignedCrossings),
    alignedCrossings = alignedCrossings';
end

% Get event times and waveforms
ev_t  = crossThreshold ./ fRec;   % Keep event times as the actual threshold crossing
wvIdx = bsxfun(@plus, alignedCrossings', window); % But sample aligned waveforms
wv    = trace(wvIdx);

% Interpolate waveforms
wv = spline(window, wv, interpWind);

% Remove waveforms with any point over upper bound
ev_t( any( wv<ub, 2))  = [];
wv( any( wv<ub, 2), :)  = [];
ev_t( any( wv>-ub, 2)) = [];
wv( any( wv>-ub, 2), :) = [];                                        


