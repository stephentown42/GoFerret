function adapt_training_parameters

global gf

% Define step size
stepSize.holdTime = 0.01; % seconds
stepSize.LED_stim = 0.2; % V
stepSize.spkr_dB  = 3;
stepSize.valveTime = 0.01;

% Define parameter limits
pLimits.holdTime.max = 3.001; % seconds
pLimits.holdTime.min = 0.501; % seconds
pLimits.LED_stim.max = 4.5;     % V
pLimits.LED_stim.min = 0;       % V
pLimits.spkr_dB.max  = 40;     % V
pLimits.spkr_dB.min  = 0;       % V
pLimits.valveTime.min = 0; % seconds
pLimits.valveTime.max = 0.4; % seconds

% Define direction of adaptation / descent
adaptDir.holdTime =  +1; % Increasing
adaptDir.LED_stim =  -1; % Decreasing
adaptDir.spkr_dB  =  +1; % Increasing



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get recent performance history
get_recent_performance(gf.subjectDir)
% Filter for non-correction trials


% Get bias
getBias

% Update valve times