function [pulse_times, channel_order] = unique_isi_sequence_CF(C)
%UNIQUE_ISI_SEQUENCE creates a sequence of click times across channels
%   This function creates a pseudo random sequence of pulses distributed
%   equally across 'n_channels' loudspeakers. The rules governing the
%   sequence generation involve specifying a minimum and maximum ISI. The
%   resulting pulse sequence contain no repeats of any given ISI. 
%

%
%   Example:
%   [pulse_times, channel_order, wav_sequence] = random_pulse_generator(10,.001,.1,8);
%
%   pulse_times is a vector with the time of each pulse (in seconds)
%   channel_order is a vector with channel numbers for each pulse.
%
%   The resulting sequence has temporally pseudorandomly spaced pulses
%   with the requirement that each channel have an identical number of
%   pulses. 
%
% Author: Owen Brimijoin
% Date: 07/10/13
% 
% Modification: 06 December 2013 (Stephen Town)
% - wav file generation removed 
% - sample rate moved to become input arguement 
% - pulse times switched to samples 
%
% Modification; 14th March 2019
% - vectorization to accelerate use in behavioral tasks
% - several variables have been defined earlier in the code so that this
% function can be called many times without duplicating unnecessary
% commands


%shuffle delays and sum to create vector of pulse times:
pulse_times = cumsum( C.pulse_vector( randperm( C.nPulse)));

%crop the vector to duration:
pulse_times = pulse_times( pulse_times <= C.n_samples);
nPulses = length(pulse_times);

%present warning if range of specified delays won't result in unique ISIs:
if length(unique(diff(floor(pulse_times)))) < nPulses-1,
    error([ 'ISIs cannot be unique at the specified sample rate. ',...
            'Increase sample rate or the range of min to max allowed delays.'])    
end

% Determine remainder to ensure equal num of pulses in each channel:
remainder = rem( nPulses, C.n_speakers);

% Remove these extra pulses:
pulse_times(end-remainder+1:end) = [];

% Generate a randomizer across channels
channel_order = repmat( C.speaker_vec, length(pulse_times) / C.n_speakers, 1);

