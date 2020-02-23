function [S, currentGrid] = getStimGrid_allowColocation(S)

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

% We want AV, V and A (but the user only has the choice of how many
% multi/unisensory trials
S.nLoci  = numel(S.SpeakerPositions);

S.modality = [zeros(S.nLoci, 1);      % Visual
              ones(S.nLoci, 1);       % Auditory
              zeros(S.nLoci, 1)+2];   % AV
          
% Makes Auditory dominant modality for AV (no problem since they're
% co-located)
S.domMod = S.modality > 0;           

% Define target location as stimulus location (the visual and auditory
% ranges should be matched - an error will result at L25 if not)
S.targetSpout = [S.LEDpositions(:); 
                 S.SpeakerPositions(:); 
                 S.SpeakerPositions(:)]; 

% Randomize
S.grid = [S.modality S.domMod S.targetSpout];
S.N    = numel(S.modality);
idx    = randperm(S.N);
S.grid = S.grid(idx,:);

% Initial and finish
S.Idx  = 1;

% Draw for validation    
% drawValidationData(S); % This works but is commented out for ease when runnning GoFerret



