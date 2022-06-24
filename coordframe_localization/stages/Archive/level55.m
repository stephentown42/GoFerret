function level55


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

% Set ongoing parameters
tags = {'LED_bgnd_V','Spkr_bgnd_V'};

for i =1 : numel(tags)
    
   eval(sprintf('val = gf.%s;', tags{i}));
   DA.SetTargetVal(sprintf('%s.%s', gf.stimDevice,tags{i}), val);
end

% Update timeline
updateTimeline(20)


%Run case
switch gf.status

%__________________________________________________________________________    
    case('PrepareStim')%none to prepare
        
        try
        
        % Obtain trial parameters                                
        [gf.hold, gf.holdTime] = getHoldTime(gf.hold);
        
        if gf.stim.idx == 0 || gf.stim.idx > gf.stim.n
            gf.stim = generateStimGrid_Level55(gf.stim);
        else
            gf.stim.idx = gf.stim.idx + 1;   
        end
                
        gf.stim.currentPos = gf.stim.spout(gf.stim.idx);
        distractorPos      = 10;        
        if gf.stim.currentPos == 10, distractorPos = 2;   end
        
       % Get stimulus parameters        
        gf.modality    = gf.stim.modality(gf.stim.idx);    % 0 = LED, 1 = Speaker, 2 = Both 
        gf.domMod      = gf.stim.domMod(gf.stim.idx);
        gf.targetSpout = gf.stim.currentPos;   % Define target spout based on target modality
        
        if gf.domMod == 0        
            gf.LED     = gf.stim.currentPos;    % Note that this is revesed below and wil need
            gf.Speaker = distractorPos;    % Changing in future iterations
        else
            gf.LED     = distractorPos;    % Note that this is revesed below and wil need
            gf.Speaker = gf.stim.currentPos;    % Changing in future iterations
        end       
        
        % Get stimulus parameters        
        gf.LEDmux = getMUXfamily( gf.LED); 
        gf.SPKmux = getMUXfamily( gf.Speaker); 
                                        
        % Initialize variables
        gf.correctionTrial = 0;        % Identify as new trial
        gf.nStimRepeats    = -1;
        
        % Time to Sample conversion
        gf.holdSamples = ceil(gf.holdTime * gf.fStim);        
        gf.reqSamps = gf.holdSamples - ceil(gf.absentTime*gf.fStim);    % Samples required to initiate
        gf.isiSamps = ceil(gf.isi*gf.fStim);
        gf.stimSamps = ceil(gf.duration*gf.fStim);
        
        % Set parameters TDT
        DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
        DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice),  gf.holdSamples);             
        DA.SetTargetVal( sprintf('%s.reqSamps', gf.stimDevice),     gf.reqSamps);               
        DA.SetTargetVal( sprintf('%s.nStim', gf.stimDevice),        gf.nStimRepeats);                   
        DA.SetTargetVal( sprintf('%s.stimSamps', gf.stimDevice),     gf.stimSamps);  
        DA.SetTargetVal( sprintf('%s.stim&intSamps', gf.stimDevice), gf.isiSamps+gf.stimSamps);         
        DA.SetTargetVal( sprintf('%s.LED_stim_V', gf.stimDevice),    gf.LED_stim_V); 
        DA.SetTargetVal( sprintf('%s.Spkr_stim_MF', gf.stimDevice), gf.Spkr_stim_MF	); 
        DA.SetTargetVal( sprintf('%s.modality', gf.stimDevice),    gf.modality);
        DA.SetTargetVal( sprintf('%s.domMod', gf.stimDevice),    gf.domMod);
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
         if gf.Speaker~=gf.LED
             gf.status = 'WaitForStart';
         else
             gf.status = 'PrepareStim';
         end
%         
%         if gf.modality == 0 && gf.speaker < 10 && gf.speaker > 2
%             gf.status = 'PrepareStim';
%         end 
        catch 
        end
        
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
            if gf.centerStatus && gf.centerRewardP > rand(1)
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
                logTrial(gf.centerReward, -1)                   %See toolbox (-1 = aborted trial)                   
            end
            
            
            
        % Otherwise record response time
        else
            
            valveID = find(lick);
            comment = '';
            
            if numel(valveID) == 1, 

                % Get response time
                gf.responseTime = lickTime(valveID) ./ gf.fStim;  %Open Ex            


                if valveID == gf.targetSpout  
                                        
                     % Reward
                     valveJumbo(valveID, gf.valveTimes(valveID))
                     comment = 'Correct - reward given';
                     gf.status = 'WaitForEnd';                    
                    
                else
                    % Put Timeout Here
                    comment = 'Incorrect - repeating trial';
                    gf.status = 'timeout';
                   
                    %See toolbox 
    %             else
    %                 gf.errorCount = gf.errorCount + 1;
    %                 if gf.errorCount > gf.errorLimit
    %                    gf.status = 'timeout'; 
    %                 end
                end
                
                % Update performance                      
                updatePerformance(valveID)
                
                % Log trial
                logTrial(gf.centerReward, valveID)
                
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
        
        DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 0);        
        DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice),  1e6);           
        DA.SetTargetVal( sprintf('%s.domMod', gf.stimDevice),3);
        gf.correctionTrial = gf.correctionTrial + 1;
        
        timeNow        = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
        timeElapsed    = timeNow - gf.responseTime;
        timeRemaining  = gf.timeoutDuration - timeElapsed;
        
        comment = sprintf('Timeout: \nTime remaining %0.1f s', timeRemaining);
        set(h.comment,'string',comment);
            
        if gf.correctionTrial > 2
            DA.SetTargetVal( sprintf('%s.modality', gf.stimDevice),gf.domMod);
        end
           
        if timeElapsed < 1          
        
            DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_stim_V);
            DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_stim_MF*gf.Spkr_bgnd_V);
            pause(0.01)
            DA.SetTargetVal( sprintf('%s.LED_bgnd_V', gf.stimDevice), gf.LED_bgnd_V);
            DA.SetTargetVal( sprintf('%s.Spkr_bgnd_V', gf.stimDevice), gf.Spkr_bgnd_V);
        end
        
        if timeRemaining <= 0 & DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;
            DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
                  
            DA.SetTargetVal( sprintf('%s.domMod', gf.stimDevice),gf.domMod);
            DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice),gf.holdSamples);
            
                gf.status = 'WaitForStart';
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
       


    

    
    


