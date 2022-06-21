function logTrial(centerReward, response)                                                %#ok<*INUSL>

% Reports stimulus and response parameters 

global gf

if ischar(response), % Enter string as arguement to get header
    if isempty(strfind(gf.filename,'level13_WE'))
        headings = {'Trial','CorrectionTrial?','StartTime','CenterReward?','HoldTime','Atten',...
            'Reference','Target','Side','Response','RespTime','Correct'};
    elseif any(strfind(gf.filename,'level13_WE'))
        headings = {'Trial','CorrectionTrial?','StartTime','CenterReward?','HoldTime','Atten',...
            'Reference','Target','Side','Response','RespTime','Correct','distractorLoc'};
    elseif any(strfind(gf.filename,'level14_WE'))
            headings = {'Trial','CorrectionTrial?','StartTime','CenterReward?','HoldTime','Atten',...
            'Reference','Target','Side','Response','RespTime','Correct','doubleRefLoc'};
    end
        for i = 1 : length(headings),
            fprintf(gf.fid, '%s\t', headings{i});
        end

    fprintf(gf.fid,'\n');
    
    % Initiate trial number
    gf.TrialNumber  = 1;
else    
    
    if ~isfield(gf,'side'),
        gf.side = -99;
    end
    
    if ~isfield(gf,'holdTime'),
        gf.holdTime = -99;
    end

    if ~isfield(gf,'atten'),
        gf.atten = -99;
    end

    
    
%     %For levels with multiple sounds
%     for i = 1 : 10,
%         fieldName = sprintf('sound%d',gf.side);
%         
%         if isfield(gf, fieldName)
%             f = eval(sprintf('gf.sound%d',gf.side));       % Sessions involving multiple sounds  
%         end
%     end
    
   
        if gf.side==2 && gf.resp==2;
            correct = 1;
        elseif gf.side==8 && gf.resp==8
            correct = 1;
        else
            correct=0;
        end
    
if isempty(strfind(gf.filename,'level13_WE')) & isempty(strfind(gf.filename,'level14_WE'))
    %           variable                 format            
    output = {'gf.TrialNumber'          ,'%d'   ;
              'gf.correctionTrial'      ,'%d'   ;
              'gf.startTrialTime'       ,'%.3f' ;
              'centerReward'            ,'%d'   ;
              'gf.holdTime'             ,'%d'   ;
              'gf.atten'                ,'%.1f' ;
              'gf.refChoice'            ,'%d'   ;
              'gf.tarChoice'            ,'%d'   ;
              'gf.side'                 ,'%d'   ;
              'response'                ,'%d'   ;
              'gf.responseTime'         ,'%.3f' ;
              'correct'                 ,'%d'   };
else
      %           variable                 format            
    output = {'gf.TrialNumber'          ,'%d'   ;
              'gf.correctionTrial'      ,'%d'   ;
              'gf.startTrialTime'       ,'%.3f' ;
              'centerReward'            ,'%d'   ;
              'gf.holdTime'             ,'%d'   ;
              'gf.atten'                ,'%.1f' ;
              'gf.refChoice'            ,'%d'   ;
              'gf.tarChoice'            ,'%d'   ;
              'gf.side'                 ,'%d'   ;
              'response'                ,'%d'   ;
              'gf.responseTime'         ,'%.3f' ;
              'correct'                 ,'%d'   ;
              'gf.distractorLoc'           ,'%d'  };
end


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
 
 
 