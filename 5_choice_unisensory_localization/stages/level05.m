function level05

% Level 5:
% Repeat play
% Stimulus duration not variable
% Correction trials

global DA gf h saveData
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles*

%(*ideally i would get rid of this and just pass handles but it doesn't seem to work)

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

% Set ongoing parameters
tags = {'LED_bgnd_V','Spkr_bgnd_V'};


for i =1 : numel(tags)
    
    eval(sprintf('val = gf.%s;', tags{i}));
    DA.SetTargetVal(sprintf('%s.%s', gf.stimDevice,tags{i}), val);
end

% Update timeline
updateTimeline(20)

%Check other matlab
if isa(h.tcpip,'tcpip')
    if h.tcpip.BytesAvailable > 0
        gf.centerStatus = fread(h.tcpip, h.tcpip.BytesAvailable);
        gf.centerStatus = max(gf.centerStatus);
        
         % only able to trigger trial when in correct position 
        %DA.SetTargetVal(sprintf('%s.centerEnable', gf.stimDevice), gf.centerStatus);
    end
end

%Run case
switch gf.status
    %__________________________________________________________________________
    case('PrepareStim')%none to prepare
        
        % Obtain trial parameters
        if ~isfield(gf,'holdRange')  % Initialize hold range
            gf.holdRange = gf.holdMax - gf.holdMin;
            gf.holdRange = gf.holdMin : gf.holdRange/gf.holdSteps : gf.holdMax;
            gf.holdRange = gf.holdRange( randperm( numel(gf.holdRange)));
            gf.holdIdx   = 1;
        end
        if ~isfield(gf,'nTrial')
            gf.nTrial = 1;
        else
            gf.nTrial = gf.nTrial + 1; % number of non-correction trials used to define blocks
        end
        if ~isfield(gf,'trialBlock') % define block structure
            gf.trialBlock = 1;
        elseif gf.nTrial / gf.blockLength > gf.trialBlock
            gf.trialBlock = gf.trialBlock + 1;
        end
        
        if ~isfield(gf,'stimGrid')  % Initialize stimulus grid
            gf.stimIdx  = 1;
            gf.stimGrid = zeros( numel(gf.holdRange),...
                numel(gf.speakers),...
                numel(gf.modalities));
            gf.stimOrder = randperm( numel(gf.stimGrid));     % Randomize order
        end
        
        % Get random position within grid
        gf.stimIdx = gf.stimIdx + 1;      % Update for next trial
        if gf.stimIdx > length(gf.stimOrder)
            gf.stimOrder = randperm( numel(gf.stimGrid));
            gf.stimIdx = 1;
        end
        idx = gf.stimOrder(gf.stimIdx);
  
        [gf.holdIdx, gf.speakerIdx, gf.modalityIdx] = ind2sub( size(gf.stimGrid), idx); % Subscripts refer to indices of indivdual parameter ranges
        gf.holdTime = gf.holdRange(gf.holdIdx);
        gf.modality = gf.modalities(gf.modalityIdx);    % 0 = LED, 1 = Speaker, 2 = Both
        gf.speaker  = gf.speakers(gf.speakerIdx);       % Clockface order
        spk = gf.speaker;
        
        % set the duration appropriate for this block:
        gf.duration = gf.durations(2 - rem(gf.trialBlock,2));
        
        % JB: I think this means you can't get any visual stimuli from
        % locations 3:9 - i.e. only 10,11,12,1,2 are permitted.
        
        if gf.modality == 0 && gf.speaker < 10 && gf.speaker > 2
            % gf.status = 'PrepareStim'; rather than redraw stimulus meaning
            % 2x as many auditory trials
            LEDloc = [10,11,12,1,2];
            r = randperm(length(LEDloc),1);
            % redraw one of the permitted LED locations at random.
            gf.speaker = LEDloc(r(1));
            spk = gf.speaker;
        end

        
        gf.speaker = ['0' dec2base(gf.speaker-1, 4)];   % Convert to quarternery numeral for mux input
        gf.speaker = ['0',gf.speaker];                  % Add zero to cope with case where gf.speaker < 0 and function returns shorter output
        gf.speaker = [str2num(gf.speaker(end-1)), str2num(gf.speaker(end))];    % Reformat from char to double
        
        
        gf.correctionTrial = 0;        % Identify as new trial
        gf.errorCount = 0;
        
        % Time to Sample conversion
        gf.holdSamples = ceil(gf.holdTime * gf.fStim);
        gf.reqSamps = gf.holdSamples - ceil(gf.absentTime*gf.fStim);    % Samples required to initiate
        gf.isiSamps = ceil(gf.isi*gf.fStim);
        
        gf.stimSamps = ceil(gf.duration*gf.fStim);
        
        % Set parameters TDT
        DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
        DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice), gf.holdSamples);
        DA.SetTargetVal( sprintf('%s.reqSamps', gf.stimDevice), gf.reqSamps);
        DA.SetTargetVal( sprintf('%s.nStim', gf.stimDevice), gf.nStimRepeats);
        DA.SetTargetVal( sprintf('%s.stimSamps', gf.stimDevice), gf.stimSamps);
        DA.SetTargetVal( sprintf('%s.stim&intSamps', gf.stimDevice), gf.isiSamps+gf.stimSamps);
        DA.SetTargetVal( sprintf('%s.LED_stim_V', gf.stimDevice), gf.LED_stim_V);
        DA.SetTargetVal( sprintf('%s.Spkr_stim_MF', gf.stimDevice), gf.Spkr_stim_MF	);
        DA.SetTargetVal( sprintf('%s.modality', gf.stimDevice), gf.modality);
        DA.SetTargetVal( sprintf('%s.Spkr-mux-01', gf.stimDevice), gf.speaker(1));
        DA.SetTargetVal( sprintf('%s.Spkr-mux-10', gf.stimDevice), gf.speaker(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.Spkr-mux-11', gf.stimDevice), gf.speaker(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.Spkr-mux-12', gf.stimDevice), gf.speaker(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-01', gf.stimDevice), gf.speaker(1));
        DA.SetTargetVal( sprintf('%s.LED-mux-10', gf.stimDevice), gf.speaker(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-11', gf.stimDevice), gf.speaker(2));  % Brute force approach
        DA.SetTargetVal( sprintf('%s.LED-mux-12', gf.stimDevice), gf.speaker(2));  % Brute force approach
        
        % Update online GUI
        gf.speaker  = spk;   % Return to decimal numeral system
        set(h.status,     'string',sprintf('%s',gf.status))
        set(h.side,       'string',gf.speaker)
        set(h.pitch,      'string',gf.modality)
        set(h.holdTime,   'string',sprintf('%.3f s',gf.holdTime))
        set(h.currentStim,'string','-')
        set(h.atten,      'string','-')
        set(h.trialInfo,  'string',sprintf('%d',gf.TrialNumber-1))
        
        
        %         if gf.modality == 0 && gf.speaker < 10 && gf.speaker > 2
        %
        %             gf.status = 'PrepareStim';
        %
        %         end
        
        % Skip LEDs beyond +/- 60 deg
        
        gf.status = 'WaitForStart';
        
        
        
        
        % Center Response__________________________________________________________
    case('WaitForStart')
        
        centerLickTime = invoke(DA,'GetTargetVal',sprintf('%s.lick6time',gf.stimDevice));
        centerLickTime = centerLickTime ./ gf.fStim;
        comment = 'LED flashing, waiting for center lick';
        
        %If start
        if centerLickTime ~= gf.startTrialTime;
            
            gf.status = 'WaitForResponse';
            gf.startTrialTime = centerLickTime;
            comment = 'Center spout licked';
            
            % Reward at center spout
            %if gf.centerRewardP > rand(1),
            if gf.centerStatus == 1 && gf.centerRewardP > rand(1),
                
                gf.centerReward = 1;
                comment         = 'Trial initiated - giving reward';
                
                valveJumbo(6, gf.centerValveTime);
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
        
        [lick, lickTime] = deal(zeros(12,1));
        
        for i = 1 : 12
            lick(i) = DA.GetTargetVal( sprintf('%s.lick%d', gf.stimDevice, i));
            lickTime(i) = DA.GetTargetVal( sprintf('%s.lick%dtime', gf.stimDevice, i));
        end
        
        lick(6) = 0;        % Ignore center spout
        
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
                gf.response = -1;      
                gf.correct = -1;
                
                logTrial(gf.centerReward, -1)                   %See toolbox (-1 = aborted trial)
                           
                saveData{1, gf.TrialNumber} = gf;
%                 T = dotmatTable(saveData);
%                 save([gf.saveName ' TABLE.mat'], 'T');
                save([gf.saveName '.mat'], 'saveData');
            
            end
            
            
            
            % Otherwise record response time
        else
            
            valveID = find(lick);
            comment = '';
            
            if numel(valveID) == 1,
                
                
                % Get response time
                gf.responseTime = lickTime(valveID) ./ gf.fStim;  %Open Ex
                
                % Count total number of non correction trials for visual
                % and auditory trials
                if gf.modality == 0 && gf.correctionTrial == 0
                    gf.totalVisNonCorr = gf.totalVisNonCorr + 1;
                elseif gf.modality == 1 && gf.correctionTrial == 0
                    gf.totalAudNonCorr = gf.totalAudNonCorr + 1;
                end
                
                if valveID == gf.speaker
                    
                    % Reward
                    valveJumbo(valveID, gf.valveTimes(valveID))
                    comment = 'Correct - reward given';
                    gf.status = 'WaitForEnd';
                    
                    gf.correct = 1;
                    
                    % Count number of correct visual and auditory
                    % trials
                    if gf.modality == 0 && gf.correctionTrial == 0
                        gf.visCorrect = gf.visCorrect + 1;
                    elseif gf.modality == 1 && gf.correctionTrial == 0
                        gf.audCorrect = gf.audCorrect + 1;
                    end
                    %end
                    
                else
                    % Put Timeout Here
                    comment = 'Incorrect - repeating trial';
                    gf.status = 'timeout';
                    
                    gf.correct = 0;
                    
                    %See toolbox
                    %             else
                    %                 gf.errorCount = gf.errorCount + 1;
                    %                 if gf.errorCount > gf.errorLimit
                    %                    gf.status = 'timeout';
                    %                 end
                end
                
                % Update performance
                gf.performance( gf.speaker, valveID, gf.modality+1) = gf.performance( gf.speaker, valveID, gf.modality+1) +1;
                set(h.performanceM(gf.modality+1),'CData',gf.performance(:,:,gf.modality+1))
                
                
                % Log trial
                gf.response = valveID;
                logTrial(gf.centerReward, valveID)
                
                saveData{1, gf.TrialNumber} = gf;
%                 T = dotmatTable(saveData);
%                 save([gf.saveName ' TABLE.mat'], 'T');
                save([gf.saveName '.mat'], 'saveData');
                
                % Reset trial
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 1);
                DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 0);
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
        DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), 0.1);
        pause(0.01)
        DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_bgnd_V);
        DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V);
        
        set(h.trialInfo,  'string',sprintf('%d',gf.TrialNumber-1)) % update trial number on gui even on correction trials
        
        gf.correctionTrial = 1;
        gf.errorCount = gf.errorCount + 1;
        if gf.errorCount < gf.errorLimit
            if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;
                DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
                gf.status = 'WaitForStart';
            end
        else % abort this trial and begin a new one
            % Reset trial
            DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 1);
            DA.SetTargetVal( sprintf('%s.trialReset', gf.stimDevice), 0);
            
            gf.status = 'PrepareStim';
        end
        
end











