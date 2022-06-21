function level99_WE

% White Elephant Level 99:
% For getting spatial receptive fields - plays 100 ms noise bursts from
% speakers 2-8 pseudo-randomly.  1 stimulus per second.  Rewards every 3
% seconds.  Looks for ferrets at centre spout, if away for more than 300
% ms then does not play a sound and waits fro presence of ferret again.  

global DA gf h
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

try
    %Run case
    switch gf.status
        
        %__________________________________________________________________________
        case('PrepareStim')
            
            % Identify as new trial
            gf.correctionTrial = 0;
           
            % Clear speakers
            if gf.firstTrial~=1;
                DA.WriteTargetVEX(sprintf('%s.speaker%d', gf.stimDevice, gf.lastTarget), 0, 'F32', zeros(1,2.4e5));
            end
            
           % Calculate hold range, attenuation & pitch
       %     calculateHoldTimes % goes through a pseudo-random cycle to pick from the holdtime range provided
            calculateAtten % goes through a pseudo-random cycle to pick from the attenuation range provided
            
            % Generate sound     % Generate sound
            sound       = rand(ceil(gf.duration/1000 * gf.fStim), 1);
%             repInt=zeros(gf.repInterval*round(gf.fStim),1);
%             sound=[sound;repInt];
            sound       = sound .*10^(-(gf.atten/20));  % attenuate the sound!
            sound       = envelope(sound, ceil(5e-3*gf.fStim));
            holdOK      = 0;
            silence     = zeros(size(sound));
            
            
            % Calculate timing information
            playDelay = gf.holdSamples - holdOK;
            refractS  = playDelay + length(sound) + ceil(gf.refractoryTime * gf.fStim);
            absentS   = ceil(gf.absentTime * gf.fStim);
            
            % Choose speaker
            if gf.spkrTrialIdx < length(gf.spkrTrialList)
                gf.spkrTrialIdx = gf.spkrTrialIdx + 1;
            else % reset trial index if necessary
                gf.spkrTrialList = [randperm(gf.nSpeakers),randperm(gf.nSpeakers),randperm(gf.nSpeakers)];
                gf.spkrTrialList = gf.spkrTrialList( randperm( length(gf.spkrTrialList)));
                gf.spkrTrialIdx  = 1;
            end
            gf.spkrIdx = gf.spkrTrialList(gf.spkrTrialIdx);
            gf.spkr    = gf.speakerIndices(gf.spkrIdx); % speaker in numbers
            gf.spkrPos = gf.speakerPositions(gf.spkrIdx); % speaker in degrees
            gf.lastTarget=gf.spkr;
            
            
            % Calibrate for white elephant
            sound = WEcalibration(sound, gf.calibDir, gf.spkr);
            
            % Write sound to buffer
            DA.WriteTargetVEX(sprintf('%s.speaker%d', gf.stimDevice, gf.spkr), 0, 'F32', sound');
            
            
            % Enable / Disable Circuit components
            DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1); % enable centre spout
            DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0); % Disable OpenEx driven sound repetition
            DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0); % Disable Matlab driven sound repetition
            
            
            % Set length of time to play noise during timeout
            DA.SetTargetVal( sprintf('%s.noiseDuration', gf.stimDevice), gf.noiseDuration);
            
            % Set timing information on TDT
            DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));
            DA.SetTargetVal( sprintf('%s.repNPoints',       gf.stimDevice), length(sound));
            
            DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);
            DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), absentS);
            DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), playDelay);
            DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), refractS);
            
            % Update online GUI
            set(h.status,     'string',sprintf('%s',gf.status))
            set(h.speaker,    'string',num2str( gf.spkr))
            set(h.position,   'string',sprintf('%d', gf.spkrPos))
            set(h.holdTime,   'string',sprintf('%.0f ms', gf.holdTime))
            set(h.editAtten,      'string',sprintf('%.0f', gf.atten))
            set(h.editRewardTime, 'string',sprintf('%.0f', gf.rewardTime))
            set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
            
            
            
            gf.status = 'WaitForStart';
            
            
            % Center Response__________________________________________________________
        case('WaitForStart')
                       
            DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
            DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time
            
            centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.lick1',gf.stimDevice));
          
            
            
            %If no start
            if centerLick == 0;
                
                %Flash LED
                DA.SetTargetVal(sprintf('%s.led1in',gf.stimDevice),1);
                comment = 'LED flashing, waiting for center lick';
                
            else
                if gf.firstTrial==1
                    gf.centerReward = 1;
                    comment         = 'Center spout licked - giving reward';
                    valve_WE(1,150,1)
                end
                DA.SetTargetVal( sprintf('%s.led1in',      gf.stimDevice), 0);
                if gf.correctionTrial==1 & gf.nSingPres<=gf.nCorTrials % If correction trial repeat the play
                    DA.SetTargetVal( sprintf('%s.repeatPlayEnable',        gf.stimDevice), 1); % TDT driven sound repetition
                    DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice),1);     % Enable Matlab driven
                else
                    DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);     % Disable OpenEx driven sound repetition
                    DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);     % Enable Matlab driven
                end
                gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lick1Time',gf.stimDevice)) ./ gf.fStim;  %Open Ex
                
                
