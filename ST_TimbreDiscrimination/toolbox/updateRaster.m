function updateRaster

global rstr DA h

try

% Update parameters based on start times
if isempty(rstr.startTimes), return; end

rstr.trialIdx = length(rstr.startTimes);
rstr.nTrials  = max([ rstr.nTrials rstr.trialIdx]);

% Get current event index    
for chan = 1 : 32

    hotSpike = DA.GetTargetVal( sprintf('RZ2.sev%02d', chan));
    
    if hotSpike > rstr.sev(chan),
    
        nWords   = hotSpike - rstr.sev(chan);        
        newTimes = DA.ReadTargetVEX( sprintf('RZ2.tev%02d', chan),...  
                                     rstr.sev(chan),... 
                                     nWords,...
                                     'F32','F32');                                 
                                 
        newTimes = newTimes ./ 24414.0625;                
        
        oldTimes = rstr.tev{chan};
        
        rstr.tev{chan} = [oldTimes newTimes];        
        rstr.sev(chan) = hotSpike;
    end                       
end


% Calculate raster
chan = get(h.rasterChan,'value');

taso   = bsxfun(@minus, rstr.tev{chan}', rstr.startTimes - 0.5);        
n      = histc(taso, rstr.edges);
n(n>0) = 1;

if size(n,1) < size(n,2),
    n = n';
end


% Pad image with zeros for trials to come
toGo    = rstr.nTrials - rstr.trialIdx;

if toGo
    padding = zeros( length(rstr.edges), toGo);

    n = [n padding];
end

% Update CData
set(rstr.im,'CData',n')
set(h.rasterAxes,'ylim',[0.5 rstr.nTrial])


catch err
    
    sprintf('Update raster failed\n')   
end