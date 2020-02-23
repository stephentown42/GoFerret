function stim_v = getJumboCalib_FRA(freq, dB_val, speaker)
% stim_v = getJumboCalib_FRA(freq, dB_val, speaker)
%
% Stephen Town: 7th December 2019


% Check that this frequency has been calibrated
calib_freq = 150 * 2 .^ (0 : 1/3 : log(2e4 / 150) / log(2));
calib_idx = round(calib_freq) == round(freq);

if ~any(calib_idx)
    error('Frequency not calibrated')
end
  
% Microphone calibration
m94_dBSPL = 99.5; % value on B&K
SPL_correction = m94_dBSPL - 94;

calibration_v = 0.5; % 7th Dec 2019
% calibration_SPL = 60; 

% Speaker specific calibration
switch speaker
    
    case 2
        
        bnk_val = [37.8     41.5    44.5,...
                   44.0     47.5    49.9,...
                   52.5     56.4    63.5,...
                   67.7     67.0    71.1,...
                   73.7     61.6    63.1,...
                   68.6     72.9    66.9,...
                   57.1     56.3    72.5    72.1];                            
        
    otherwise
        error('Speaker not calibrated')
        
end

% Calculate corrected signal voltage
bnk_val = bnk_val( calib_idx);
spl_val = bnk_val - SPL_correction;
required_correction = spl_val - dB_val;
required_correction = 10 .^(-(required_correction/20));
stim_v = calibration_v * required_correction;      

if stim_v > 12
    warning('Stimulus exceeds 5V')
%     keyboard
end
        
