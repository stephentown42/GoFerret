function level55_test

% Same as level 53, duplicated for separation of egocentric testing
% ST 13 Feb 2019

global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles* 

try


%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

% Update timeline (disabled in Win 10)
check_video_status;
gf.centerStatus = 1;

%Run case
switch gf.status

%__________________________________________________________________________    
    case('PrepareStim')
        
        % Obtain trial parameters                                
        [gf.hold, gf.holdTime] = getHoldTime(gf.hold);                       
        
        % Get stimulus parameters                    
        if gf.correctionTrial == 0
            [gf.stim, gf.stimGrid] = getStimGrid_CF_Level55(gf.stim, gf.centerSpoutRotation);
        end

        gf.modality    = gf.stimGrid(1);    % 0 = LED, 1 = Speaker, 2 = Both 
        gf.LED         = gf.stimGrid(4);
        gf.Speaker     = gf.stimGrid(3); 
        gf.targetSpout = gf.stimGrid(5);   % Define target spout based on target modality
        gf.centerPass  = 0;                 % Latched variable using head direction to modulate reward value        
        
        
        if check_online_stim_limit( gf.targetSpout), return; end
        
        % Probe trial override
        gf.probe_trial = false;
        
        if rand < gf.probe_probablity &&...
                gf.correctionTrial == 0 &&...
                gf.TrialNumber > 10 
                       
            probe_idx = randperm(numel(gf.stim.probe_positions), 1);
            
            gf.Speaker = gf.stim.probe_positions( probe_idx);
            gf.probe_trial = true;                                    
        end               
        
        
%         if gf.targetSpout == 3, return; end
        
        % Convert stimulus positions to multiplex (mux) values
        gf.LEDmux = getMUXfamily( gf.LED); 
        gf.SPKmux = getMUXfamily( gf.Speaker);
                
        % Force levels to be stim intensity
        gf.trial_Spkr_stim_dB = gf.Spkr_stim_dB;
        gf.trial_LED_stim_V   = gf.LED_stim_V;
               
        % Apply calibration to auditory stimuli
        gf.trial_Spkr_stim_V = getJumboCalib(gf.trial_Spkr_stim_dB, gf.Speaker);
        gf.Spkr_bgnd_V       = getJumboCalib(gf.Spkr_bgnd_dB, gf.Speaker);
                
        % Initialize variables
        gf.stimPlayCheck   = nan;      % Reset play checker
        
        % Time to Sample conversion
        gf.holdSamples = ceil(gf.holdTime * gf.fStim);        
        gf.reqSamps = gf.holdSamples - ceil(gf.absentTime*gf.fStim);    % Samples required to initiate
        gf.isiSamps = ceil(gf.isi*gf.fStim);
        gf.stimSamps = ceil(gf.duration*gf.fStim);
        
        playDelay = gf.holdSamples - gf.stimSamps - gf.isiSamps;
        playDuration = gf.nStimRepeats*(gf.isiSamps+gf.stimSamps);
        
        if playDelay <= 0 
            warning('Play delay less than zero'); return
        end
        
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
        DA.SetTargetVal( sprintf('%s.LED_stim_V',  gf.stimDevice), gf.trial_LED_stim_V);            
        DA.SetTargetVal( sprintf('%s.LED_bgnd_V',  gf.stimDevice), gf.LED_bgnd_V);
        DA.SetTargetVal( sprintf('%s.Spkr_stim_V', gf.stimDevice), gf.trial_Spkr_stim_V	); 
        DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V);
        DA.SetTargetVal( sprintf('%s.modality',    gf.stimDevice), gf.modality);
        DA.SetTargetVal( sprintf('%s.Spkr-mux-01', gf.stimDevice), gf.SPKmux(1));
        DA.SetTargetVal( sprintf('%s.Spkr-mux-10', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.Spkr-mux-11', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.Spkr-mux-12', gf.stimDevice), gf.SPKmux(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-01', gf.stimDevice),  gf.LEDmux(1));
        DA.SetTargetVal( sprintf('%s.LED-mux-10', gf.stimDevice),  gf.LEDmux(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-11', gf.stimDevice),  gf.LEDmux(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-12', gf.stimDevice),  gf.LEDmux(2));  % Brute force approach
        
        % Update online GUI      
        set(h.status,     'string', sprintf('%s',gf.status))
        set(h.pitch,      'string', gf.modality)     
        set(h.holdTime,   'string', sprintf('%.3f s',gf.holdTime))
        set(h.currentStim,'string', gf.Speaker) 
        set(h.target,     'string', gf.targetSpout)        
        set(h.trialInfo,  'string', sprintf('%d',gf.TrialNumber-1))  % Current trial
    
        gf.centerReward = 0; % report, not set variable 
        gf.status = 'WaitForStart';

        
% Center Response__________________________________________________________        
    case('WaitForStart')
        
        DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), 1); 
        DA.SetTargetVal(sprintf('%s.playEnable', gf.stimDevice), 1);
                
        centerLick = DA.GetTargetVal( sprintf('%s.lick6',   gf.stimDevice));        
        comment = 'LED flashing, waiting for center lick';
        
        %If start and stimulus has played
        if centerLick == 1 %&& hasPlayed;            
            
            gf.centerPass = gf.centerStatus;
            gf.centerPixelVal = DA.GetTargetVal('RX8.trackingVal');
            gf.status = 'WaitForResponse';           
            gf.startTrialTime = invoke(DA,'GetTargetVal',sprintf('%s.lick6time',gf.stimDevice));
            gf.startTrialTime = gf.startTrialTime / gf.fStim;
            comment = 'Center spout licked';           
            
            % Reward at center spout            
            if gf.centerRewardP > rand(1)

                % Escape if using tracking and failed to align head
                if ~gf.track || gf.centerPass == 1
                
                    % Give reward
                    gf.centerReward = 1;
                    comment         = 'Trial initiated - giving reward';
                    
                    valveJumbo_J5(6, gf.centerValveTime, gf.box_mode);            
                else
                    comment         = 'Trial Initiated - no reward';
                end
            end            
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
        
