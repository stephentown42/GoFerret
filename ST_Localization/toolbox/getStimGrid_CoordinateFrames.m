function [S, currentGrid] = getStimGrid_CoordinateFrames(S)
%
% S is structure containing stimulus parameters such as speaker position
% and LED position
%
% The first time this function is called, it will add a matrix with each row
% indicating a set of stimulus conditions 

% If a grid has been calculated
if isfield(S,'grid')
    
    % Move to the next trial in the list (index)
    S.Idx = S.Idx + 1;    
    
    % If the next trial exceeds the number of arranged trials in this set,
    % generate the list again
    if S.Idx > S.N
        S = initializeGrid(S);
    end

% If running the function for the first time
else
    S = initializeGrid(S);
end

% Return values for current trial
currentGrid = S.grid(S.Idx,:);



function S = initializeGrid(S)
%
% main function

% Specify the number of combinations of task parameters to repeat
nIterations = 10;

% Randomly index speaker location
nSpeakers = numel(S.SpeakerPositions);
idx = nan( nIterations, nSpeakers);

for i = 1 : nIterations    
   idx(i,:) = randperm(nSpeakers);
end

idx = idx(:); % Convert to column vector

% Create a two column vector of speaker and associated LED positions
S.token = [S.SpeakerPositions' S.LEDpositions'];

% Apply the random index
S.token = S.token(idx,:);

% Get sample size
S.N = size(S.token,1);

% Add filler
S.modality = repmat(2, S.N, 1);
S.domMod   = zeros(size(S.modality)); % Force visual location (LED will be turned down to nothing in testing) 
S.targetSpout = S.token(:,2);         % Force visual 

% Tidy up
S.grid = [S.modality S.domMod S.token S.targetSpout];
S.Idx  = 1;




