function level93
% Level 95 - FRA

% This protocol for delivering stimulus leaves the spout completely open
% for a set amount of time with the assumption that the passive properties
% of the plumbing system have been optimized to delivery a slow continuous 
% (~1/30 ml/s) stream of water. 
% 
% vowels are played on every trial, where each trial is extremely short
% (~1s). The animal cannoth terminate trials, they terminate themselves as
% the abort time is set <1. If the animal leaves the center, sounds will
% not play. The hold time is the length of the sound, minimizing any false
% trials

global DA gf h 
% DA: TDT connection structure
% gf: Go ferrit user data
% h:  Online GUI handles

try

%GUI Clock
gf.sessionTime = (now - gf.startTime)*(24*60*60);
set(h.sessionLength,'string', sprintf('%0.1f secs',gf.sessionTime));

% Keep valve open
if ~gf.valveState,  % (faster than checking for field)    
    
%     valve(6, gf.centerValveTime, 1, 'center');                  
    gf.valveState = 0;

    % Hold light constantly on
    DA.SetTargetVal( sprintf('%s.ledEnable',gf.stimDevice), 0);        
end

%Run case
switch gf.status
    
    case('Pause')

    case('GenerateStimList')
        
        % Type      FrequencyParams         Attn
        % 'Vowel'   [460 1105 2857 4205]    -10
        % 'Tone'    [200]                     0
        vowels = struct;
        gf.Nreps  = 1;
        
       
        
        vowels.n  = length(gf.attnRange) * length(gf.pitchRange) * gf.Nreps;    
        
        [attnIdx, freqIdx, repIdx] = ind2sub([ length(gf.attnRange),...
                                               length(gf.pitchRange),...
                                               gf.Nreps ],...
                                               randperm(vowels.n));
        
        
        vowels.order = [attnIdx', freqIdx', repIdx'];
        vowels.Idx   = 1;
        
        gf.vowels = vowels;        
        gf.status = 'PrepareStim';
%__________________________________________________________________________    
    case('PrepareStim')
        
        % Throw back to generate stimulus list if it doesn't exist (i.e
        % when initially starting up.        
        if ~isfield(gf, 'vowels'), 
            gf.status = 'GenerateStimList'; return
        end
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        % Select tone frequency;  
        if gf.vowels.Idx > gf.vowels.n,
            
%             set(h.status,     'string','Stimulus grid complete')
%             set(h.pitch,      'string','Stimulus grid complete')
%             set(h.holdTime,   'string','Stimulus grid complete')
%             set(h.atten,      'string','Stimulus grid complete')
%             set(h.trialInfo,  'string','Stimulus grid complete')
%             set(h.currentStim,'string','Pure Tone')
            gf.status = 'GenerateStimList';
            
        else
            gf.attn = gf.gf.attnRange( gf.vowels.order( gf.vowels.Idx, 1));
            gf.freq = gf.gf.pitchRange( gf.vowels.order( gf.vowels.Idx, 2));        
        
            % Monitor trial history
            gf.vowels.Idx = gf.vowels.Idx + 1;                      

            % Make sound

            sound = tone(gf.fStim, gf.freq, gf.duration/1000);   
            if isfield(gf,'noiseON'),
                sound = rand(size(sound));
            end

            % Compensate for slight differences in loudness
            if ismember(gf.formants,[936,1551,2975,4263],'rows'), gf.atten = gf.atten - 5; end
            if ismember(gf.formants,[730 2058 2857 4205],'rows'), gf.atten = gf.atten - 2; end

            % Envelope
            sound = sound .* 10^(-(gf.attn/20));        
            sound = envelope(sound, ceil(5e-3*gf.fStim));
            
            % Calculate hold range        
            gf.holdSamples = length(sound);        
            gf.holdTime    = gf.holdSamples / gf.fStim;

            % Calculate timing information
    %         holdOK    = length(sound);
    %         playDelay = gf.holdSamples - holdOK;
    %         refractS  = playDelay + length(sound) + ceil(gf.refractoryTime * gf.fStim);
    %         absentS   = ceil(gf.absentTime * gf.fStim);

            % Calibrate sounds
%             if ~isfield(gf,'noiseON'),                
                sound0 = conv(sound, gf.fltL.flt, 'same');
                sound1 = conv(sound, gf.fltR.flt, 'same');
%             end

            % Write sound to buffers
            DA.WriteTargetVEX(sprintf('%s.sound0', gf.stimDevice), 0, 'F32', sound0); % Play from 
            DA.WriteTargetVEX(sprintf('%s.sound1', gf.stimDevice), 0, 'F32', sound1); % both speakers

           % Set timing information on TDT
            DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));        
            DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), length(sound));  
            DA.SetTargetVal( sprintf('%s.absentSamps',      gf.stimDevice), 1);
            DA.SetTargetVal( sprintf('%s.playDelay',        gf.stimDevice), 1); 
            DA.SetTargetVal( sprintf('%s.refractorySamps',  gf.stimDevice), gf.refractoryTime * gf.fStim);

            % Enable / Disable Circuit components
            DA.SetTargetVal( sprintf('%s.centerEnable',     gf.stimDevice), 1);                         
            DA.SetTargetVal( sprintf('%s.repeatPlayEnable', gf.stimDevice), 0);                 % Disable OpenEx driven sound repetition
            DA.SetTargetVal( sprintf('%s.repeatPlay',       gf.stimDevice), 0);                 % Disable Matlab driven sound repetition

            % Update online GUI       
            set(h.status,     'string',sprintf('%s',gf.status))
            set(h.pitch,      'string',sprintf('%.0f Hz', gf.freq))     
            set(h.holdTime,   'string',sprintf('%.1f s', gf.holdTime))        
            set(h.atten,      'string',sprintf('%.1f dB', gf.attn))        
            set(h.trialInfo,  'string',sprintf('%d', gf.TrialNumber - 1))        
            set(h.currentStim,'string','Pure Tone') 

            gf.status = 'WaitForStart';

        end
        
