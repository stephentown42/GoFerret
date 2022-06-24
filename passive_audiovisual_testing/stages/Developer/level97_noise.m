function level97_noise
try
% Level 11 
% Passive ferret, manual stimulus delivery

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

if iscom(DA) == 1,                                 % Only check sensors if TDT connected
    checkSensors(bits, vars);                      % See toolbox for function
end
    
%Run case
switch gf.status

    case('GenerateStimList')
        
        % Type      FrequencyParams         Attn
        % 'Vowel'   [460 1105 2857 4205]    -10
        % 'Tone'    [200]                     0
        noise = struct;
        
        
        if gf.attenMin ~= gf.attenMax,
            noise.attns = gf.attenMin: (gf.attenMax - gf.attenMax)/ gf.attenSteps : gf.attenMax;
        else
            noise.attns = gf.attenMin;
        end
        
        noise.n  = length(noise.attns) * gf.nReps;    
        
        [attnIdx, repIdx] = ind2sub([ length(noise.attns), gf.nReps ],...
                                       randperm(noise.n));
        
        
        noise.order = [attnIdx', repIdx'];
        noise.Idx   = 1;
        
        gf.noise = noise;
        
        gf.status = 'PrepareStim';
%__________________________________________________________________________    
    case('PrepareStim')
        
        % Throw back to generate stimulus list if it doesn't exist (i.e
        % when initially starting up.        
        if ~isfield(gf, 'noise'), 
            gf.status = 'GenerateStimList'; return
        end
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        % Select tone frequency;  
        if gf.noise.Idx > gf.noise.n,
            
            set(h.status,     'string','Stimulus grid complete')
            set(h.pitch,      'string','Stimulus grid complete')
            set(h.holdTime,   'string','Stimulus grid complete')
            set(h.atten,      'string','Stimulus grid complete')
            set(h.trialInfo,  'string','Stimulus grid complete')
            set(h.currentStim,'string','Pure Tone')
            
        else
            gf.attn = gf.noise.attns( gf.noise.order( gf.noise.Idx, 1));        
        
            % Monitor trial history
            gf.noise.Idx = gf.noise.Idx + 1;                      

            % Make sound

            sound = rand(1,ceil(gf.fStim*gf.duration/1000));        
            sound = sound .* 10^(-(gf.attn/20));        
            sound = envelope(sound, ceil(5e-3*gf.fStim));

            isi   = zeros(1, ceil(gf.isi/1000 * gf.fStim));     % add interstimulus interval  
            sound = [sound, isi];    

            % Calculate hold range        
            gf.holdSamples = length(sound);        
            gf.holdTime    = gf.holdSamples / gf.fStim;

            % Calculate timing information
    %         holdOK    = length(sound);
    %         playDelay = gf.holdSamples - holdOK;
    %         refractS  = playDelay + length(sound) + ceil(gf.refractoryTime * gf.fStim);
    %         absentS   = ceil(gf.absentTime * gf.fStim);

            % Calibrate sounds
            sound0 = conv(sound, gf.fltL.flt, 'same');
            sound1 = conv(sound, gf.fltR.flt, 'same');


            % Write sound to buffers
            DA.WriteTargetVEX(sprintf('%s.sound0', gf.stimDevice), 0, 'F32', sound0); % Play from 
            DA.WriteTargetVEX(sprintf('%s.sound1', gf.stimDevice), 0, 'F32', sound1); % both speakers

           % Set timing information on TDT
            DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));        
            DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), length(sound));  
            DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), 1);
            DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), 1); 
            DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), 1);

            % Enable / Disable Circuit components
            DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1);                         
            DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
            DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition

            % Update online GUI       
            set(h.status,     'string',sprintf('%s',gf.status))    
            set(h.holdTime,   'string',sprintf('%.1f s', gf.holdTime))        
            set(h.atten,      'string',sprintf('%.1f dB', gf.attn))        
            set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))        
            set(h.currentStim,'string','Pure Tone') 

            gf.status = 'WaitForStart';

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
            comment = 'LED flashing, waiting for center lick';
            
        else
            DA.SetTargetVal( sprintf('%s.flashEnable',      gf.stimDevice), 0);              
                                                            
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.lickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
            gf.startTrialTime    = gf.startTrialTime - (gf.holdTime/1000);     % Label start of sound rather than
            gf.status            = 'PrepareStim';
            
            % Reward at center spout       
            gf.centerReward = 1;
            comment         = 'Center spout licked - giving reward';                              
            
            % Log trial
            fprintf(gf.fid, '%d\t',     gf.TrialNumber);
            fprintf(gf.fid, '0\t');                                         % Correction Trial = 0;
            fprintf(gf.fid, '%.3f\t',   gf.startTrialTime);
            fprintf(gf.fid, '%d\t',     gf.centerReward);
            fprintf(gf.fid, '-1\t-1\t-1\t-1\t');                 % Formants not applicable
            fprintf(gf.fid, '%d\t',     gf.holdTime);
            fprintf(gf.fid, '%.1f\t',   gf.attn);
            fprintf(gf.fid, '-1\t-1\t-1\n');                 % Response, response time and correct not applicable
            
            % Move to next trial
            gf.TrialNumber  = gf.TrialNumber + 1;
            
%             pause(gf.duration/1000);
            
            valve(6, gf.centerValveTime, 1, 'center');  
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
        




end

%Check outputs
checkOutputs([4 5 6 7]);                                %See toolbox for function

%Update timeline
updateTimeline(20)


catch err
    
    err 
    keyboard
    
end

