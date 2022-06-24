function level01

% Level 1 - Reward all responses

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
        
        % Initialize variables
        gf.correctionTrial = 0;        % Identify as new trial
        gf.errorCount = 0;
        gf.nStimRepeats = -1;
        gf.modality = 3;
        
        
        % Set parameters TDT
        DA.SetTargetVal( sprintf('%s.centerEnable', gf.stimDevice), 1);    % Enable center spout
        DA.SetTargetVal( sprintf('%s.holdSamples', gf.stimDevice),  10);             
        DA.SetTargetVal( sprintf('%s.reqSamps', gf.stimDevice),     5);               
        DA.SetTargetVal( sprintf('%s.nStim', gf.stimDevice),        -1);                   
        DA.SetTargetVal( sprintf('%s.modality', gf.stimDevice),    3);
        
        
        % Update online GUI      
         set(h.status,    'string',sprintf('%s',gf.status))
        set(h.pitch,      'string','NA')     
        set(h.holdTime,   'string','NA')
        set(h.currentStim,'string','-') 
        set(h.atten,      'string','-')        
        set(h.trialInfo,  'string',sprintf('%d',gf.TrialNumber-1))
    
         % Skip LEDs beyond +/- 60 deg         
        gf.status = 'WaitForStart';   

        
        
% Center Response__________________________________________________________        
    case('WaitForStart')                                
        
               
        [lick, lickTime] = deal(zeros(12,1));
        
        for i = 1 : 12
           lick(i) = DA.GetTargetVal( sprintf('%s.lick%d', gf.stimDevice, i));
           lickTime(i) = DA.GetTargetVal( sprintf('%s.lick%dtime', gf.stimDevice, i));
        end
       
        lickTime = lickTime ./ gf.fStim;    % Sample to second conversion
      
        % Ignore uninteresting spouts
        if isfield(gf,'spouts2ignore')
           lick(gf.spouts2ignore) = 0; 
        end
        
        % Require that center status is high to reward center spout
        if gf.centerStatus == 0, lick(6) = 0; end
        
        %If any response
        if any(lick)    
                        
            % Find index
            valveID = find(lick);
            
            % Don't allow if recently rewarded
            lickTime = lickTime(valveID);
            
            if lickTime > gf.responseTime + 3            
                
                % Update variables
                gf.responseTime = lickTime;
                comment         = sprintf('Correct - reward given @ spout %d', valveID);
                gf.status       = 'WaitForEnd';
                              
                % Reward
                valveJumbo_J4(valveID, gf.valveTimes(valveID))
            end                                              
        end
        
                
    case 'WaitForEnd'
        
        if DA.GetTargetVal(sprintf('%s.stimON', gf.stimDevice)) == 0;           
            gf.status = 'PrepareStim';
        end           

end

catch err
    err
    keyboard    
end


    

    
    


