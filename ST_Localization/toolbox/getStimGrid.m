function [S, currentGrid] = getStimGrid(S)

if isfield(S,'grid')
    
    S.Idx = S.Idx + 1;    
    
    if S.Idx > S.N
        S = initializeGrid(S);
    end
else
    S = initializeGrid(S);
end

currentGrid = S.grid(S.Idx,:);



function S = initializeGrid(S)

% Alternate dominant modality
S.period    = S.multisensoryTrials + S.unisensoryTrials;
seedValue   = round(rand(1));   % LED = 0; Speaker = 1;
nIterations = 1;
partA       = repmat(seedValue, S.period, 1);
partB       = 1 - partA;
S.domMod    = repmat([partA; partB], nIterations, 1);

% Label audiovisual trials
if S.multisensoryTrials > 0
    partA(S.unisensoryTrials+1:end) = 2;    
    partB(S.unisensoryTrials+1:end) = 2;
end

% Stimulus modality
S.modality = repmat([partA; partB], nIterations, 1);
S.N        = numel(S.modality);


% Get possible combinations of speakers and LEDs
[S.Speakers, S.LEDs]     = deal([]);
[marginal.A, marginal.V] = deal(false(1,12));   % Define marginals of position grid

marginal.A(S.SpeakerPositions) = true;
marginal.V(S.LEDpositions)     = true;

S.positionGrid             = bsxfun(@times, marginal.A, marginal.V');
S.positionGrid(eye(12)==1) = false; % Disallow co-located trials
[LEDs, speakers]           = find(S.positionGrid);

LEDs     = repmat(LEDs, 3, 1);          % Allow variation within three repeats of the possible stimuli
speakers = repmat(speakers, 3, 1);
repSize  = numel(LEDs);

for i = 1 : floor(S.N / repSize)        % Randomize order within each repeat
    
    idx = randperm( repSize);
    S.LEDs     = [S.LEDs; LEDs( idx)];
    S.Speakers = [S.Speakers; speakers( idx)];
end

topUp = mod(S.N, repSize);  % Make vector lengths consisten across structure

idx = randperm(repSize, topUp);
S.LEDs     = [S.LEDs; LEDs(idx)];
S.Speakers = [S.Speakers; speakers(idx)];

% Assign target spout
S.targetSpout  = nan(size(S.domMod)); % Filter by dominant modality
S.targetSpout(S.domMod == 0) = S.LEDs(S.domMod == 0);   % LED trials
S.targetSpout(S.domMod == 1) = S.Speakers(S.domMod == 1);   % LED trials

% Tidy up
S.grid = [S.modality S.domMod S.LEDs S.Speakers S.targetSpout];
S.Idx  = 1;

% Draw for validation    
% drawValidationData(S); % This works but is commented out for ease when runnning GoFerret



