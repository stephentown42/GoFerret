function [Left_attn, Right_attn] = getCalibAtten(targetLevel, overRideFormants)

% Designed to work as part of GoFerret
% Values for 02 August 2014

global gf

try
   
% Overide default arguements from GoFerret
if exist('overRideFormants','var')
    formants = overRideFormants;
else
    formants = gf.formants;
end
    
% Allow ferret specific target levels
if isfield(gf,'targetLevel'),
    targetLevel = gf.targetLevel;
end

% Default if not specified
if ~exist('targetLevel','var') 
    targetLevel = 63.5;         
end

calib.target= targetLevel;

calib.f0    = [149 200 263 330 459 NaN];

calib.id    = [460 1105; 
               730 2058; 
               437 2761; 
               936 1551;
               460 2058;
               730 1105;
               437 1551;
               936 2761;
               460  0;
               730  0;
               0 1105;
               0 2058;               
               437  0;
               936  0;
               0 1551;
               0 2761];
           
calib.right = [63.1 62.5 60.6 63.2 61.1 44.0;
               64.2 69.6 65.0 63.3 66.9 55.0;
               68.9 68.0 69.1 71.1 67.5 53.5;
               65.3 64.0 62.7 64.1 66.1 61.5;
               NaN  63.6  NaN  NaN  NaN  NaN ;
               NaN  66.2  NaN  NaN  NaN  NaN ;
               NaN  63.3  NaN  NaN  NaN  NaN ;
               NaN  71.5  NaN  NaN  NaN  NaN ;
               NaN  62.7  NaN  NaN  NaN  NaN ;
               NaN  66.5  NaN  NaN  NaN  NaN ;
               NaN  65.5  NaN  NaN  NaN  NaN ;
               NaN  60.9  NaN  NaN  NaN  NaN;
               NaN  62.9  NaN  NaN  NaN  NaN ;
               NaN  65.6  NaN  NaN  NaN  NaN ;
               NaN  64.6  NaN  NaN  NaN  NaN ;
               NaN  71.6  NaN  NaN  NaN  NaN ];
           
calib.left = [66.1 65.7 63.5 65.4 65.6 55.6;
              66.6 67.5 67.1 65.6 69.1 61.0;
              73.5 74.0 74.6 73.5 74.1 67.9;
              65.1 64.8 63.1 65.5 67.0 62.0;
              NaN  67.4  NaN  NaN  NaN  NaN ;
              NaN  68.0  NaN  NaN  NaN  NaN ;
              NaN  66.0  NaN  NaN  NaN  NaN ;
              NaN  76.2  NaN  NaN  NaN  NaN ;
              NaN  65.7  NaN  NaN  NaN  NaN ;
              NaN  69.1  NaN  NaN  NaN  NaN;
              NaN  64.0  NaN  NaN  NaN  NaN ;
              NaN  59.8  NaN  NaN  NaN  NaN ;
              NaN  65.9  NaN  NaN  NaN  NaN ;
              NaN  65.5  NaN  NaN  NaN  NaN ;
              NaN  60.5  NaN  NaN  NaN  NaN ;
              NaN  73.0  NaN  NaN  NaN  NaN ];
           
          

% Cross reference table          
if isnan(gf.pitch)
    calib.attn0 = calib.left( ismember(calib.id, formants(1:2),'rows'), end);
    calib.attn1 = calib.right( ismember(calib.id, formants(1:2),'rows'), end);
else
    calib.attn0 = calib.left( ismember(calib.id, formants(1:2),'rows'), calib.f0 == gf.pitch);
    calib.attn1 = calib.right( ismember(calib.id, formants(1:2),'rows'), calib.f0 == gf.pitch);
end

% If not yet calibrated 
if isnan(calib.attn1),    calib.attn1 = calib.target; end
if isnan(calib.attn0),    calib.attn0 = calib.target; end

% Calculate compensation required for target level
Left_attn  = calib.attn0 - calib.target;
Right_attn = calib.attn1 - calib.target;


% Safety check
if Left_attn < -20 || Right_attn < -20,
   
    choice = questdlg('Warning - determined calibration levels will amplify sound by > 20 dB - please confirm',...
                        'Amplification warning');
    
    if strcmp(choice,'No')
        keyboard
    end
    
end

catch
    Left_attn = 0;
    Right_attn = 0;
    fprintf('no calibration value found for f0 = %d, formants = %d %d %d %d\n', gf.pitch, gf.formants) 
end