function level3_Jumbo

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
        
        attn_range = gf.min_attn : gf.attn_int : gf.max_attn;
        attn_n = length(attn_range);
        [intervals, chans, attns] = deal( cell(attn_n,1));
        
        % Adjustment table (spkr, attn)
        adjustment_table = [    1 -4;      % 7 o clock (c2)- 61
                                2 -5.5;    % 9 o clock (c4)- 59.5
                                3 -5.5;    % 8 o clock (c3)- 59.25
                                4 -6;      % 10 o clock (c5) - 59
                                5 -5.5;    % 11 o clock (c6)- 59.25
                                6 -4;      % 6 o clock - 61
                                7 -5.5;    % 1 o click (c12)- 59.75
                                8 -5;      % 2 o clock (c9)- 60
                                9 -5;      % 3 o clock (c10)- 60
                                10 -6;     % 4 o clock (c11) - 59
                                11 -5.5;   % 5 o clock (c8) - 59.5
                                12 -5];    % 59.5 - 12 oclock
        
        % For each attenuation
        for atten_idx = 1 : attn_n
        
            % Generate stimulus list
            [samps, chans{atten_idx}] = unique_isi_sequence( gf.duration,...
                                                        gf.min_delay,...
                                                        gf.max_delay,...
                                                        gf.nSpeakers,...
                                                        gf.fStim);

            % Convert click times to intervals between clicks
            sample_intervals = diff(samps);
            intervals{atten_idx} = [sample_intervals; sample_intervals(1)];
            
            % Make fine adjustments for levels
            attns_unadjusted = repmat( attnRange(atten_idx), size(chans{atten_idx})); 
            attns_adjusted = attns_unadjusted;
            
            for speaker_idx = 1 : gf.nSpeakers
                            
                adjustment = adjustment_table(speaker_idx, 2);
                rows = chans{atten_idx} == speaker_idx;
                
                attns_adjusted(rows) = attns_unadjusted(rows) + adjustment;
            end
            
            attns{atten_idx} = attns_adjusted;
        end
               
        % Randomize once again
        T = table( cell2mat(chans), cell2mat(attns), cell2mat(intervals),...
            'VariableNames',{'Chan','Attn','Interval'});
        T = T( randperm( size(T, 1)), :);

        
        % Add final interval - the length of time between reps (enough to
        % include rewards)
        T.Interval(end)  = 2 * gf.nSpeakers * gf.valveTime * gf.fStim;                
        
        % Convert Attn to voltage level
        T.Voltage = zeros( size(T, 1), 1);
        
        for i = 1 : size(T, 1)
            T.Voltage(i) = gf.pulseV .* 10^(-(T.Attn(i)/20));
        end
        
        % Pause to counter parallel processing
        pause(1)
        
        % Write to buffers        
        if ~DA.WriteTargetVEX( sprintf('%s.intervals', gf.stimDevice), 0, 'F32', intervals')
            warning('Failed to write intervals')
        end        
        
        if ~DA.WriteTargetVEX( sprintf('%s.Vs', gf.stimDevice), 0, 'F32', Vs')
            warning('Failed to write intervals')
        end
                
        if ~DA.WriteTargetVEX( sprintf('%s.speakers', gf.stimDevice), 0, 'F32', chans')
            warning('Failed to write speakers')
        end
                
        
        % Reset buffer positions
        while DA.GetTargetVal( sprintf( '%s.spkrIdx',  gf.stimDevice)) > 1
            
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
        if ~DA.GetTargetVal( sprintf( '%s.play',  gf.stimDevice))
            
            DA.SetTargetVal( sprintf('%s.play', gf.stimDevice), 1);            
            DA.SetTargetVal( sprintf('%s.play', gf.recDevice), 1);
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
            DA.SetTargetVal( sprintf('%s.play', gf.recDevice), 0);
            gf.status = 'Reward';
        end
                               
        
% Peripheral Response______________________________________________________        
    case('Reward')
               
        set(h.status,'string','Rewarding - Please wait')
                      
       gf.status = 'PrepareStim';
end