% Peripheral Response______________________________________________________        
    case('WaitForResponse')
        
        % Check stimulus has played
        if isnan(gf.stimPlayCheck)
            gf.stimPlayCheck = DA.GetTargetVal( sprintf('%s.stimON', gf.stimDevice));
                        
            if gf.stimPlayCheck == 0 && gf.nStimRepeats > 5
                DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 1);                
                DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 0);
                fprintf('Manual play\n')
            end
        end
        
        % Force single presentation
        if gf.nStimRepeats == 1,                               
            DA.SetTargetVal(sprintf('%s.playEnable', gf.stimDevice), 0);
        end
        
        % Check spouts for response
        DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), 0);
        [lick, lickTime] = deal(zeros(12,1));
        
        for i = 1 : 12
           lick(i) = DA.GetTargetVal( sprintf('%s.lick%d_%s', gf.stimDevice, i, gf.box_mode));
           lickTime(i) = DA.GetTargetVal( sprintf('%s.lick%dtime_%s', gf.stimDevice, i, gf.box_mode));
        end
        
        lick(6) = 0;       % Ignore center spout   
        spouts2ignore = setdiff(1:12, unique(gf.stim.targetSpout));       
        lick(spouts2ignore) = 0; % Ignore other spouts (i.e. force 2-choice task)
        
        % If no response
        if ~any(lick) 
            
            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed    = timeNow - gf.startTrialTime;
            timeRemaining  = gf.abortTrial - timeElapsed;
            
            comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);
            
            %Check response countdown
            if timeRemaining <= 0,
                
                % Reset trial
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 1);
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 0);
                
                gf.abortedTrials  = gf.abortedTrials + 1;                                               
                gf.status         = 'WaitForEnd';
                
                %Log aborted response
                gf.responseTime = -1;
                logTrial(gf.centerReward, -1)                   %See toolbox (-1 = aborted trial)                   
            end
            
            
            
        % Otherwise record response time
        else                                          
            licked_spout = find(lick);
            comment = '';
            
            % Track responses to estimate bias            
            gf.biasTracker.idx = gf.biasTracker.idx + 1;
            gf.biasTracker.data = [gf.biasTracker.data licked_spout];
            
            % Update valve times if bias is a problem
