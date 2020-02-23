function logTrial(centerReward, response)                                                %#ok<*INUSL>

% Reports stimulus and response parameters 

global gf

if ischar(response), % Enter string as arguement to get header
    
    headings = {'Trial','CorrectionTrial','StartTime','CenterReward','CenterSpoutRotation',...
                'nStimReps','Duration','Modality','LED_Location','LED_trial_V','LED_bgnd_V',...
                'Speaker_Location','Speaker_trial_V','Speaker_bgnd_V',...
                'TargetSpout','HoldTime','Response','RespTime','ValveTime',...
                'Correct','CenterPixelVal'};

        for i = 1 : length(headings),
            fprintf(gf.fid, '%s\t', headings{i});
        end

    fprintf(gf.fid,'\n');
    
    % Initiate trial number
    gf.TrialNumber  = 1;
else    
    
    % Default for cases where variables aren't relevant
    tags = {'holdTime','atten','modality','speaker'};
    
    for i = 1 : numel(tags)
        if ~isfield(gf,tags{i}),
            eval( sprintf('gf.%s = -99', tags{i}));
        end
    end
    
    if isfield(gf,'targetSpout'),
        correct = response == gf.targetSpout;      %#ok<*NASGU>
    else
        correct = -1;
    end

    if correct == 1,
        valveTime = gf.valveTimes(response);
    else
        valveTime = 0;
    end
    
    if ~isfield(gf,'trial_LED_stim_V'),
        gf.trial_LED_stim_V = gf.LED_stim_V;      %#ok<*NASGU>    
    end
    
    if ~isfield(gf,'trial_Spkr_stim_dB'),
        gf.Spkr_stim_dB = -1;
        gf.trial_Spkr_stim_dB = -1;
    end    
    
    if ~isfield(gf,'Spkr_bgnd_dB'),
        gf.Spkr_bgnd_dB = -1;
    end   
    
    if ~isfield(gf,'trial_Spkr_stim_dB'),
        gf.trial_Spkr_stim_MF = gf.Spkr_stim_dB;      %#ok<*NASGU>    
    end
    
    if ~isfield(gf,'centerSpoutRotation'),
        gf.centerSpoutRotation = 0;        
    end 
    
    %           variable                 format            
    output = {'gf.TrialNumber'          ,'%d'   ;
              'gf.correctionTrial'      ,'%d'   ;
              'gf.startTrialTime'       ,'%.3f' ;
              'centerReward'            ,'%d'   ;
              'gf.centerSpoutRotation'  ,'%d'   ;
              'gf.nStimRepeats'         ,'%d'   ;
              'gf.duration'             ,'%.3f' ;
              'gf.modality'             ,'%d'   ;
              'gf.LED'                  ,'%d'   ;
              'gf.trial_LED_stim_V'     ,'%.1f' ;
              'gf.LED_bgnd_V'           ,'%.1f' ;
              'gf.Speaker'              ,'%d'   ;              
              'gf.trial_Spkr_stim_dB'   ,'%.1f' ;
              'gf.Spkr_bgnd_dB'         ,'%.3f' ;
              'gf.targetSpout'          ,'%d'   ;
              'gf.holdTime'             ,'%.3f' ;
              'response'                ,'%d'   ;
              'gf.responseTime'         ,'%.3f' ;
              'valveTime'               ,'%.3f';
              'correct'                 ,'%d';
              'gf.centerPixelVal'       ,'%.0f'};


        for i = 1 : length(output),
        
            variable = eval(output{i,1});
            format   = output{i,2};
        
            fprintf(gf.fid, format, variable);          % Print value
            fprintf(gf.fid,'\t');                       % Print delimiter (tab so that excel can open it easily)
        end

        fprintf(gf.fid,'\n');                           % Next line
        
        % Move to next trial
        gf.TrialNumber  = gf.TrialNumber + 1;
end
 
 
 