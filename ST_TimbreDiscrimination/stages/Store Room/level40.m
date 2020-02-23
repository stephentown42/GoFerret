function level40

% Level 10

global DA gf h rstr
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles
% rstr: Online raster 

try

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

% TDT time
gf.tStim = DA.GetTargetVal( sprintf( '%s.zTime',  gf.stimDevice)) ./ gf.fStim;
gf.tRec  = DA.GetTargetVal( sprintf( '%s.zTime',  gf.recDevice)) ./ gf.fRec;

%Run case
switch gf.status
%__________________________________________________________________________    
    case('PrepareStim')
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        
        % Use a random number to pick sound index; sound probabilities biased by gf.soundCumulP        
        sideIdx = findnearest(rand(1), gf.soundCumulP, 1);
        gf.side = gf.sides(sideIdx); 
        
         % Monitor trial history
        gf.trialHistory(gf.TrialNumber) = gf.side;            
        
        % Conditional arguments 
        startTrials    = 5;                % No test stimuli in the first N trials
        testRefractory = 2; 
        
        if gf.TrialNumber > startTrials,
        
            if all(gf.trialHistory(gf.TrialNumber: -1 : gf.TrialNumber - testRefractory)==-1), %#ok<*EFIND>
                gf.status = 'PrepareStim';
                return
            end
        else
            if gf.side < 0,                        
                gf.status = 'PrepareStim';
                return                
            end
        end
        
        
        gf.formants = eval(sprintf('gf.sound%d',sideIdx - 1));
        
        % Use a random number to pick sound index; sound probabilities biased by gf.soundCumulP        
%         sideIdx = findnearest(rand(1), gf.soundCumulP, 1);
%         gf.side = gf.sides(sideIdx);     
        
        % Monitor trial history
        gf.trialHistory(gf.TrialNumber) = gf.side;            
                
        % Calculate hold range, attenuation & pitch
        %
        % Generate gf.holdTime etc from variables declared in parameters 
        %
        % May be changed between stimuli, open to user control
        %
        % Developer note, these functions should be changed to state input
        % and output arguements. Both functions are the same and should be
        % combined to improve efficiency.
        
        calculateHoldTimes        
        calculateAtten
       
        %calculatePitch                
        if gf.pInd == 0,
            gf.pitchInd = randperm(length(gf.pitchRange));
        end
        
        gf.pInd  = gf.pInd + 1;              
        gf.pitch = gf.pitchRange(gf.pitchInd(gf.pInd));
        
        if gf.pInd == length(gf.pitchRange),
            gf.pInd = 0;
        end
        
        % Make hold time minimum for mismatch (side = -1) stimuli       
        gf.holdTime    = gf.holdMin;
        gf.holdSamples = ceil((gf.holdMin / 1000) * gf.fStim);
        gf.atten       = gf.attenMin;
        gf.pitch = 200;
        gf.formants = [0 2058 0 0];
        gf.duration = 750;

        % Generate sound        
        sound = ComputeSingleFormantVowels_noEnvelope(gf.formants);             % create vowel        
        
        isi    = zeros(1, ceil(gf.isi/1000 * gf.fStim));     % add interstimulus interval
        holdOK = length(sound) + length(isi);                % point in stimulus that the ferret must hold to        
%         sound  = [sound, sound, sound];                        % create two vowels with two intervals
        sound = envelope(sound, 250);
        
        % Calculate timing information
        playDelay = gf.holdSamples - holdOK;
        refractS  = playDelay + length(sound) + ceil(gf.refractoryTime * gf.fStim);
        absentS   = ceil(gf.absentTime * gf.fStim);
        
        % Calibrate sounds
        sound0 = conv(sound, gf.fltL.flt, 'same');
        sound1 = conv(sound, gf.fltR.flt, 'same');
        
%         sound0 = sound; %calibrateSignal(sound, gf.calibDir, 1);
%         sound1 = sound; %calibrateSignal(sound, gf.calibDir, 1);
        
        % Side dependent calibration
        [Left_attn, Right_attn] = getCalibAtten(63.5);
        sound0 = sound0 .* 10 ^(-(Left_attn/20));
        sound1 = sound1 .* 10 ^(-(Right_attn/20));    
        
        % Write sound to buffers
        DA.WriteTargetVEX(sprintf('%s.sound0', gf.stimDevice), 0, 'F32', sound0); % Play from 
        DA.WriteTargetVEX(sprintf('%s.sound1', gf.stimDevice), 0, 'F32', sound1); % both speakers
        
        % Set length of time to play noise during timeout
        DA.SetTargetVal( sprintf('%s.noiseDuration', gf.stimDevice), gf.noiseDuration);
        
        % Set timing information on TDT
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));        
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);  
        DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), absentS);
        DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), playDelay); 
        DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), refractS);
                 
        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1);                         
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
        DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition
        %DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 0);                 % Disable constant LED in hold time
        %DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 0);                 % Disable sound in hold time
            
        % Update online GUI       
        set(h.status,     'string',sprintf('%s',gf.status))
        set(h.side,       'string',num2str( gf.side))          
        set(h.pitch,      'string',sprintf('%d Hz', gf.pitch))     
        set(h.holdTime,   'string',sprintf('%.0f ms', gf.holdTime))
        set(h.currentStim,'string',sprintf('%d, %d, %d, %d', gf.formants)) 
        set(h.atten,      'string',sprintf('%.1f dB', gf.atten))        
        set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
        
        
        % Conditional arguments 
        startTrials   = 5;                % No test stimuli in the first N trials
        testRefractory = 2; 
        
        if gf.TrialNumber > startTrials,
        
            if ~all(gf.trialHistory(gf.TrialNumber: -1 : gf.TrialNumber - testRefractory)==-1), %#ok<*EFIND>
                gf.status = 'WaitForStart';
            else
                gf.status = 'PrepareStim';
            end
        else
            if gf.side >= 0,                        
                gf.status = 'WaitForStart';
            else
                gf.status = 'PrepareStim';
            end
        end
        
        
