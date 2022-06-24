function level10_WE

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



%Check sensor inputs
% bits = [0       2       1];
% vars = {'left','center','right'};
%
% if iscom(DA) == 1,                                 % Only check sensors if TDT connected
%     checkSensors(bits, vars);                      % See toolbox for function
% end

%Run case
switch gf.status
    
    % __________________________________________________________________________
    case('PrepareStim')
        
        % Identify as new trial
        gf.correctionTrial = 0;
          gf.nCT=0;
        
        calculateHoldTimes
       % calculateAtten
        
        %  gf.atten = 18;         % temporary compensation for new speakers until something better arrrives
        
        if gf.extraCentral & ~gf.doOnce
            gf.rlp=[gf.rlp;4,5;5,6;6,5;5,4;4,5;5,6;6,5;5,4];
            gf.rlTrialIdx=randperm(size(gf.rlp,1));
            gf.doOnce=1;
        end
        
        
        
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
        stimSound=rand(gf.nRefSpks+1,floor(gf.fStim)*3);
        
        % Filter for the Spkrs Low Pass (22 kHz)
        for ii=1:size(stimSound,1)
            stimSound(ii,:)=filter(gf.SpkrLowPass.ferretSpkrLowPass,stimSound(ii,:));
        end
        
        % Calibrate for white elephant
        for ii=1:gf.nRefSpks
            stimSound(ii,:) = WEcalibration(stimSound(ii,:), gf.calibDir, gf.refChoice(ii));
        end
        stimSound(gf.nRefSpks+1,:) = WEcalibration(stimSound(gf.nRefSpks+1,:), gf.calibDir, gf.tarChoice);
        
        refD=floor((gf.refDuration*gf.fStim)); % ref duration
        tarD=floor((gf.tarDuration*gf.fStim)); % tar duration
        startRef1=floor(0.5*gf.fStim); % start point (in the middle of the noise)
        startRef2=startRef1+floor(gf.fStim);
        startTar=startRef2+floor(gf.fStim);
        refSamps(1,:)=stimSound(1,startRef1:startRef1+refD-1); % get the samples
        refSamps(2,:)=stimSound(2,startRef2:startRef2+refD-1); % get the samples
        tarSamps=stimSound(gf.nRefSpks+1,startTar:startTar+tarD-1); % get the samples
        for ii=1:size(refSamps,1) % envelope the samples
            refSamps(ii,:)=envelopeKW(refSamps(ii,:),5,gf.fStim);
        end
        tarSamps=envelopeKW(tarSamps,5,gf.fStim);
        
        % create the stimulus
        gapp=1-(gf.refDuration*gf.nRefSpks)-gf.tarDuration-(gf.interval*(gf.nRefSpks));    % interval between repeated stimuli made so total stim is 1s
        for ii=1:gf.nRefSpks % create reference sound
            refSound(ii,:)=[(zeros(1,floor(gf.refDuration*gf.fStim*(ii-1)))),...
                zeros(1,floor(gf.interval*gf.fStim*(ii-1))),...
                refSamps(ii,:),...
                zeros(1,floor(gf.interval*gf.fStim)),...
                (zeros(1,floor(gf.refDuration*gf.fStim*(gf.nRefSpks-ii)))),...
                zeros(1,floor(gf.interval*gf.fStim*(gf.nRefSpks-ii))),...
                zeros(1,floor((gf.tarDuration+gapp)*gf.fStim))];
        end
        tarSound=[zeros(1,floor((gf.refDuration*gf.nRefSpks)*gf.fStim)),...
            zeros(1,floor(gf.interval*gf.fStim*2)),...
            tarSamps,...
            zeros(1,floor(gapp*gf.fStim))];  % create target sound
        
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
        
        holdOK      = ((gf.refDuration*gf.nRefSpks)+(gf.tarDuration/2)+gf.interval)*gf.fStim;
               % point in stimulus that the ferret must hold to
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NB interval added in%%%%%%%
               %%%%%%%%%%%%%%%%%%%%%% 27/01/2015%%%%%%%%%%%%%%%%%%%%%%%%%%%

               
        for ii=min(gf.rTar):max(gf.lTar)
            silentSpks=strcat('%s.speaker',num2str(ii));
            silencefiller=DA.WriteTargetVEX(sprintf(silentSpks, gf.stimDevice), 0, 'F32', gf.silence); % fill unused speakers with silence
            %  end
        end
        
        % Calculate timing information
        playDelay = gf.holdSamples - holdOK;
        refractS  = playDelay + length(refSound) + ceil(gf.refractoryTime * gf.fStim);
        absentS   = ceil(gf.absentTime * gf.fStim);
       
        
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
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), gf.holdSamples);
        DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), absentS);
        DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), playDelay);
        DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), refractS);
        
        
        % Enable / Disable Circuit components
        DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1);
        
        
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
            gf.status='WaitForStart';
        end
        
        
        % Center Response__________________________________________________________
    case('WaitForStart')
        
        
        for ii = 1 : 2
            checkPeri(ii) = DA.GetTargetVal( sprintf( '%s.lick%d',  gf.stimDevice, gf.tarIdx(ii)));
        end
        if any(checkPeri)
            pause(1)
        else
            
            % Reset the timeout player
            gf.timeoutPlayed=0;
            silenceTO=zeros(1,round(((gf.noiseDuration/1000))*gf.fStim));
            DA.WriteTargetVEX(sprintf('%s.speaker1', gf.stimDevice), 0, 'F32', silenceTO); % clear the tone
            
            % Enable center spout
            DA.SetTargetVal( sprintf('%s.ledEnable',        gf.stimDevice), 1);                 % Enable constant LED in hold time
            DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time
            %
            centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.lick1',gf.stimDevice));
            
            %If no start
            if centerLick == 0;
                
                %Flash LED
                DA.SetTargetVal(sprintf('%s.led1in',gf.stimDevice),1);
                comment = 'LED flashing, waiting for center lick';
                
            else
                DA.SetTargetVal( sprintf('%s.led1in',      gf.stimDevice), 0);
                DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);     % Disable OpenEx driven sound repetition
                DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);     % Disable Matlab driven
                
                gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lick1Time',gf.stimDevice)) ./ gf.fStim;  %Open Ex
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
        
        if gf.useLEDs,
            DA.SetTargetVal( sprintf('%s.LEDthreshold',     gf.stimDevice), 0.01);          % Enable LEDs
        end
        
        if gf.singPres==1 && gf.correctionTrial==0
            DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 0);                 % Matlab driven sound repetition
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
       elseif gf.correctionTrial==1 && gf.nSingPres>gf.nCT
            DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 0);                 % Matlab driven sound repetition
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...

        else
            timeNow=DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice))./gf.fStim;
            if timeNow-gf.startTrialTime > 0.9
                DA.SetTargetVal( sprintf('%s.repeatPlay',        gf.stimDevice), 1);                 % Matlab driven sound repetition
                DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);
            end
        end
        
        
        % Check for peripheral response
        pResp = zeros(2,1);
        gf.tarIdx=[2,8];
        
        for ii = 1 : 2
            pResp(ii) = DA.GetTargetVal( sprintf( '%s.lick%d',  gf.stimDevice, gf.tarIdx(ii)));
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
                
                % Disable LEDs
                DA.SetTargetVal( sprintf('%s.LEDthreshold', gf.stimDevice), 99);
                
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
                
                if gf.side==2;
                    gf.resp=2;
                elseif gf.side==8
                    gf.resp=8;
                end
                
                %Log response
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.stimDevice, gf.side)) ./ gf.fStim;
                
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
                response        = gf.LeftRight(gf.tarIdx~=gf.side)
                
                %%%% ST Modification (Added to allow code to run: 26 Nov
                %%%% 2012 AM.
                %Log response
                gf.responseTime = DA.GetTargetVal(sprintf('%s.lick%dtime',gf.stimDevice, gf.tarIdx(gf.tarIdx~=gf.side))) ./ gf.fStim;
                
                comment    = sprintf( 'Incorrect response at speaker %d', gf.tarIdx(pResp == 1));
                
                
                logTrial(gf.centerReward, response)                   %See toolbox
                
                
                
                % Update perfomance graph
                if response==1
                    updatePerformance(1)             % code 1 = right incorrect
                elseif response==0
                    updatePerformance(5)             % code 5 = left incorrect
                end
                
                
                % Disable center spout
                DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 0);
                
                gf.status  = 'timeout';
                
            end
            
            
        end
        
        % Timeout _________________________________________________________________
        
    case('timeout')
        
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
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 1);
            gf.correctionTrial = 1;
              gf.nCT=gf.nCT+1;
            
            % Update trial number
            set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))
            gf.status  = 'WaitForStart';
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        
end



%Check outputs
%checkOutputs_WE(10);                                %See toolbox for function

%Update timeline
updateTimeline_WE(20)