%            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
%            timeElapsed    = timeNow - gf.startTrialTime;
           gf.counter=gf.counter+1;
%            timeRemaining  = 3 - timeElapsed;
                         
                % Reward at center spout every 3 seconds
               if gf.counter>=3
                    gf.centerReward = 1;
                    comment         = 'Center spout licked - giving reward';
                    valve_WE(1,150,1)
                    gf.counter=0;
               end
                
                gf.status            = 'PrepareStim';
                gf.firstTrial=0;
            end
            
%             %Update GUI
%             set(h.status,'string',gf.status);
%             set(h.comment,'string',comment);
%             
%             
%             % Peripheral Response______________________________________________________
%         case('WaitForResponse')
%             
%             DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
%             
%             if gf.useLEDs && gf.correctionTrial==1
%                 DA.SetTargetVal( sprintf('%s.LEDthreshold',     gf.stimDevice), 0.01);          % Enable LEDs
%             end
%             
%             timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
%             timeElapsed    = timeNow - gf.startTrialTime;
%             if  gf.correctionTrial == 1 %&& timeElapsed > gf.duration/1000
%                 DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
%             end
%             
%             % Check for peripheral response
%             pResp = zeros(gf.nSpeakers,1);
%             
%             for i = 1 : gf.nSpeakers
%                 pResp(i) = DA.GetTargetVal( sprintf( '%s.lick%d',  gf.stimDevice, gf.speakerIndices(i)));
%             end
%             
%             % Separate response types
%             errResp             = pResp;
%             errResp(gf.spkrIdx) = [];                   % Remove index of correct response
%             corrResp            = pResp(gf.spkrIdx);
%             
%             
%             % If no response
%             if ~sum(pResp),
%                 
%                 % timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
%                 % timeElapsed    = timeNow - gf.startTrialTime;
%                 %if timeElapsed>
%                 timeRemaining  = gf.abortTrial - timeElapsed;
%                 
%                 comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);
%                 
%                 % Check response countdown
%                 if timeRemaining <= 0,
%                     
%                     % Disable LEDs
%                     DA.SetTargetVal( sprintf('%s.LEDthreshold', gf.stimDevice), 99);
%                     
%                     %Log aborted response
%                     gf.responseTime = -1;
%                     response        = -1;
%                     logTrial(gf.centerReward, response)                   %See toolbox (-1 = aborted trial)
%                     
%                     % Update perfomance graph
%                     updatePerformance('abort')
%                     
%                     gf.status         = 'PrepareStim';
%                 end
%                 
%                 %If response
%             else
%                 
%                 % Disable LEDs
%                 DA.SetTargetVal( sprintf('%s.LEDthreshold', gf.stimDevice), 99);
%                 
%                 if corrResp,
%                     
%                     %Log response to right
%                     gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.stimDevice, gf.spkr)) ./ gf.fStim;
%                     response        = gf.spkr;
%                     logTrial(gf.centerReward, response)                   %See toolbox
%                     
%                     valve_WE(gf.spkr, gf.rewardTime, 1)
%                     comment    = sprintf('Correct response at speaker %d - giving reward', gf.spkr);
%                     % Enable / Disable Circuit components
%                     DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
%                     DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);
%                     gf.status  = 'PrepareStim';
%                     
%                     % Update perfomance graph
%                     updatePerformance( sprintf('Correct_%d',gf.spkrPos))
%                     
%                     
%                     
%                     
%                 elseif any(errResp)
%                     
%                     gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.stimDevice, gf.speakerIndices(pResp==1))) ./ gf.fStim;  %Open Ex
%                     response        = gf.speakerIndices(pResp==1);
%                     gf.respTO=response;
%                     logTrial(gf.centerReward, response)                   %See toolbox
%                     
%                     % Give timeout
%                     comment    = sprintf( 'Incorrect response at speaker %d - timeout', gf.spkr);
%                     
%                     
%                     DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),0);
%                     DA.SetTargetVal(sprintf('%s.timeout',gf.stimDevice),1);
%                     
%                     % Disable center spout
%                     DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 0);
%                     % Enable / Disable Circuit components
%                     DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
%                     DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);
%                     
%                     % Update perfomance graph
%                     updatePerformance( sprintf('Incorrect_%d',gf.speakerPositions(pResp == 1)))
%                     gf.status  = 'timeout';
%                     
%                 end
%             end
%             
%             %Update GUI
%             set(h.status,'string',gf.status);
%             set(h.comment,'string',comment);
%             
%             % Timeout _________________________________________________________________
%             
%         case 'timeout'
%             
%             DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 0);                 % Matlab driven sound repetition
%             
%             timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
%             timeElapsed    = timeNow - gf.responseTime;
%             %         if gf.respTO==3 & ~isempty(strfind(gf.saveDir,'Kerry'))
%             %             timeoutDuration=10;
%             %         else
%             timeoutDuration=gf.timeoutDuration;
%             %         end
%             timeRemaining  = timeoutDuration - timeElapsed;
%             
%             comment = sprintf('Timeout: \nTime remaining %0.1f s', timeRemaining);
%             set(h.comment,'string',comment);
%             
%             % Play noise
%             if timeRemaining > (timeoutDuration - gf.noiseDuration/1000),
%                 
%                 noise = rand(round(gf.fStim,1));
%                 noise=noise .* 10^(-(5/20)); % attenuate the noise slightly
%                 
%                 DA.SetTargetVal(sprintf('%s.TO_Samps', gf.stimDevice), length(noise)); % Play from central speaker
%                 DA.WriteTargetVEX(sprintf('%s.speaker1', gf.stimDevice), 0, 'F32', noise'); % Play from central speaker
%                 
%                 DA.SetTargetVal(sprintf('%s.manualTO',gf.stimDevice),1);
%                 DA.SetTargetVal(sprintf('%s.manualTO',gf.stimDevice),0);
%             end
%             
%             if timeRemaining <= 0,
%                 
%                 % Go straight to waiting, do not prepare another stimulus.
%                 % Use the same stimulus in a correction trial until the
%                 % correct response is made.
%                 
%                 
%                 gf.correctionTrial = 1;
%                 gf.nCorTrials=gf.nCorTrials+1;
%                 
%                 
%                 
%                 % Reset enable parameter tags for correction trial
%                 DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 1);
%                 
%                 % Update trial number
%                 set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
%                 gf.status          = 'WaitForStart';
%             end
%             
%             set(h.status,'string',gf.status);
%     end
%     
%     %Check outputs
%     % checkOutputs_WE(10);                                %See toolbox for function
%     
%     %Update timeline
%     updateTimeline_WE(20)
    
catch err
end