%             if gf.biasTracker.idx > gf.biasTracker.window &&...    % Only do after we've got 8 trials
%                mod(gf.biasTracker.idx, gf.biasTracker.window) == 0  % Only if an integer of 8 (gives a cycle of time for bias adjustment to work rather than continual tweaking)
%             
%                 % Calculate bias
%                 idx =  gf.biasTracker.idx - (1 : gf.biasTracker.window) ;
%                 gf.biasTracker.current = mean(gf.biasTracker.data(idx)) - 6;
%                 
%                 % Calculate adjustment
%                 gf.biasTracker.adjustment = abs(gf.biasTracker.current) * gf.biasTracker.rate;  % Linear rate of change
%                 gf.biasTracker.adjustment = max([gf.biasTracker.adjustment gf.biasTracker.saturation]); % Saturating non-linearity
%                 
%                 % Act based on direction of bias
%                 if gf.biasTracker.current > 0 % Bias towards 9
%                 
%                     gf.valveTimes(3) = gf.valveTimes(3) + gf.biasTracker.adjustment;
%                     gf.valveTimes(9) = gf.valveTimes(9) - gf.biasTracker.adjustment;
%                     
%                 else % Bias towards 3                
%                     gf.valveTimes(3) = gf.valveTimes(3) - gf.biasTracker.adjustment;
%                     gf.valveTimes(9) = gf.valveTimes(9) + gf.biasTracker.adjustment;
%                 end        
%                 
%                 % Minimize valve times at min val
%                 gf.valveTimes(gf.valveTimes <= 0) = 0.05;                
%                 gf.valveTimes(gf.valveTimes > 0.5) = 0.5;
%             end
            

            % Temporarily cut reward time if the animal didn't pass the center test
            if gf.track && gf.centerPass == 0
                gf.valveTimes = gf.valveTimes ./ 2;
            end
            
            % If a single response
            if numel(licked_spout) == 1, 

                % Get response time
                gf.responseTime = lickTime(licked_spout) ./ gf.fStim;  %Open Ex            

                % If correct response
                if licked_spout == gf.targetSpout || gf.probe_trial
                                        
                     % Reward
                     valveJumbo_J5(licked_spout, gf.valveTimes(licked_spout), gf.box_mode);
                     comment = 'Correct - reward given';
                     gf.status = 'WaitForEnd';
                     
                     % Otherwise give time out
                else
                    comment = 'Incorrect - repeating trial';
                    gf.status = 'timeout';
                end
                                
                % Update performance
                updatePerformance(licked_spout);
                
                % Log trial
                logTrial(gf.centerReward, licked_spout);
                
                % Reset trial
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 1);
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.playEnable', gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.LED_stim_V',  gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.LED_bgnd_V',  gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.Spkr_stim_V', gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), 0);                
            else
                fprintf('multiple licks detected\n')                
            end       
            
            % Restore cut reward time 
            if gf.track && gf.centerPass == 0
                gf.valveTimes = gf.valveTimes .* 2;
            end
        end
               
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
    case 'WaitForEnd'
        
        gf.correctionTrial = 0;
        
        if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;           
            gf.status = 'PrepareStim';
        end
        
    case 'timeout'
        
        gf.correctionTrial = 1;
        
%         DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_stim_V); 
%         DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.trial_Spkr_stim_V); 
%         pause(0.01)
%         DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_bgnd_V); 
%         DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V); 
                        
        % Give error beep       
        if ~gf.beep_given || ~isfield(gf,'beep_given')
            DA.SetTargetVal( sprintf('%s.errorPulse', gf.recDevice), 1); 
            DA.SetTargetVal( sprintf('%s.errorPulse', gf.recDevice), 0); 
            gf.beep_given = true;
        end
        
        timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
        timeElapsed    = timeNow - gf.responseTime;
        timeRemaining  = gf.timeout_duration - timeElapsed;
        
        if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0 &&...
                timeRemaining <= 0,
            DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
                        
            gf.beep_given = false;
            
            % Correction trials for unisensory (0|1) but not multisensory
            % (2) stimuli
            if gf.modality == 2
                gf.status = 'PrepareStim';
            else
                if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;
                    gf.status = 'PrepareStim';
                end
            end
            
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
       


    

    
    


