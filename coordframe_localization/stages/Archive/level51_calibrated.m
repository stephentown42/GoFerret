function level51_calibrated

% Single presentation only

global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles* 

try


%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));


% Check other matlab
if isa(h.tcpip,'tcpip')
    if h.tcpip.BytesAvailable > 0    
        gf.centerStatus = fread(h.tcpip, h.tcpip.BytesAvailable);
        gf.centerStatus = max(gf.centerStatus);        
        DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), gf.centerStatus);
    end
%         
%     fwrite(h.tcpip,  2)
else
    gf.centerStatus = 1;
end

% Update timeline
updateTimeline(20)


%Run case
switch gf.status

%__________________________________________________________________________    
    case('PrepareStim')%none to prepare
        
        % Obtain trial parameters                                
        [gf.hold, gf.holdTime] = getHoldTime(gf.hold);    
                   
        
        % Get stimulus parameters                             
        [gf.stim, gf.stimGrid] = getStimGrid(gf.stim);

        gf.modality    = gf.stimGrid(1);    % 0 = LED, 1 = Speaker, 2 = Both 
        gf.LED         = gf.stimGrid(3);
        gf.Speaker     = gf.stimGrid(4); 
        gf.targetSpout = gf.stimGrid(5);   % Define target spout based on target modality

        % Force unisensory contingency
        if gf.modality < 2
            gf.modality = gf.domMod;
        end

        % Force target spout
        switch gf.domMod
            case 0 
                gf.targetSpout = gf.LED;
            case 1
                gf.targetSpout = gf.Speaker;
        end

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
        gf.correctionTrial = 0;        % Identify as new trial
        gf.stimPlayCheck   = nan;      % Reset play checker
        
        % Time to Sample conversion
        gf.holdSamples = ceil(gf.holdTime * gf.fStim);        
        gf.reqSamps = gf.holdSamples - ceil(gf.absentTime*gf.fStim);    % Samples required to initiate
        gf.stimSamps = ceil(gf.duration*gf.fStim);
                    
        playDelay = gf.holdSamples - gf.stimSamps;
                
        if playDelay <= 0 
            warning('Play delay less than zero')
        end
        
        % Set timing parameters on TDT
        DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice),     1);    % Enable center spout
        DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice),      gf.holdSamples);             
        DA.SetTargetVal( sprintf('%s.absentSamps', gf.stimDevice),      round(0.1*gf.fStim)); % 29/8/16  
        DA.SetTargetVal( sprintf('%s.refractorySamps', gf.stimDevice),  round(0.1*gf.fStim)) % 29/8/16  
        DA.SetTargetVal( sprintf('%s.reqSamps', gf.stimDevice),         gf.reqSamps);               
        DA.SetTargetVal( sprintf('%s.nStim', gf.stimDevice),            1); % Single presentation
        DA.SetTargetVal( sprintf('%s.stimSamps', gf.stimDevice),        gf.stimSamps);  
        DA.SetTargetVal( sprintf('%s.playDuration', gf.stimDevice),     gf.stimSamps+1); % Single presentation
        DA.SetTargetVal( sprintf('%s.stim&intSamps', gf.stimDevice),    gf.stimSamps);
        DA.SetTargetVal( sprintf('%s.playDelay', gf.stimDevice),        playDelay);
        
        % Set stimulus parameters on TDT
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
         set(h.status,     'string',sprintf('%s',gf.status))
%         set(h.side,       'string',gf.speaker)          
        set(h.pitch,      'string',gf.modality)     
        set(h.holdTime,   'string',sprintf('%.3f s',gf.holdTime))
        set(h.currentStim,'string',gf.domMod) 
        set(h.atten,      'string','-')        
        set(h.trialInfo,  'string',sprintf('%d',gf.TrialNumber-1))  % Current time
    
         % Skip LEDs beyond +/- 60 deg     
%          if gf.Speaker~=gf.LED
             gf.status = 'WaitForStart';
%          else
%              if gf.TrialNumber > 5
%              gf.status = 'PrepareStim';
%              else
%                  
%                  gf.status = 'WaitForStart';
%              end
%          end
%         
%         if gf.modality == 0 && gf.speaker < 10 && gf.speaker > 2
%             gf.status = 'PrepareStim';
%         end 
%         
        
