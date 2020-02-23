function stim = initialize_FRA(freq, dB_SPL, stim_order)
% function stim = initialize_FRA(freq, attn, stim_order)
%
% Initializes grid of stimuli to present
%
% INPUTS
% freq: parameter values with min, max and octave intervals
% attn: parameter values with min, max and interval
% stim_order: whether to proceed randomly ('rand') or with 'directed' search* 
%
% * directed search assumes that neural responses to sounds will decrease
% with sound attenuation and therefore prioritizes presenting louder tones
% first and then work through progressively quieter tones that are less
% likely to ellicit neural responses.
%
% OUTPUTS
% stim: table of frequencies and tones to present
%
% Stephen Town: 7th Dec 2019


% Create table of all combinations of frequency and attenuation
freq.vals = freq.min * 2 .^ (0 : freq.oct_int : log(freq.max / freq.min) / log(2));
dB_SPL.vals = dB_SPL.min : dB_SPL.int : dB_SPL.max;

[freqs.mesh, dBs.mesh] = meshgrid( freq.vals, dB_SPL.vals);

stim = table( freqs.mesh(:), dBs.mesh(:), 'VariableNames', {'Freq','dB_SPL'});

% Randomize in either completely random or directed approach
make_random = @(x) x( randperm(size(x, 1)), :);

switch stim_order
    
    case 'rand'  
        stim = make_random( stim);
        
    case 'directed'
        
        % In more recent versions of matlab, could use in-built split_apply
        % but here we're just going to use a for loop for R2013        
        for i = 1 : numel( dB_SPL.vals)
           
            rows = find( stim.dB_SPL == dB_SPL.vals(i));
            stim(rows,:) = make_random(stim(rows,:));            
        end        
        
        stim = sortrows( stim, 'dB_SPL', 'descend');
end

% Append zeros for counting trial number later
stim.nTrials = zeros(size(stim, 1), 1);
