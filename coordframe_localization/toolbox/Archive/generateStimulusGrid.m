function stimGrid = generateStimulusGrid(varargin)

% Default arguments
switch nargin 
    case 0
        seed = round(rand(1));
        dMod = seed;
    case 1
        seed = varargin{1};
        dMod = seed;
    case 2
        seed = varargin{1};
        dMod = varargin{2};
end

% Number of stimuli
nStim = [5 5 150]; 
nStim = nStim(seed+1);

% Stimulus positions
stimLabels = [10 11 12 1 2];

% Assign modality and dominant modality
stimGrid = nan(nStim,4);
stimGrid(:,1) = ones(nStim,1) .* seed;
stimGrid(:,2) = ones(nStim,1) .* dMod;

% For each stimulus, randomly select stimulus positions
for k = 1 : nStim,        
    
    stimPositions = randperm(5,2);
    stimGrid(k,3) = stimLabels(stimPositions(1));    
    stimGrid(k,4) = stimLabels(stimPositions(2));        
end