% Center Response__________________________________________________________        
    case('WaitForStart')
        
        DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), 1);                    
        DA.SetTargetVal(sprintf('%s.playEnable', gf.stimDevice), 1);
                
        centerLick = invoke(DA,'GetTargetVal',sprintf('%s.lick6',gf.stimDevice));
        comment = 'LED flashing, waiting for center lick';
        
        %If start
        if centerLick == 1;            
            
            gf.status = 'WaitForResponse';            
            gf.startTrialTime = invoke(DA,'GetTargetVal',sprintf('%s.lick6time',gf.stimDevice));
            gf.startTrialTime = gf.startTrialTime / gf.fStim;
            comment = 'Center spout licked';           
            
            % Reward at center spout
            if gf.centerStatus && gf.centerRewardP > rand(1)
                gf.centerReward = 1;
                comment         = 'Trial initiated - giving reward';
                
                valveJumbo_J4(6, gf.centerValveTime);
            else
                gf.centerReward = 0;
                comment         = 'Trial Initiated - no reward';
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
                        
%             if gf.stimPlayCheck == 0
%                 DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 1);                
%                 DA.SetTargetVal(sprintf('%s.manualPlay', gf.stimDevice), 0);
%                 fprintf('Manual play\n')
%             end
        end
        
        % Check spouts for response
        DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), 0);
        [lick, lickTime] = deal(zeros(12,1));
        
        for i = 1 : 12
           lick(i) = DA.GetTargetVal( sprintf('%s.lick%d', gf.stimDevice, i));
           lickTime(i) = DA.GetTargetVal( sprintf('%s.lick%dtime', gf.stimDevice, i));
        end
        
        lick(6) = 0;       % Ignore center spout   
        
        if isfield(gf,'spouts2ignore')
           lick(gf.spouts2ignore) = 0; 
        end
        
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
            DA.SetTargetVal(sprintf('%s.playEnable', gf.stimDevice), 0); % Stop stimulus repeating
            valveID = find(lick);
            comment = '';
            
            if numel(valveID) == 1, 

                % Get response time
                gf.responseTime = lickTime(valveID) ./ gf.fStim;  %Open Ex            

                % If correct response
                if valveID == gf.targetSpout  
                                        
                     % Reward
                     valveJumbo_J4(valveID, gf.valveTimes(valveID))
                     comment = 'Correct - reward given';
                     gf.status = 'WaitForEnd';                    
                    
                % Otherwise give time out
                else
                    comment = 'Incorrect - repeating trial';
                    gf.status = 'timeout';                   
                end

                % Update performance                      
                updatePerformance(valveID)
                
                % Log trial
                logTrial(gf.centerReward, valveID)
                
                % Reset trial             
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 1);
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 0);                
                DA.SetTargetVal(sprintf('%s.playEnable', gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.LED_stim_V',  gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.LED_bgnd_V',  gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.Spkr_stim_V', gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), 0);
            else
                fprintf('multiple licks detected\n')                
            end        
        end
               
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
    case 'WaitForEnd'
        
        
        if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;           
            gf.status = 'PrepareStim';
        end
        
    case 'timeout'
        
        DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_stim_V); 
        DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.trial_Spkr_stim_V); 
        pause(0.01)
        DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_bgnd_V); 
        DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V); 
        
        if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;
            DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
            
            % Correction trials for unisensory (0|1) but not multisensory
            % (2) stimuli
            if gf.modality == 2
                gf.status = 'PrepareStim';
            else
                if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;
                    gf.status = 'PrepareStim';
                end
                gf.correctionTrial = 1;
            end
        end

end

catch err
    err
    keyboard    
end

function y = getMUXfamily(x)

x = ['0' dec2base(x-1, 4)];   % Convert to quarternery numeral for mux input
x = ['0',x];                  % Add zero to cope with case where x < 0 and function returns shorter output
y = [str2num(x(end-1)), str2num(x(end))];    % Reformat from char to double
       


    

    
    


