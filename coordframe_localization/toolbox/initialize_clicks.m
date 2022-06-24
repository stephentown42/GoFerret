function C = initialize_clicks( C, fS)
%
% Initializes static variables for click sequence generation during
% behavioral testing. Saves time by not recalculating numbers we only need
% to compute once
%
%
% fS - Sample rate of stimulus device
%
% Written on 14th March 2019 by Stephen Town
        
% Get range of signal attenuations
C.attn_range = C.min_attn : C.attn_interval : C.max_attn;
C.n_attn = numel(C.attn_range);
       
% Convert timing variables into samples
C.n_samples = floor( C.duration * fS); 
C.min_delay = ceil(C.min_delay * fS); 
C.max_delay = ceil(C.max_delay * fS); 

% Create pulse time vector (from which we will draw samples later)
mean_delay = mean([C.min_delay, C.max_delay]);
C.nPulse = floor( C.n_samples / mean_delay);
C.pulse_vector = transpose( linspace( C.min_delay, C.max_delay, C.nPulse));

% Speaker vector
C.speaker_vec = transpose( 1 : C.n_speakers);
                