function level6_WE

% White Elephant Level 8:
% Two or more stimuli are presented
% Presentations are limited to hold times (i.e. no repetition)
% Mistakes lead to time outs

global DA gf h
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles

try

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));


%Run case
switch gf.status
    
    % __________________________________________________________________________
    case('PrepareStim')
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        calculateHoldTimes
        calculateAtten
                        
        % CHOOSE SPEAKERS
        if gf.rlTrialNo>size(gf.rlp,1)
            gf.rlTrialIdx=randperm(size(gf.rlp,1));
            gf.rlTrialNo=1;
            gf.refChoice(1,1:gf.nRefSpks)=gf.rlp(gf.rlTrialIdx(gf.rlTrialNo),1:gf.nRefSpks);
            gf.tarChoice=gf.rlp(gf.rlTrialIdx(gf.rlTrialNo),gf.nRefSpks+1);
            gf.rlTrialNo=gf.rlTrialNo+1;
        else
            gf.refChoice(1,1:gf.nRefSpks)=gf.rlp(gf.rlTrialIdx(gf.rlTrialNo),1:gf.nRefSpks);
            gf.tarChoice=gf.rlp(gf.rlTrialIdx(gf.rlTrialNo),gf.nRefSpks+1);
            gf.rlTrialNo=gf.rlTrialNo+1;
        end
        
        
        % Generate sound
        % interval=0.02; % interval between reference and target
        gap=1-(gf.refDuration*gf.nRefSpks)-gf.tarDuration;    % interval between repeated stimuli made so total stim is 1s
        for ii=1:gf.nRefSpks
            refSound(ii,:)=[(zeros(1,ceil(gf.refDuration*gf.fStim*(ii-1)))),rand(1,ceil(gf.refDuration*gf.fStim)),(zeros(1,ceil(gf.refDuration*gf.fStim*(gf.nRefSpks-ii)))),zeros(1,ceil((gf.tarDuration+gap)*gf.fStim))];  % create reference sound
        end
        tarSound=[zeros(1,ceil((gf.refDuration*gf.nRefSpks)*gf.fStim)),rand(1,ceil(gf.tarDuration*gf.fStim)),zeros(1,ceil(gap*gf.fStim))];  % create target sound
        if length(tarSound)<length(refSound)
            refSound=refSound(:,1:size(tarSound,2));
        else
            tarSound=tarSound(:,1:size(refSound,2));
        end
        
        gf.silence=zeros(1,size(refSound,2));% Fill unused speakers with silence
        
        if gf.refChoice(1)>gf.tarChoice
            gf.side=2;
        elseif gf.refChoice(1)<gf.tarChoice
            gf.side=8;
        end
        
        gf.tarIdx=[2,8];
        
        
        % Apply the attenuation
        for ii=1:gf.nRefSpks
            refSound(ii,:) = refSound(ii,:) .* 10^(-(gf.atten/20));
        end
        tarSound = tarSound .* 10^(-(gf.atten/20));
        
        holdOK      = ((gf.refDuration*gf.nRefSpks)+(gf.tarDuration/2))*gf.fStim;                % point in stimulus that the ferret must hold to
        for ii=2:8
            silentSpks=strcat('%s.speaker',num2str(ii));
            silencefiller=DA.WriteTargetVEX(sprintf(silentSpks, gf.stimDevice), 0, 'F32', gf.silence); % fill unused speakers with silence
            %  end
        end
        
        % Calculate timing information
        playDelay = gf.holdSamples - holdOK;
        refractS  = playDelay + length(refSound) + ceil(gf.refractoryTime * gf.fStim);
        absentS   = ceil(gf.absentTime * gf.fStim);
        
        % Calibrate for white elephant
        for ii=1:gf.nRefSpks
            refSoundFilt(ii,:) = WEcalibration(refSound(ii,:), gf.calibDir, gf.refChoice(ii));
        end
        
        % Write sound to buffers
        for ii=1:gf.nRefSpks
            refSpeaker{ii} = strcat('%s.speaker',num2str(gf.refChoice(ii)));
        end
        tarSpeaker = strcat('%s.speaker',num2str(gf.tarChoice));
        
        for ii=1:gf.nRefSpks
            DA.WriteTargetVEX(sprintf(refSpeaker{ii}, gf.stimDevice), 0, 'F32', refSound(ii,:)); % Write to reference speaker
        end
        DA.WriteTargetVEX(sprintf(tarSpeaker, gf.stimDevice), 0, 'F32', tarSound); % Write to target speaker
        
        % Set length of time to play noise during timeout
        DA.SetTargetVal( sprintf('%s.noiseDuration', gf.stimDevice), gf.noiseDuration);
        

        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 1);
        DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
        
        % Set timing information on TDT
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(refSound));
        DA.SetTargetVal( sprintf('%s.firstNPoints',     gf.stimDevice),(length(refSound) + gf.repInterval*gf.fStim)/gf.fStim*1000);
        DA.SetTargetVal( sprintf('%s.repNPoints',       gf.stimDevice), length(refSound) + gf.repInterval*gf.fStim);
