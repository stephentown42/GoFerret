function clicks = generate_click_library( clicks)

% Code taken from Level3_WE in OB_Spatial on Jumbo and modified on 14th
% March 2019 by ST
%
% clicks - structure containing metadata for click generation
    

[intervals, chans, attns] = deal( cell(clicks.n_attn, 1));

% Adjustment table (spkr, attn)
my_correction = [  1 -4;      % 7 o clock (c2)- 61
    2 -5.5;    % 9 o clock (c4)- 59.5
    3 -5.5;    % 8 o clock (c3)- 59.25
    4 -6;      % 10 o clock (c5) - 59
    5 -5.5;    % 11 o clock (c6)- 59.25
    6 -4;      % 6 o clock - 61
    7 -5.5;    % 1 o click (c12)- 59.75
    8 -5;      % 2 o clock (c9)- 60
    9 -5;      % 3 o clock (c10)- 60
    10 -6;     % 4 o clock (c11) - 59
    11 -5.5;   % 5 o clock (c8) - 59.5
    12 -5];    % 59.5 - 12 oclock

% For each attenuation
for i = 1 : clicks.n_attn,

    % Generate stimulus list
    [samps, chans{i}] = unique_isi_sequence_CF( clicks);
    
    % Convert click times to intervals between clicks
    intervals_i = diff(samps) ;
    intervals{i} = [intervals_i; intervals_i(1)];
    
    % Log uncorrected attenuation value (this can't be done a priori
    % because we don't know exactly how many clicks will be selected)
    attns{i} = repmat( clicks.attn_range(i), size(chans{i})); % Unadjusted (UA)    
end

% Convert cell arrays to arrays of values 
attns = cell2mat(attns);
chans = cell2mat(chans);
intervals = cell2mat(intervals);

% Make fine adjustments for levels
for speaker = 1 : clicks.n_speakers,

    % Get indices 
    rows = chans == speaker;
    
    % Make adjustment
    attns(rows) = attns(rows) + my_correction(speaker, 2);
end

% Randomize once again
clicks.tbl = table( chans, attns, intervals);
clicks.tbl = clicks.tbl( randperm( length(chans)), :);

% Convert Attn to voltage level
clicks.tbl.Vs = clicks.pulse_v .* 10.^-(clicks.tbl.attns ./ 20);

% Mute first click
clicks.tbl.Vs(1) = 0;