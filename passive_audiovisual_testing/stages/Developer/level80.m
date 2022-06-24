function level95
% Level 95 - FRA

% This protocol for delivering stimulus leaves the spout completely open
% for a set amount of time with the assumption that the passive properties
% of the plumbing system have been optimized to delivery a slow continuous 
% (~1/30 ml/s) stream of water. 
% 
% Tones are played on every trial, where each trial is extremely short
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

% hold light constantly on
DA.SetTargetVal( sprintf('%s.ledEnable',gf.stimDevice), 0);

%Run case
switch gf.status
    
%______________________________________    
    case('PrepareStim')
        
        
        
        % Identify as new trial
        gf.correctionTrial = 0;
        
        % initialize stimulus index
        if ~isfield(gf,'stimCounter'), gf.stimCounter = inf; end
        
        % Reset stimulus order
        if gf.stimCounter > length(gf.stim),
            gf.stimOrder   = randperm(length(gf.stim));
            gf.stimCounter = 1;               
        end
                                        
        % Get sound from stimulus array
        gf.stimIdx     = gf.stimOrder( gf.stimCounter);        
        gf.stimCounter = gf.stimCounter + 1;
        sound          = gf.stim{ gf.stimIdx};
        gf.soundTime   = length(sound) ./ gf.fStim;
        
        % Define redundant parameters
        gf.attn     = 43;
        gf.freq     = -1;       
        gf.holdTime = -1 * (length(sound)/gf.fStim);
        
%         % Attenuate and envelope
%         sound = sound .* 10^(-(gf.attn/20));
%         sound = envelope(sound, ceil(5e-3*gf.fStim));
                        
        % Calibrate sounds
        sound0 = conv(sound, gf.fltL.flt, 'same');
        sound1 = conv(sound, gf.fltR.flt, 'same');
        
        
        % Write sound to buffers
        DA.WriteTargetVEX(sprintf('%s.sound1', gf.stimDevice), 0, 'F32', sound1'); % both speakers                
        DA.WriteTargetVEX(sprintf('%s.sound0', gf.stimDevice), 0, 'F32', sound0'); % Play from
        
        % Set timing information on TDT
        DA.SetTargetVal( sprintf('%s.stimNPoints',      gf.stimDevice), length(sound));
        DA.SetTargetVal( sprintf('%s.holdSamples',      gf.stimDevice), 1);
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
        
        % Initiate play and get mark start time
        pause(0.1)
        DA.SetTargetVal( sprintf('%s.manualPlay', gf.stimDevice), 1);  
        gf.startTrialTime = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim; 
        DA.SetTargetVal( sprintf('%s.manualPlay', gf.stimDevice), 0);
                
        % Monitor play
        gf.status = 'MonitorPlay';

        
% Center Response__________________________________________________________        
    case('MonitorPlay')

        % Get time elapsed
        timeNow       = DA.GetTargetVal(sprintf('%s.zTime',gf.stimDevice)) ./ gf.fStim;
        timeElapsed   = timeNow - gf.startTrialTime;        
        comment       = sprintf('Stimulus currently playing: %.1f secs remaining', gf.holdTime + timeElapsed);
        
        
        %Update GUI
        set(h.status,'string',gf.status);
        set(h.comment,'string', comment);
                
        
        % If stimulus completed        
        if timeElapsed >  (0.1+gf.soundTime),        
            
            % Log trial
            fprintf(gf.fid, '%d\t',     gf.TrialNumber);
            fprintf(gf.fid, '0\t');                                         % Correction Trial = 0;
            fprintf(gf.fid, '%.3f\t',   gf.startTrialTime);
            fprintf(gf.fid, '%d\t',     1);                      % Center reward
            fprintf(gf.fid, '-1\t-1\t-1\t-1\t');                 % Formants not applicable
            fprintf(gf.fid, '%.3f\t',   gf.holdTime);
            fprintf(gf.fid, '%.1f\t',   gf.attn);
            fprintf(gf.fid, '%.3f\t',   gf.freq);                   % Pitch = tone frequency            
            fprintf(gf.fid, '%d\t',     gf.stimIdx);                      % Center reward
            fprintf(gf.fid, '0\t-1\n');

            
            % Move to next trial   
            gf.TrialNumber  = gf.TrialNumber + 1;                        
            comment         = 'Sound ended';
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