% Center Response__________________________________________________________        
    case('WaitForStart')

        DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
        DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time        

        centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.CenterLick',gf.stimDevice));
        
        %If no start
        if centerLick == 0;
            
            %Flash LED
            DA.SetTargetVal(sprintf('%s.flashEnable',gf.stimDevice),1);
            comment = 'LED flashing, waiting for center lick';
            
        else
            DA.SetTargetVal( sprintf('%s.flashEnable',      gf.stimDevice), 0);              
            
            if  gf.correctionTrial == 1;
                DA.SetTargetVal( sprintf('%s.repeatPlay', gf.stimDevice), isfield(gf,'correctionTrialRepeat')); 
            end
            
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.CenterLickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
%             rstr.startTimes      = [rstr.startTimes gf.startTrialTimes];
            gf.status            = 'WaitForResponse';
            
            % Reward at center spout           
            if gf.centerRewardP > rand(1),
                gf.centerReward = 1;
                comment         = 'Center spout licked - giving reward';
            
                valve(6, gf.centerValveTime, 1, 'center');     
                
            else
                gf.centerReward = 0;
                comment         = 'Center spout licked - no reward';
            end
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
        
% Peripheral Response______________________________________________________        
    case('WaitForResponse')
               
        DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...        
        
        leftLick    = DA.GetTargetVal( sprintf( '%s.LeftLick',  gf.stimDevice));
        rightLick   = DA.GetTargetVal( sprintf( '%s.RightLick', gf.stimDevice));
        
        % If no response
        if (leftLick == 0) && (rightLick==0) 
            
            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed    = timeNow - gf.startTrialTime;
            timeRemaining  = gf.abortTrial - timeElapsed;
              
            comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);
            
            % Check response countdown
            if timeRemaining <= 0,
                
                gf.status         = 'PrepareStim';       
                
                %Log aborted response
                gf.responseTime = -1;
                response        = -1;
                logTrial(gf.centerReward, response)                   %See toolbox (-1 = aborted trial)
                
                % Update perfomance graph
                updatePerformance(3)             % code 3 = abort trial
            end
        
        %If response
        else
       
%             gf.responseTime = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
            
            DA.SetTargetVal(sprintf('%s.repeatPlay',gf.stimDevice),0);       %Turn sound repetition off
        
            % If animal goes right
            if rightLick > 0,
                
                %Log response to right
                gf.responseTime = DA.GetTargetVal(sprintf('%s.RightLickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
                response        = 1;
                logTrial(gf.centerReward, response)                   %See toolbox 
                
                if gf.side == 1 || gf.side == -1, % Correct response
                    
                    valve(5,gf.rightValveTime,1,'right');     %Reward at right spout
                    comment    = 'Correct response to "right" - giving reward';
                    gf.status  = 'PrepareStim';
                    
                    % Update perfomance graph
                    updatePerformance(2)             % code 2 = right correct
                    
                else
                    % Give timeout
                    comment    = 'Incorrect response to "right" - timeout';
                    gf.status  = 'timeout';
                              
                    DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),1);
                    DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),0);
                                        
                    % Disable center spout
                    DA.SetTargetVal( sprintf('%s.resetEnable', gf.stimDevice), 0);
                    
                    % Update perfomance graph
                    updatePerformance(1)             % code 1 = right incorrect
                end   

    
            elseif leftLick > 0 
                
                %Log response to left
                 gf.responseTime = DA.GetTargetVal(sprintf('%s.LeftLickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
                response = 0;
                logTrial(gf.centerReward, response)                   %See toolbox 
                
                if gf.side == 0 || gf.side == -1,
                
                    %Reward at left spout
                    valve(4,gf.leftValveTime,1,'left'); 
                    comment    = 'Correct response to "left" - giving reward';
                    gf.status  = 'PrepareStim';
                    
                    % Update perfomance graph
                    updatePerformance(4)             % code 4 = left correct                  
                
                else
                    % Give timeout
                    comment    = 'Incorrect response to "left" - timeout';
                    gf.status  = 'timeout';
                    
                    DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),1);
                    DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),0);
                                        
                    % Disable center spout
                    DA.SetTargetVal( sprintf('%s.resetEnable', gf.stimDevice), 0);
                    
                    % Update perfomance graph
                    updatePerformance(5)             % code 5 = left incorrect
                end   
            end                        
        end            
                
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);

% Timeout _________________________________________________________________  

    case 'timeout'

            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed    = timeNow - gf.responseTime;
            timeRemaining  = gf.timeoutDuration - timeElapsed;
                        
            comment = sprintf('Timeout: \nTime remaining %0.1f s', timeRemaining);
            set(h.comment,'string',comment);
            
            if timeRemaining <= 0,
               
                % Go straight to waiting, do not prepare another stimulus.
                % Use the same stimulus in a correction trial until the
                % correct response is made.
                
                gf.status          = 'WaitForStart';
                gf.correctionTrial = 1;
                
                % Reset enable parameter tags for correction trial                             
                DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);     % Disable OpenEx driven sound repetition                        
                DA.SetTargetVal( sprintf('%s.repeatPlay', gf.stimDevice), 0);                       
                DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);  
                
                % Update trial number
                set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))  
            end
                                   
            set(h.status,'string',gf.status);
end

%Update timeline
updateTimeline(20)

% Update neural data
% updateRaster


catch err
    
    err 
    keyboard
    
end