% Center Response__________________________________________________________        
    case('WaitForStart')

        DA.SetTargetVal( sprintf('%s.spoutPlayEnable',  gf.stimDevice), 1);                 % Enable sound in hold time        

        centerLick  = invoke(DA,'GetTargetVal',sprintf('%s.CenterLick',gf.stimDevice));
        
        % This could be where we fall down, we need to how to reset the
        % system to allow continuous spout presence while stimuli play
        
        
        %If no start
        if centerLick == 0;
            
            comment = 'Waiting for center lick';            
        else
            DA.SetTargetVal( sprintf('%s.flashEnable',      gf.stimDevice), 0);              
                                                            
            gf.startTrialTime    = DA.GetTargetVal(sprintf('%s.CenterLickTime',gf.stimDevice)) ./ gf.fStim;  %Open Ex
            gf.startTrialTime    = gf.startTrialTime - (gf.holdTime/1000);     % Label start of sound rather than
            gf.status            = 'WaitForResponse';
            
            % Reward at center spout       
            comment         = 'Center spout licked - waiting for peripheral response';                              
            gf.centerReward = 0;                        
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
                
        
    case('WaitForResponse')
            
        DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 0);                 % Reset counter for center spout...
        
        timeNow       = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
        timeElapsed   = timeNow - gf.startTrialTime;        
        comment       = 'Intertrial interval';

        if timeElapsed > gf.abortTrial,                        
            
            % Log trial
            fprintf(gf.fid, '%d\t',     gf.TrialNumber);
            fprintf(gf.fid, '0\t');                                         % Correction Trial = 0;
            fprintf(gf.fid, '%.3f\t',   gf.startTrialTime);
            fprintf(gf.fid, '%d\t',     gf.centerReward);
            fprintf(gf.fid, '-1\t-1\t-1\t-1\t');                 % Formants not applicable
            fprintf(gf.fid, '%.0f\t',     gf.holdTime);
            fprintf(gf.fid, '%.1f\t',   gf.attn);
            fprintf(gf.fid, '%.3f\t',   gf.freq);               % Pitch = tone frequency
            fprintf(gf.fid, '-1\t0\t-1\n');

            
            % Move to next trial   
            DA.SetTargetVal( sprintf('%s.centerEnable',      gf.stimDevice), 1);                 % Reset counter for center spout...                       
            DA.SetTargetVal( sprintf('%s.bit2',      gf.stimDevice), 0);  
            DA.SetTargetVal( sprintf('%s.bit2',      gf.stimDevice), 1);  
            gf.TrialNumber  = gf.TrialNumber + 1;                        
            comment         = 'response';
            gf.status       = 'PrepareStim';
        end
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string',comment);
end

%Update timeline
updateTimeline(20)


catch err
    
    err 
    keyboard    
end

