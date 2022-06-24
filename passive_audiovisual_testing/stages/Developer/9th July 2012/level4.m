function level4

% Level 4: 
% Two or more stimuli are presented 
% Mistakes do not terminate trials

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
    case('PrepareStim')
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        % Determine peripheral reward side
        gf.side = round(rand(1));
        
        % Calculate hold range* 
        calculateHoldTimes
        
        % Calculate attenuation*
        calculateAtten

        % Calculate pitch*
        calculatePitch
                    
        formants = eval(sprintf('gf.sound%d',gf.side));
        sound    = ComputeTimbreStim(formants);                     % create vowel
        sound    = [sound zeros(1, ceil(gf.isi/1000 * gf.fStim))];  % add interstimulus interval              
        sound    = [sound sound];                                   % create two vowels with two intervals
        
        % Update TDT
        
        DA.WriteTargetVEX(sprintf('%s.sound0', gf.stimDevice), 0, 'F32', sound); % Play from 
        DA.WriteTargetVEX(sprintf('%s.sound1', gf.stimDevice), 0, 'F32', sound); % both speakers

        DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
        DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 1);                 % ... avoids problem if animal is constantly at spout

        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);  
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));
        DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 0);                 % Disable constant LED in hold time
        DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 0);                 % Disable sound in hold time
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
        DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition
        
        % Check that sound is shorter than hold duration
        if gf.holdSamples + 1 > length(sound),
            DA.SetTargetVal( sprintf('%s.startSamp', gf.stimDevice), gf.holdSamples - length(sound)+1);
            gf.status = 'WaitForStart'; 
        else
            warning('Sound length (%d samples) > hold time duration (%d samples)- preparing another sound', length(sound), gf.holdSamples)
            gf.status = 'PrepareStim';
        end

        
        % Update online GUI       
        set(h.status,     'string',sprintf('%s',gf.status))
        set(h.side,       'string',num2str( gf.side))          
        set(h.pitch,      'string',sprintf('%d Hz', gf.pitch))     
        set(h.holdTime,   'string',sprintf('%.0f ms', gf.holdTime))
        set(h.currentStim,'string',sprintf('%d, %d, %d, %d', formants)) 
        set(h.atten,      'string',sprintf('%.1f dB', gf.atten))        
        set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
        
        
        % *
        %  Generate gf.holdTime and atten from variables declared in parameters 
        %
        %  May be changed between stimuli, open to user control
        %
        %  Developer note, these functions should be changed to state input
        %  and output arguements. Both functions are the same and should be
        %  combined to improve efficiency.
    
        
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
            DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 0);     % Disable constant LED in hold time
            DA.SetTargetVal( sprintf('%s.flashEnable',      gf.stimDevice), 0);     % Stop LED flash
            DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 0);     % Disable OpenEx driven sound in hold time            
            DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);     % Disable OpenEx driven sound repetition            
            DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 1);     % Enable Matlab driven
           
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
               
        leftLick    = DA.GetTargetVal( sprintf( '%s.LeftLick',  gf.stimDevice));
        rightLick   = DA.GetTargetVal( sprintf( '%s.RightLick', gf.stimDevice));
             
        if leftLick > 0 && gf.side == 0,

            %Reward at left spout
            valve(4,gf.leftValveTime,1,'left'); 

            comment         = 'Correct response to "left" - giving reward';                    

            gf.responseTime = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex  
            gf.status       = 'PrepareStim';


            DA.SetTargetVal(sprintf('%s.repeatPlay',gf.stimDevice),0);       %Turn sound repetition off

            %Log response to left
            response = 0;
            logTrial(gf.centerReward, response)                   %See toolbox 

            % Update perfomance graph
            updatePerformance(4)             % code 4 = left correct     
                

        elseif rightLick > 0 && gf.side == 1,

            valve(5,gf.rightValveTime,1,'right');     %Reward at right spout

            comment         = 'Correct response to "right" - giving reward';                    

            gf.responseTime = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex           
            gf.status       = 'PrepareStim';

            DA.SetTargetVal(sprintf('%s.repeatPlay',gf.stimDevice),0);       %Turn sound repetition off

            %Log response to right
            response        = 1;
            logTrial(gf.centerReward, response)                   %See toolbox 

            % Update perfomance graph
            updatePerformance(2)             % code 2 = right correct


        else
            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
            timeElapsed    = timeNow - gf.startTrialTime;
            timeRemaining  = gf.abortTrial - timeElapsed;

            comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);

            if timeRemaining <= 0,

                gf.status         = 'PrepareStim';
                gf.abortedTrials  = gf.abortedTrials + 1;
                
                DA.SetTargetVal(sprintf('%s.repeatPlay',     gf.stimDevice),0);       %Turn sound repetition off

                %Log aborted response
                gf.responseTime = -1;
                response        = -1;
                logTrial(gf.centerReward, response)                   %See toolbox (-1 = aborted trial)


                % Update perfomance graph
                updatePerformance(3)             % code 3 = abort trial
                
            end
        end  
                
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
end

%Check outputs
checkOutputs([4 5 6 7]);                                %See toolbox for function

%Update timeline
updateTimeline(20)




