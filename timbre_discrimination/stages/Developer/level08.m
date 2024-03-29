function level8
try
% Level 8 Noise
% Options:  
%     Discrete / Continuous
%     Spatially separated / collocalized
%          
% Spatial separation options:
%   Signal(Left) + Noise (Right)
%   Signal(Right) + Noise (Left)
%   Signal(Both) + Noise (Both)

    

global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

%Check sensor inputs
bits = [0       2       1];
vars = {'left','center','right'};
    
%Run case
switch gf.status

%__________________________________________________________________________    
    case('PrepareStim')
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        
        % Create stimulus grid        
        if ~isfield(gf,'nStim'), 
            gf.sideList  = [0 1];                       
            gf.attnRange = gf.attenMin :(gf.attenMax - gf.attenMin)/ gf.attenSteps : gf.attenMax;    
            gf.maskCases = 1: 1 + 2*isfield(gf,'spatialUnmasking');
            
            gf.nStim     = length(gf.attnRange) * length(gf.sideList) * length(gf.maskCases);   
            gf.stimIdx   = gf.nStim + 1;
        end

        if gf.stimIdx > gf.nStim
            [attnIdx, sideIdx, maskIdx] = ind2sub([ length(gf.attnRange),...
                                                    length(gf.sideList),...
                                                    length(gf.maskCases)],...
                                                    randperm(gf.nStim));

            gf.stimOrder = [attnIdx', sideIdx', maskIdx'];
            gf.stimIdx   = 1;
        end

        gf.atten   = gf.attnRange( gf.stimOrder( gf.stimIdx, 1));
        gf.side    = gf.sideList(  gf.stimOrder( gf.stimIdx, 2));
        gf.mask    = gf.maskCases( gf.stimOrder( gf.stimIdx, 3));
        gf.stimIdx = gf.stimIdx + 1;
        
        gf.formants = eval(sprintf('gf.sound%d',gf.side));
        

        
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
        
        %calculatePitch                
        if gf.pInd == 0,
            gf.pitchInd = randperm(length(gf.pitchRange));
        end
        
        gf.pInd  = gf.pInd + 1;              
        gf.pitch = gf.pitchRange(gf.pitchInd(gf.pInd));
        
        if gf.pInd == length(gf.pitchRange),
            gf.pInd = 0;
        end
        
        % Compensate for slight differences in loudness
        if ismember(gf.formants,[936,1551,2975,4263],'rows'), gf.atten = gf.atten - 5; end
%         if ismember(gf.formants,[460 1105 2857 4205],'rows'), gf.atten = gf.atten - 5; end        
        if ismember(gf.formants,[730 2058 2857 4205],'rows'), gf.atten = gf.atten - 2; end
        
        
        % Generate sound        
        sound  = ComputeTimbreStim(gf.formants);             % create vowel
        isi    = zeros(1, ceil(gf.isi/1000 * gf.fStim));     % add interstimulus interval  
        holdOK = length(sound) + length(isi);                % point in stimulus that the ferret must hold to        
        sound  = [sound, isi, sound];                        % create two vowels with two intervals
        
        % Calibrate sounds
        sound0 = conv(sound, gf.fltL.flt, 'same');
        sound1 = conv(sound, gf.fltR.flt, 'same');
        
        % Generate background noise
        if isfield(gf,'continuousNoise'),
            DA.SetTargetVal( sprintf('%s.contNoise', gf.stimDevice), 1);  
            DA.SetTargetVal( sprintf('%s.contNoiseAttn', gf.stimDevice), 10^(-(gf.noiseAttn/20)));            
            DA.SetTargetVal( sprintf('%s.noiseAmp', gf.stimDevice), 0.3);
           
        else            
            noise  = rand(size(sound));
            noise  = noise .* 10^(-(gf.noiseAttn/20));
            noise  = envelope(noise,ceil(0.005.*gf.fStim));
            
            % Assign signal and noise to speakers depending on mask case
            switch gf.mask,
                case 1              % Both left and right (default for case without masking)
                    sound0 = noise + sound0;
                    sound1 = noise + sound1;
                    
                case 2              % Signal left; noise right
                    sound0 = sound0;
                    sound1 = noise;
            
                case 3              % Signal right; noise left
                    sound0 = noise;
                    sound1 = sound1;
            end
            
             
            % Open new performance graph if not open
%             if isempty( findobj(0,'type','figure','name','SNR performance')),
%                 figure('color','k','name','SNR performance')
%                 gf.SNRperformance = gf.attenRange .* 0;
%                 
%                 vowelPa = -10.^(-(65 - gf.attenRange) /20);
%                 noisePa = -10.^(-65 /20);
%                 
%                 gf.SNRrange = -20 *log10(vowelPa / noisePa);
%             end
%             
%             gf.SNR = -20 * log10( 10^(-(65 - gf.atten) /20) - 10^(-(65/20)));
        end
        
        % Calculate timing information
        playDelay = gf.holdSamples - holdOK;
        refractS  = playDelay + length(sound) + ceil(gf.refractoryTime * gf.fStim);
        absentS   = ceil(gf.absentTime * gf.fStim);
        

        
%         sound0 = sound; %calibrateSignal(sound, gf.calibDir, 1);
%         sound1 = sound; %calibrateSignal(sound, gf.calibDir, 1);
        
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
            
            switch gf.mask
                case 1
                    comment = 'Sound + Noise from both speakers';
                case 2
                    comment = 'Sound-Left,  Noise-Right';
                case 3
                    comment = 'Sound-Right, Noise-Left';
            end
            comment = strcat(comment, '     LED flashing, waiting for center lick');
            
        else
            DA.SetTargetVal( sprintf('%s.flashEnable',      gf.stimDevice), 0);              
            
            if  gf.correctionTrial == 1;
                DA.SetTargetVal( sprintf('%s.repeatPlay', gf.stimDevice), isfield(gf,'correctionTrialRepeat')); 
            end
            %DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 0);                 % Disable constant LED in hold time
            %DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 0);                 % Disable sound in hold time
                                                            
%             gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.CenterLickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
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

%Check outputs
% checkOutputs([4 5 6 7]);                                %See toolbox for function

%Update timeline
updateTimeline(20)


catch err
    
    err 
    keyboard
    
end

      