%         DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);      %%%%%% ST Mod
%         DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), absentS);             %%%%%% ST Mod
%         DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), playDelay);           %%%%%% ST Mod
%         DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), refractS);            %%%%%% ST Mod
        
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.recDevice), length(refSound));       %%%%%% ST Mod
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.recDevice), gf.holdSamples);         %%%%%% ST Mod
        DA.SetTargetVal( sprintf('%s.absentSamps',      gf.recDevice), absentS);                %%%%%% ST Mod
        DA.SetTargetVal( sprintf('%s.playDelay',        gf.recDevice), playDelay);              %%%%%% ST Mod
        DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.recDevice), refractS);               %%%%%% ST Mod               
        
        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.centerEnable',     gf.recDevice), 1);                      %%%%%% ST Mod
                
        % Update online GUI
        set(h.status,     'string',sprintf('%s',gf.status))
        set(h.side,       'string',num2str( gf.side))
        set(h.pitch,      'string','N/A')
        set(h.holdTime,   'string',sprintf('%.0f ms', gf.holdTime))
        set(h.currentStim,'string',num2str(gf.tarChoice))
        set(h.atten,      'string',sprintf('%.1f dB', gf.atten))
        set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
        
        
        
        if gf.refChoice==gf.tarChoice
            gf.status='PrepareStim';
        else
            gf.status='WaitToPlay';
        end
        
        
        
        % Play Sound______________________________________________________% _ST MOD
        
    case('WaitToPlay')
                
        DA.SetTargetVal(sprintf('%s.led1in',gf.recDevice),1);                   %%%%%% ST Mod
                
        if DA.GetTargetVal(sprintf( '%s.play',  gf.recDevice));
           
            DA.SetTargetVal(sprintf( '%s.play',  gf.stimDevice), 0);
            DA.SetTargetVal(sprintf( '%s.play',  gf.stimDevice), 1);
            pause(0.010) % This is me being hypocritical ;)
                        
            gf.status = 'WaitForStart';
        end
        
        
        % Center Response__________________________________________________________
    case('WaitForStart')
        
        
        for ii = 1 : 2
            checkPeri(ii) = DA.GetTargetVal( sprintf( '%s.lick%d',  gf.recDevice, gf.tarIdx(ii)));  %%%%%% ST Mod
        end
        if any(checkPeri)
            pause(1)                                                        % ST MOD - Can we amend this to stop the program pausing
        else
            
            % Reset the timeout player
            gf.timeoutPlayed=0;
            silenceTO=zeros(1,round(((gf.noiseDuration/1000))*gf.fStim));
            DA.WriteTargetVEX(sprintf('%s.speaker1', gf.stimDevice), 0, 'F32', silenceTO); % clear the tone
            
%             % Enable center spout
%             DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
%             DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time
%             %
            centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.lick1',gf.recDevice));   %%%%%% ST Mod
            
            %If no start
            if centerLick == 0;
                
                %Flash LED
                DA.SetTargetVal(sprintf('%s.led1in',gf.recDevice),1);                   %%%%%% ST Mod
                comment = 'LED flashing, waiting for center lick';
                
            else
                DA.SetTargetVal( sprintf('%s.led1in',           gf.recDevice), 0);           %%%%%% ST Mod
                DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);     % Disable OpenEx driven sound repetition
                DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);     % Disable Matlab driven
                
                
                %%%%%% ST MOD 19-9-13
                gf.startTrialTime = DA.GetTargetVal(sprintf('%s.playTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
                gf.status            = 'WaitForResponse';
                
                % Reward at center spout
                if gf.centerRewardP > rand(1),
                    gf.centerReward = 1;
                    comment         = 'Center spout licked - giving reward';
                    
                    valve_WE(1,100,1)
                    
                else
                    gf.centerReward = 0;
                    comment         = 'Center spout licked - no reward';
                end
            end
            
            %Update GUI
            set(h.status,'string',gf.status);
            set(h.comment,'string',comment);
        end
        
        % Peripheral Response______________________________________________________
    case('WaitForResponse')
        
        %%%%%% ST Mod
%         if gf.useLEDs,
%             DA.SetTargetVal( sprintf('%s.LEDthreshold',     gf.stimDevice), 0.01);          % Enable LEDs
%         end
        
        if gf.singPres==1 && gf.correctionTrial==0
            DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 0);                            % Matlab driven sound repetition
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.recDevice), 0);     %%%%% ST Mod            % Reset counter for center spout...
        else
            
            timeNow = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice))./gf.fStim;
            
            if (timeNow - gf.startTrialTime) > 0.4, %%%%%% ST Mod    
                DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 1);                 % Matlab driven sound repetition
                DA.SetTargetVal( sprintf('%s.centerEnable',      gf.recDevice), 0); %%%%% ST Mod
            end
        end
        
        
        % Check for peripheral response
        pResp = zeros(2,1);
        gf.tarIdx=[2,8];
        
        for ii = 1 : 2
            pResp(ii) = DA.GetTargetVal( sprintf( '%s.lick%d',  gf.recDevice, gf.tarIdx(ii))); %%%%%% ST Mod
        end
        
        
        % Separate response types
        errResp             = pResp;
        errResp(gf.tarIdx==gf.side) = [];                   % Remove index of correct response
        corrResp            = pResp(gf.tarIdx==gf.side);
        
        % If no response
        if ~sum(pResp)
            
            timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
            timeElapsed    = timeNow - gf.startTrialTime;
            timeRemaining  = gf.abortTrial - timeElapsed;
            
            comment = sprintf('Awaiting response: \nTime remaining %0.1f s', timeRemaining);
            
            % Check response countdown
            if timeRemaining <= 0,
                
