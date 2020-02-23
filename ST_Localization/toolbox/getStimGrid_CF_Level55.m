function [S, currentGrid] = getStimGrid_CF_Level55(S, theta)
%
% S is structure containing stimulus parameters such as speaker position
% and LED position
%
% Theta is the angle of the central platform in degrees
%
% The first time this function is called, it will add a matrix with each row
% indicating a set of stimulus conditions 
%
% Modified from getStimGrid_CoordinateFrames.m on 20 Feb 2019 by ST to
% introduce speaker position calculation from theta
%
% Modified on 15 June 2019 by ST to take account of rotation of response
% coordinate frame
try


% If a grid has been calculated
if isfield(S,'grid')
    
    % Move to the next trial in the list (index)
    S.Idx = S.Idx + 1;    
    
    % If the next trial exceeds the number of arranged trials in this set,
    % generate the list again
    if S.Idx > S.N
        S = initializeGrid(S, theta);
    end

% If running the function for the first time
else
    S = initializeGrid(S, theta);
    
    % Get list of probe sounds
    all_locations = 1:12;
    S.probe_positions = setdiff(all_locations, S.SpeakerPositions);
    
    if isfield(S,'probe_exclude')
        if ~isempty(S.probe_exclude)
            S.probe_positions = setdiff(all_locations, S.probe_exclude);
        end
    end
end

% Return values for current trial
currentGrid = S.grid(S.Idx,:);

catch err
    err
    keyboard
end


function S = initializeGrid(S, theta)
%
% main function

% Compute the speaker locations for this value of theta
speakers = 1:12;    % Ticks of the clock
speaker_angles = 180 - (speakers .* 30);    % Angles of the box    
speaker_platform_angles = speaker_angles - theta;   % Adjust for center platform value

fu_idx = speaker_platform_angles <= -180;
speaker_platform_angles(fu_idx) = speaker_platform_angles(fu_idx) + 360;

fu_idx = speaker_platform_angles > 180;
speaker_platform_angles(fu_idx) = speaker_platform_angles(fu_idx) - 360;

speaker_2_respond_L = speakers( speaker_platform_angles == S.angle(1));
speaker_2_respond_R = speakers( speaker_platform_angles == S.angle(2));

S.SpeakerPositions = [speaker_2_respond_L, speaker_2_respond_R]; 
S.targetSpout = [9, 3];
% Note, this assumes the order of contingency in the parameters table,
% which should be constant across animals. It could be an error source if
% not maintained.
    
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
S.token = [S.SpeakerPositions' S.targetSpout'];

% Apply the random index
S.token = S.token(idx,:);

% Get sample size
S.N = size(S.token,1);

% Add filler
S.modality = repmat(2, S.N, 1);
S.domMod   = zeros(size(S.modality)); % Force visual location (LED will be turned down to nothing in testing) 
S.targetSpout = S.token(:,2);         

% Tidy up
S.grid = [S.modality S.domMod S.token S.targetSpout];
S.Idx  = 1;





