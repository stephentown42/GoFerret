function level4_WE

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
        
        attnRange = gf.min_attn : gf.attn_int : gf.max_attn;
        nAttn = length(attnRange);
        [intervals, chans, attns] = deal( cell(nAttn,1));
        
        % Adjustment table (spkr, attn)
        AdjTab = [  2 -0.5;  % 70.5 dB 
                    3 0;    % 71
                    4 0;    % 71
                    5 -0.5;    % 70 - positioning not great for microphone
                    6 -1;    % 70
                    7 1.25;    % 72.25
                    8 -0.5];   % 70.5    
        
        % For each attenuation
        for i = 1 : nAttn,
        
            % Generate stimulus list
            [samps, chans{i}] = unique_isi_sequence( gf.duration,...
                                                        gf.min_delay,...
                                                        gf.max_delay,...
                                                        gf.nSpeakers,...
                                                        gf.fStim);          
            
            % Convert click times to intervals between clicks
            intv         = diff(samps) ;
            intervals{i} = [intv; intv(1)];
            attnsUA      = repmat( attnRange(i), size(chans{i})); % Unadjusted (UA)
            attnsA       = attnsUA;
            
            % Make fine adjustments for levels
            for spkr = 2 : 8,
            
                rows = chans{i} == spkr;
                adjt = AdjTab(spkr-1, 2);
                
                attnsA(rows) = attnsUA(rows) + adjt;
            end
            
            attns{i} = attnsA;
        end
        
        % Cell 2 mat
        attns = cell2mat(attns);
        intervals = cell2mat(intervals);
        chans = cell2mat(chans);
        
        % Randomize once again
        nStim = length(chans);
        order = randperm(nStim);
        attns = attns(order);
        intervals = intervals(order);
        chans = chans(order);
        
        % Add final interval - the length of time between reps (enough to
        % include rewards)
        rewardTime = (2*(8 * gf.valveTime)) * gf.fStim;
        intervals  = [intervals; rewardTime];
        
        
        % Convert Attn to voltage level
        Vs = 0.*attns;
        
        for i = 1 : length(attns),
            Vs(i) = gf.pulseV .* 10^(-(attns(i)/20));
        end
        
        % Add one to speaker to account for lack of speaker 1 
        chans = chans + 1;
        
        % Pause to counter parallel processing
        pause(1)
        
        
        % Speaker calibration (to use, change date)
%         if strcmp( datestr(now,'dd-mm-yy'),'22-10-14'),
%             
%             chans = 8 .* ones(size(chans));
%         end
        
        % Write to buffers
        if ~DA.WriteTargetVEX( sprintf('%s.intervals', gf.stimDevice), 0, 'F32', intervals');
            warning('Failed to write intervals')
        end
        
        if ~DA.WriteTargetVEX( sprintf('%s.Vs', gf.stimDevice), 0, 'F32', Vs');
            warning('Failed to write intervals')
        end
                
        if ~DA.WriteTargetVEX( sprintf('%s.speakers', gf.stimDevice), 0, 'F32', chans');
            warning('Failed to write speakers')
        end
                
        % Assign to structure for saving
%         gf.chans     = [gf.chans     chans];
        gf.intervals = intervals;
%         gf.samps     = [gf.samps     samps];
%         
%         save(gf.saveName, '-struct','gf')
        
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
%             DA.SetTargetVal( sprintf('%s.pulseV', gf.stimDevice), gf.pulseV);
        end
        
        % Report current speaker and interval
        speaker  = DA.GetTargetVal( sprintf( '%s.currSpkr',  gf.stimDevice));
        interval = DA.GetTargetVal( sprintf( '%s.interval',  gf.stimDevice));
                
        set(h.currSpkr,'string',num2str(speaker))
        set(h.interval,'string',sprintf('%0.3f s',interval/gf.fStim))
        
        
        % Get current stimulus and stop if rep completed
        currentStim = DA.GetTargetVal( sprintf( '%s.spkrIdx',  gf.stimDevice));
        set(h.currentStim,'string',sprintf('%d / %d',currentStim, size(gf.intervals,1)))
        
        if currentStim >= size(gf.intervals,1)-1,
            
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
            valve_WE( order(i), gf.valveTime*1000, 1)   
            pause( gf.valveTime * 1.1)
        end
        
       gf.status = 'PrepareStim';
end

%Check outputs
checkOutputs_WE(10);                                %See toolbox for function

plotLEDposition