%                 % Disable LEDs                                                %%%%%% ST Mod
%                 DA.SetTargetVal( sprintf('%s.LEDthreshold', gf.stimDevice), 99);
                
                %Log aborted response
                gf.responseTime = -1;
                response        = -1;
                logTrial(gf.centerReward, response)                   %See toolbox (-1 = aborted trial)
                
                % Update perfomance graph
                updatePerformance(3)             % code 3 = abort trial
                
                gf.status         = 'PrepareStim';
            end
            
            
        else % If response
            
            DA.SetTargetVal( sprintf('%s.LEDthreshold', gf.stimDevice), 99);              % Disable LEDs
            
            
            % If animal responds correctly
            if corrResp
                DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
                DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);
                
                if gf.side==2 || gf.side == 8,   %%%%%% ST Mod
                    gf.resp= gf.side;            %%%%%% ST Mod
                end                              %%%%%% ST Mod
                
                %Log response
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.recDevice, gf.side)) ./ gf.fRec; %%%%%% ST Mod
                
                gf.LeftRight=[1,0]; % reversed because if tarChoice =2 we need response to the right (1) not left (0)
                response        = gf.LeftRight(gf.tarIdx==gf.side);
                logTrial(gf.centerReward, response)                   %See toolbox
                
                valve_WE(gf.side,gf.rewardTime,1)
                comment    = sprintf('Correct response at speaker %d - giving reward', gf.side);
                
                gf.status  = 'PrepareStim';
                
                % Update perfomance graph
                if response==1
                    updatePerformance(2)             % code 2 = right correct
                elseif response==0
                    updatePerformance(4)             % code 4 = left correct
                end
                
                % If animal responds incorrectly
            elseif any(errResp)
                
                gf.LeftRight=[1,0]; % reversed because if tarChoice =2 we need response to the right (1) not left (0)
                if gf.side==2;
                    gf.resp=8;
                elseif gf.side==8
                    gf.resp=2;
                end
                
                response  = gf.LeftRight(gf.tarIdx~=gf.side);
                
                
                %Log response
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.recDevice, gf.tarIdx(gf.tarIdx~=gf.side))) ./ gf.fRec;    %%%%%% ST Mod
                
                comment    = sprintf( 'Incorrect response at speaker %d', gf.tarIdx(pResp == 1));
                                
                logTrial(gf.centerReward, response)                   %See toolbox                               
                
                % Update perfomance graph
                if response==1
                    updatePerformance(1)             % code 1 = right incorrect
                elseif response==0
                    updatePerformance(5)             % code 5 = left incorrect
                end
                
                
                % Disable center spout
                DA.SetTargetVal( sprintf('%s.centerEnable', gf.recDevice), 0); %%%%%% ST Mod
                
                gf.status  = 'timeout';
                
            end                        
        end
        
        % Timeout _________________________________________________________________
        
    case('timeout')
        DA.SetTargetVal( sprintf('%s.led1in',           gf.recDevice), 0);                   %%%%%% ST Mod        
        DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
        DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);
        
        timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
        timeElapsed    = timeNow - gf.responseTime;       
        timeRemaining  = gf.timeoutDuration - timeElapsed;
        
        comment = sprintf('Timeout: \nTime remaining %0.1f s', timeRemaining);
        set(h.comment,'string',comment);
        
        % Play noise
        if gf.timeoutPlayed==0
            
            
            noise=tone(gf.fStim,5000,gf.noiseDuration/500)';
            noise=noise .* 10^(-(30/20));
            DA.SetTargetVal(sprintf('%s.TO_Samps', gf.stimDevice), length(noise)); % Play from central speaker
            DA.WriteTargetVEX(sprintf('%s.speaker1', gf.stimDevice), 0, 'F32', noise'); % Play from central speaker                                         
            
            DA.SetTargetVal(sprintf('%s.manualTO',gf.stimDevice),1);
            DA.SetTargetVal(sprintf('%s.manualTO',gf.stimDevice),0);
            
            gf.timeoutPlayed=1;
        end
        
        
        if timeRemaining <= 0,
            
            % Go straight to waiting, do not prepare another stimulus.
            % Use the same stimulus in a correction trial until the
            % correct response is made.
            % Repeat trial
            % DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice),0);
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.recDevice), 1); %%%%%% ST Mod
            gf.correctionTrial = 1;
            
            % Update trial number
            set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
            gf.status  = 'WaitToPlay';
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
end

%Update timeline
updateTimeline_WEb(20)


catch err
    err
    keyboard
end
    

