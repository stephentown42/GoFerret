function updatePerformance(valveID)

global gf h

% Exit for correction trials
if gf.correctionTrial == 1
    return
end

% Exit for probe trials
if isfield(gf,'probe_trial')
    if gf.probe_trial
        return
    end
end

% Get the right graph
graphRow = 1 + (gf.modality == 2);
graphCol = 1 + gf.domMod;

if gf.domMod == 2, graphCol = 1; end

graphInd = sub2ind([2 2], graphCol, graphRow);

% Create single trial mask
cellInd = sub2ind([12 12], valveID, gf.targetSpout);    % Find the right cell
newPerformance      = zeros(12);                                    % Create mask
newPerformance(cellInd) = 1;

% Get image handle and update CData
imH = h.im(graphInd);
pastPerformance = get(imH,'CData');  % Current performance
newPerformance  = newPerformance + pastPerformance; % Add mask

set(imH,'CData',newPerformance);

% Report % correct in title
nCorrect = sum(newPerformance(eye(12) == 1));
nTrials = sum(newPerformance(:));
pCorrect = nCorrect / nTrials;

title(h.performanceA, sprintf('%.1f%% Correct (%d / %d trials)', pCorrect* 100, nCorrect, nTrials))

% Update performance line
x_new = [get(h.perf_track, 'xdata') nTrials];
y_new = [get(h.perf_track, 'ydata') pCorrect];

set(h.perf_track, 'xdata', x_new, 'ydata', y_new)


% Update bias
pStimResp = newPerformance ./ nTrials;
pStimResp(eye(12)==1) = 0;
pStimResp = pStimResp(:);
pStimResp(pStimResp == 0) = [];

if numel(pStimResp) == 2
    % pBias = pBias( pBias ~= 0);
    pBias = abs(diff(pStimResp));


    x_new = [get(h.bias_h, 'xdata') nTrials];
    y_new = [get(h.bias_h, 'ydata') pBias];

    set(h.bias_h, 'xdata', x_new, 'ydata', y_new)
end
