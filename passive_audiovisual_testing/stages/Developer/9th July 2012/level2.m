function level2

% Level 2: 
% The ferret is required to visit the center spout for a reward, and to 
% enable the peripheral spouts so that peripheral visits also result in a
% reward.
%
% Visits to the central spout require a minimum hold time, which is
% controllable by the user. The LED is constantly on during the minimum
% hold time. If the animal removes its head before the end of the hold
% time, the LED flashes at the end of the hold time and a reward is not
% given.
%
% The aim is simply for the subject to learn to hold its head for a
% constant time.
% 

global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles* 

%(*ideally i would get rid of this and just pass handles but it doesn't seem to work)

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

%Check sensor inputs
bits = [0       2       1];
vars = {'left','center','right'};

if iscom(DA) == 1,                                 % Only check sensors if TDT connected
    checkSensors(bits, vars);                      % See toolbox for function
end
    
%Run case
switch gf.status

%__________________________________________________________________________    
    case('PrepareStim')%none to prepare
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        %Calculate hold range (may be changed by user between trials)
        calculateHoldTimes
        
        DA.SetTargetVal( sprintf('%s.centerReset',      gf.stimDevice), 1);                 % Reset counter for center spout...
        DA.SetTargetVal( sprintf('%s.centerReset',      gf.stimDevice), 0);                 % ... avoids problem if animal is constantly at spout

        
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice),gf.holdSamples);  
        DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
        DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 0);                 % Disable sound in hold time
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable sound repetition in response window
        
        gf.status       = 'WaitForStart';     
        
        % Update online GUI       
        set(h.status,     'string',sprintf('%s',gf.status))
        set(h.side,       'string','-')          
        set(h.pitch,      'string','-')     
        set(h.holdTime,   'string',sprintf('%.0f ms',gf.holdTime))
        set(h.currentStim,'string','-') 
        set(h.atten,      'string','-')        
        set(h.trialInfo,  'string',sprintf('%d',gf.TrialNumber-1))
    
        
% Center Response__________________________________________________________        
    case('WaitForStart')
        
        centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.CenterLick',gf.stimDevice));
        
        %If no start
        if centerLick == 0;
            
            %Flash LED
            DA.SetTargetVal(sprintf('%s.flashEnable',gf.stimDevice),1);
            comment = 'LED flashing, waiting for center lick';
            
        else
            DA.SetTargetVal(sprintf('%s.flashEnable',gf.stimDevice), 0);      % Stop LED flash
            DA.SetTargetVal(sprintf('%s.LEDEnable',gf.stimDevice), 0);      % Stop LED flash
            
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
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
               
        leftLick    = invoke(DA,'GetTargetVal',sprintf('%s.LeftLick',gf.stimDevice));
        rightLick   = invoke(DA,'GetTargetVal',sprintf('%s.RightLick',gf.stimDevice));
        
        % If no response
        if (leftLick == 0) && (rightLick==0) 
            
            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed    = timeNow - gf.startTrialTime;
            timeRemaining  = gf.abortTrial - timeElapsed;
            
            comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);
            
            %Check response countdown
            if timeRemaining <= 0,
                
                gf.status         = 'PrepareStim';
                gf.abortedTrials  = gf.abortedTrials + 1;     
                
                %Log aborted response
                gf.responseTime = -1;
                response        = -1;
                logTrial(gf.centerReward, response)                   %See toolbox (-1 = aborted trial)
                                
                % Update perfomance graph
                updatePerformance(3)             % code 3 = abort trial                
            end
            
        % Otherwise record response time
        else        
            gf.responseTime = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
           
            % If animal goes right
            if rightLick > 0  
                
                %Log response to right
                response        = 1;
                logTrial(gf.centerReward, response)                   %See toolbox 
                
                %Reward at right spout
                valve(5,gf.rightValveTime,1,'right'); 
                comment    = 'Response was "right" - giving reward';
                    
                % Update perfomance graph
                updatePerformance(2)             % code 2 = right correct

            % If animal goes left (modified from Jenny's code - see orginal script for details)     
            elseif leftLick > 0 

                %Log response to left
                response = 0;
                logTrial(gf.centerReward, response)                   %See toolbox 
                
                %Reward at left spout
                valve(4,gf.leftValveTime,1,'left');  
                comment    = 'Response was "left" - giving reward';

                % Update perfomance graph
                updatePerformance(4)             % code 4 = left correct     
          
            end
                        
            gf.status       = 'PrepareStim';
        end            
                
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
end

%Check outputs
checkOutputs([4 5 6 7]);                                %See toolbox for function

%Update timeline
updateTimeline(20)




    

    
    


