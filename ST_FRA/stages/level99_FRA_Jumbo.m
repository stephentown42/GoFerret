function level99_FRA_Jumbo
%
% Plays a sequence of tones from a 
%
% Stephen Town
%   - 2019: First developed
%   - 2020 May 30: Added stim init checks


global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles* 


try

    % Timing
    gf.sessionTime = (now - gf.startTime)*(24*60*60);
    set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));   
%     updateTimeline(20);

    switch gf.status

        case('PrepareStim')%none to prepare

            % Get trial parameters
            if gf.stim_index > size(gf.stim, 1)       
                gf.stim = initialize_FRA(gf.freq, gf.dB_SPL, 'directed');
                gf.stim_index = 1;
            end                   
                        
            gf.current_freq = gf.stim.Freq(gf.stim_index);            
            gf.current_dB = gf.stim.dB_SPL(gf.stim_index);
            gf.stim_v = getJumboCalib_FRA(gf.current_freq, gf.current_dB, gf.Speaker);            
            
            DA.SetTargetVal(sprintf('%s.freq',    gf.stimDevice), gf.current_freq);            
            DA.SetTargetVal(sprintf('%s.dB_SPL',    gf.stimDevice), gf.current_dB);
            DA.SetTargetVal( sprintf('%s.stim_v', gf.stimDevice), gf.stim_v	);
            
            gf.stim.nTrials(gf.stim_index) = gf.stim.nTrials(gf.stim_index) + 1;  
            gf.stim_index = gf.stim_index + 1;           
            
            gf.wait_period = gf.duration + gf.isi.min + (gf.isi.range * rand(1));
            
            % Convert stimulus positions to multiplex (mux) values
            gf.SPKmux = getMUXfamily( gf.Speaker);
            DA.SetTargetVal( sprintf('%s.Spkr-mux-01', gf.stimDevice), gf.SPKmux(1));
            DA.SetTargetVal( sprintf('%s.Spkr-mux-10', gf.stimDevice), gf.SPKmux(2)); 
            DA.SetTargetVal( sprintf('%s.Spkr-mux-11', gf.stimDevice), gf.SPKmux(2)); 
            DA.SetTargetVal( sprintf('%s.Spkr-mux-12', gf.stimDevice), gf.SPKmux(2)); 
            
            % Time to Sample conversion 
            gf.stimSamps = ceil(gf.duration*gf.fStim);           
            DA.SetTargetVal( sprintf('%s.stimSamps', gf.stimDevice), gf.stimSamps);  
            
            % Update online GUI      
            set(h.status,     'string', sprintf('%s',gf.status))
            set(h.pitch,      'string', sprintf('%.3f kHz', gf.current_freq / 1e3))     
            set(h.holdTime,   'string', '-')
            set(h.currentStim,'string', gf.Speaker) 
            set(h.target,     'string', sprintf('%.1f dB SPL', gf.current_dB))
            set(h.trialInfo,  'string', sprintf('%d',gf.TrialNumber-1))  % Current trial

            gf.status = 'PlayStim';


        case('PlayStim')

            gf.startTrialTime = invoke(DA,'GetTargetVal',sprintf('%s.zTime',gf.stimDevice));
            gf.startTrialTime = gf.startTrialTime / gf.fStim;

            mp_ok(1) = DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 1);                
            mp_ok(2) = DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 0);        

            if ~all(mp_ok)
                warning('Failed to intiate stimulus presentation')
            end
            
            set(h.comment,'string','Stim Start');

            gf.status = 'WaitForStim';                   
            set(h.status,'string',gf.status);            


        case('WaitForStim')        

            timeNow = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed = timeNow - gf.startTrialTime;
            timeRemaining  = gf.wait_period - timeElapsed;

            if timeRemaining > 0

                set(h.comment,'string',sprintf('Stim playing: %.3f', timeRemaining));
            else                                          
                logTrial_FRA;                                                                 
                gf.status = 'PrepareStim';        
                set(h.status,'string',gf.status);
            end
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
