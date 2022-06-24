function stimGrid = generateStimulusGrid_Level6_flipped(varargin)

% Default arguments
switch nargin 
    case 0
        seed = round(rand(1));
        dMod = seed;
    case 1
        seed = varargin{1};
        dMod = seed;
    case 2
        seed = varargin{1}; % Modality
        dMod = varargin{2};
end

% Assign modality and dominant modality
stimGrid(1) = seed;
stimGrid(2) = dMod;
stimGrid(3) = 2;   % LED
stimGrid(4) = 10;    % Sound



