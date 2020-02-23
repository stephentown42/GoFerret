function level1_WE

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

    
%Run case
switch gf.status
    

%__________________________________________________________________________    
    case('PrepareStim')     
        
        set(h.status,'string','Preparing stim')
        
        % Generate stimulus list
        [samps, chans] = unique_isi_sequence( gf.duration,...
                                                    gf.min_delay,...
                                                    gf.max_delay,...
                                                    gf.nSpeakers,...
                                                    gf.fStim);
        
        % Convert click times to intervals between clicks
        intervals = diff(samps) ;
        
        % Add final interval - the length of time between reps (enough to
        % include rewards)
        rewardTime = (2*(8 * gf.valveTime)) * gf.fStim;
        intervals  = [intervals; intervals(1); rewardTime];
        
        % Add one to speaker to account for lack of speaker 1 
        chans = chans + 1;
        
        % Pause to counter parallel processing
        pause(1)
        
        % Write to buffers
        if ~DA.WriteTargetVEX( sprintf('%s.intervals', gf.stimDevice), 0, 'F32', intervals');
            warning('Failed to write intervals')
        end
        
        if ~DA.WriteTargetVEX( sprintf('%s.speakers', gf.stimDevice), 0, 'F32', chans');
            warning('Failed to write speakers')
        end
                
        % Assign to structure for saving
        gf.chans     = [gf.chans     chans];
        gf.intervals = [gf.intervals intervals];
        gf.samps     = [gf.samps     samps];
        
        save(gf.saveName, '-struct','gf')
        
        % Reset buffer positions
        while DA.GetTargetVal( sprintf( '%s.spkrIdx',  gf.stimDevice)) > 1,
            
            DA.SetTargetVal( sprintf('%s.reset', gf.stimDevice), 1);        
            DA.SetTargetVal( sprintf('%s.reset', gf.stimDevice), 0);
        end
        
        
        
        gf.nReps  = gf.nReps + 1;
        gf.status = 'Play stim';               
        
        set(h.trialInfo,  'string', sprintf('Rep %d', gf.nReps))
        
        
% Center Response__________________________________________________________        
    case('Play stim')
        
        set(h.status,'string','Playing stimuli')
        
        % Continue playing
        if ~DA.GetTargetVal( sprintf( '%s.play',  gf.stimDevice));
            
            DA.SetTargetVal( sprintf('%s.play', gf.stimDevice), 1);
            DA.SetTargetVal( sprintf('%s.pulseV', gf.stimDevice), gf.pulseV);
        end
        
        % Report current speaker and interval
        speaker  = DA.GetTargetVal( sprintf( '%s.currSpkr',  gf.stimDevice));
        interval = DA.GetTargetVal( sprintf( '%s.interval',  gf.stimDevice));
                
        set(h.currSpkr,'string',num2str(speaker))
        set(h.interval,'string',sprintf('%0.3f s',interval/gf.fStim))
        
        
        % Get current stimulus and stop if rep completed
        currentStim = DA.GetTargetVal( sprintf( '%s.spkrIdx',  gf.stimDevice));
        set(h.currentStim,'string',sprintf('%d / %d',currentStim, size(gf.chans,1)))
        
        if currentStim == size(gf.intervals,1)-1,
            
            DA.SetTargetVal( sprintf('%s.play', gf.stimDevice), 0);
            gf.status = 'Reward';
        end
                               
        
% Peripheral Response______________________________________________________        
    case('Reward')
               
        set(h.status,'string','Rewarding - Please wait')
        
        % Randomize order of reward
        order = randperm(8);
        pause(gf.max_delay)
        
        for i = 1 : 8,
            valve_WE( order(i), gf.valveTime*1e3, 1)   
            pause( gf.valveTime * 1.1)
        end
        
       gf.status = 'PrepareStim';
end

%Check outputs
checkOutputs_WE(10);                                %See toolbox for function

plotLEDposition


