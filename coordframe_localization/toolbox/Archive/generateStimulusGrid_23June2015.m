function stimGrid = generateStimulusGrid(varargin)

% Default arguments
if nargin == 0
    nCycles = 50;   % Number of cycles
    nStim   = [5 5 15];   % Number of stimuli within cycle
    seed    = round(rand(1));
    template = [seed 2    1-seed 2;
                seed seed 1-seed 1-seed];

    stimLabels = [10 11 12 1 2];
end

template = repmat(template, 1, ceil(nCycles/size(template,2)));
stimGrid = nan(1,4);
k = 0;

% For each cycle
for i = 1 : nCycles
     
    n = nStim(template(1,i)+1);
    
    % For each stimulus, randomly select stimulus positions
    for j = 1 : n,        
        
        k = k + 1;
        stimPositions = randperm(5,2);
        
        stimGrid(k,1) = template(1,i);      % Modality
        stimGrid(k,2) = template(2,i);      % Dominant Modality
        stimGrid(k,3) = stimLabels(stimPositions(1));    
        stimGrid(k,4) = stimLabels(stimPositions(2));        
    end
end

stimGrid(1,:) = [];