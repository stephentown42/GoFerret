function level15_SpeakerCheck


global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles* 

try

% If this isn't a correction trial                
if gf.correctionTrial == 0

    % Obtain trial parameters                                
    [gf.hold, gf.holdTime] = getHoldTime(gf.hold);                       
    [gf.stim, gf.stimGrid] = getStimGrid_CoordinateFrames(gf.stim);
end
                
% Time to Sample conversion
gf.holdSamples = ceil(gf.holdTime * gf.fStim);        
gf.reqSamps = gf.holdSamples - ceil(gf.absentTime*gf.fStim);    % Samples required to initiate
gf.isiSamps = ceil(gf.isi*gf.fStim);
gf.stimSamps = ceil(gf.duration*gf.fStim);

playDelay = gf.holdSamples - gf.stimSamps - gf.isiSamps;
playDuration = gf.nStimRepeats*(gf.isiSamps+gf.stimSamps);

gf.modality = 2;    % 0 = LED, 1 = Speaker, 2 = Both 


% For each speaker
for i = 2

    % Convert stimulus positions to multiplex (mux) values
    gf.SPKmux = getMUXfamily(i);
                
    % Force levels to be stim intensity
    gf.trial_Spkr_stim_dB = gf.Spkr_stim_dB;

    % Apply calibration to auditory stimuli
    gf.trial_Spkr_stim_V = getJumboCalib(gf.trial_Spkr_stim_dB, i);
    gf.Spkr_bgnd_V       = getJumboCalib(gf.Spkr_bgnd_dB, i);

    % Set parameters TDT
    DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
    DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice), gf.holdSamples);             
    DA.SetTargetVal( sprintf('%s.absentSamps', gf.stimDevice), round(0.1*gf.fStim)); % 29/8/16  
    DA.SetTargetVal( sprintf('%s.refractorySamps', gf.stimDevice), gf.holdSamples); % 26/4/18  
    DA.SetTargetVal( sprintf('%s.reqSamps', gf.stimDevice),    gf.reqSamps);               
    DA.SetTargetVal( sprintf('%s.nStim', gf.stimDevice),       gf.nStimRepeats);                   
    DA.SetTargetVal( sprintf('%s.stimSamps', gf.stimDevice),   gf.stimSamps);  
    DA.SetTargetVal( sprintf('%s.stim&intSamps', gf.stimDevice),gf.isiSamps+gf.stimSamps);
    DA.SetTargetVal( sprintf('%s.playDelay', gf.stimDevice),    playDelay);
    DA.SetTargetVal( sprintf('%s.playDuration', gf.stimDevice), playDuration);
    DA.SetTargetVal( sprintf('%s.Spkr_stim_V', gf.stimDevice), gf.trial_Spkr_stim_V	); 
    DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V);
    DA.SetTargetVal( sprintf('%s.modality',    gf.stimDevice), gf.modality);
    DA.SetTargetVal( sprintf('%s.Spkr-mux-01', gf.stimDevice), gf.SPKmux(1));
    DA.SetTargetVal( sprintf('%s.Spkr-mux-10', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
    DA.SetTargetVal( sprintf('%s.Spkr-mux-11', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
    DA.SetTargetVal( sprintf('%s.Spkr-mux-12', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
        
        
    % Update online GUI              
    DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 1);                
    DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 0);
    fprintf('Playing Speaker %02d\n', i)

    pause( gf.nStimRepeats * gf.duration * 1.2)
        
%     DA.SetTargetVal( sprintf('%s.errorPulse', gf.recDevice), 1);
%     DA.SetTargetVal( sprintf('%s.errorPulse', gf.recDevice), 0);
    
    pause(0.5)
end

catch err
    
    % If because of closure of webcam
    if strcmp(err.message,'Instrument object OBJ is an invalid object.')
        fprintf('The following is a shutdown error - nothing to worry about\n')    
        
    % If because gf was cleared
    elseif strcmp(err.message,'Reference to a cleared variable gf.')
        fprintf('The following is a shutdown error - nothing to worry about\n')    
    else
        err
        keyboard
    end
end

function y = getMUXfamily(x)

x = ['0' dec2base(x-1, 4)];   % Convert to quarternery numeral for mux input
x = ['0',x];                  % Add zero to cope with case where x < 0 and function returns shorter output
y = [str2num(x(end-1)), str2num(x(end))];    % Reformat from char to double
       


    

    
    


