function logTrial(centerReward, response)                                                %#ok<*INUSL>

% Reports stimulus and response parameters 

global gf

if ischar(response), % Enter string as arguement to get header
    
    headings = {'Trial','CorrectionTrial?','StartTime','CenterReward?',...
                'Modality','Location','HoldTime','Atten',...
                'Duration','LED_V','Spkr_MF','LED_bgrd_V','Spkr_bgrd_V',...
                'Response','RespTime','Correct'};

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
    
    if isfield(gf,'speaker'),
        correct = response == gf.speaker;      %#ok<*NASGU>
    else
        correct = -1;
    end

    %           variable                 format            
    output = {'gf.TrialNumber'          ,'%d'   ;
              'gf.correctionTrial'      ,'%d'   ;
              'gf.startTrialTime'       ,'%.3f' ;
              'centerReward'            ,'%d'   ;
              'gf.modality'             ,'%d'   ;
              'gf.speaker'              ,'%d'   ;
              'gf.holdTime'             ,'%.3f' ;
              'gf.atten'                ,'%.2f' ;
              'gf.duration'             ,'%.2f' ;
              'gf.LED_stim_V'           ,'%.2f' ;
              'gf.Spkr_stim_MF'         ,'%.2f'   ;
              'gf.LED_bgnd_V'           ,'%.2f' ;
              'gf.Spkr_bgnd_V'          ,'%.5f' ;
              'response'                ,'%d'   ;
              'gf.responseTime'         ,'%.3f' ;
              'correct'                 ,'%d'   };


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
 
 
 