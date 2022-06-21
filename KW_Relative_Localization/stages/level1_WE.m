function level1_WE

% White Elephant Level 8:
% Two or more stimuli are presented
% Presentations are limited to hold times (i.e. no repetition)
% Mistakes lead to time outs

global DA gf h
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

% For pacifying logTrial
gf.refChoice=-99;
gf.tarChoice=-99;


%Run case
switch gf.status
    
    % __________________________________________________________________________
    case('PrepareStim')
        
        %      gf.errFunc=[];
        % Identify as new trial
        gf.correctionTrial = 0;
        %
        calculateHoldTimes
        
        
        %
        %         % Calculate timing information
        holdOK      = 48000;
        playDelay = gf.holdSamples - holdOK;
        refSound=ceil(200*gf.fStim);
        refractS  = playDelay + length(refSound) + ceil(gf.refractoryTime * gf.fStim);
        absentS   = ceil(gf.absentTime * gf.fStim);
        
        
        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
        DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition
        
        %         % Set timing information on TDT
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(refSound));
        %       DA.SetTargetVal( sprintf('%s.firstNPoints',     gf.stimDevice),(length(refSound) + gf.repInterval*gf.fStim)/gf.fStim*1000);
        %       DA.SetTargetVal( sprintf('%s.repNPoints',       gf.stimDevice), length(refSound) + gf.repInterval*gf.fStim);
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);
        DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), absentS);
        DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), playDelay);
        DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), refractS);
        
        
        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1);
        %      DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition
        
        
        % Update online GUI
        set(h.status,     'string',sprintf('%s',gf.status))
        %         set(h.side,       'string',num2str( gf.side))
        set(h.pitch,      'string','N/A')
        set(h.holdTime,   'string',sprintf('%.0f ms', gf.holdTime))
        % set(h.currentStim,'string',num2str(gf.tarChoice))
        % set(h.atten,      'string',sprintf('%.1f dB', gf.atten))
        set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
        
        
        gf.status='WaitForStart';
        
        
        % Center Response__________________________________________________________
    case('WaitForStart')
        
        
        DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
        DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time
        %
        
        centreLick  = DA.GetTargetVal( sprintf('%s.lick1',gf.stimDevice));
        leftLick    = DA.GetTargetVal( sprintf( '%s.lick8',  gf.stimDevice));
        rightLick   = DA.GetTargetVal( sprintf( '%s.lick2', gf.stimDevice));
        
        if centreLick
            valve_WE(1,gf.centerValveTime,1)
            DA.SetTargetVal( sprintf('%s.led1in',      gf.stimDevice), 0);
            
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lick1Time',gf.stimDevice)) ./ gf.fStim;  %Open Ex
            gf.status            = 'WaitForResponse';
            
            comment         = 'Center spout licked - giving reward';
            
            %         elseif leftLick
            %             gf.side=8;
            %             gf.resp=8;
            %             valve_WE(8,gf.rewardTime,1)
            %             comment = 'left lick';
            %
            %
            %         elseif rightLick,
            %             gf.side=2;
            %             gf.resp=2;
            %             valve_WE(2,gf.rewardTime,1)
            %             comment = 'right lick';
            %             %   If no response,
        else
            %Flash LED
            DA.SetTargetVal(sprintf('%s.led1in',gf.stimDevice),1);
            comment = 'LED flashing, waiting for center lick';
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
        
        % Peripheral Response______________________________________________________
    case('WaitForResponse')
        
        if gf.useLEDs,
            DA.SetTargetVal( sprintf('%s.LEDthreshold',     gf.stimDevice), 0.01);          % Enable LEDs
        end
        
        
        DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
        
        centreLick  = DA.GetTargetVal( sprintf('%s.lick1',gf.stimDevice));
        leftLick    = DA.GetTargetVal( sprintf( '%s.lick8',  gf.stimDevice));
        rightLick   = DA.GetTargetVal( sprintf( '%s.lick2', gf.stimDevice));
        
        
        % Allow rewards at center spout to continue
        if centreLick,
            valve_WE(1,gf.centerValveTime,1)
        end
        
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
                logTrial(1, response)                   %See toolbox (-1 = aborted trial)
                
                % Update perfomance graph
                updatePerformance(3)             % code 3 = abort trial
            end
            
            %If response
        else
            
            
            % If animal goes right
            if rightLick > 0,
                
                %Log response to right
                gf.side=2;
                gf.resp=2;
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick2time',gf.stimDevice)) ./ gf.fStim;
                response        = 1;
                logTrial(1, response)                   %See toolbox
                
                %                 if gf.side == 1 || gf.side == -1, % Correct response
                
                valve_WE(2,gf.rewardTime*2,1)
                comment    = 'Correct response to "right" - giving reward';
                gf.status  = 'PrepareStim';
                
                % Update perfomance graph
                updatePerformance(2)             % code 2 = right correct
                
                
            elseif leftLick > 0
                
                %Log response to left
                gf.side=8;
                gf.resp=8;
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick8time',gf.stimDevice)) ./ gf.fStim;  %Open Ex
                response        = 0;
                logTrial(1, response)                   %See toolbox
                
                %                 if gf.side == 0 || gf.side == -1,
                
                %Reward at left spout
                valve_WE(8,gf.rewardTime*2,1)
                comment    = 'Correct response to "left" - giving reward';
                gf.status  = 'PrepareStim';
                
                % Update perfomance graph
                updatePerformance(4)             % code 4 = left correct
                
            end
        end
end
%Update GUI
set(h.status,'string',gf.status);

%Check outputs
checkOutputs_WE(10);
updateTimeline_WE(20)




