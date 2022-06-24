function logTrial_FRA( varargin)                                                %#ok<*INUSL>

% Reports stimulus and response parameters 

global gf

% Initialize
if nargin > 0
    
    headings = {'Trial','StartTime','Duration','Frequency',...
                'Speaker_Location','dB_SPL'};

    for i = 1 : length(headings),
        fprintf(gf.fid, '%s\t', headings{i});
    end

    fprintf(gf.fid,'\n');
        
    gf.TrialNumber  = 1;

% Report trial parameters
else    
    
    output = {'gf.TrialNumber'          ,'%d'   ;
              'gf.startTrialTime'       ,'%.3f' ;
              'gf.duration'             ,'%.3f' ;
              'gf.current_freq'         ,'%.3f' ;
              'gf.Speaker'              ,'%d'   ;              
              'gf.current_dB'           ,'%.1f'};


    for i = 1 : length(output),

        variable = eval(output{i,1});
        format   = output{i,2};

        fprintf(gf.fid, format, variable);          % Print value
        fprintf(gf.fid,'\t');                       % Print delimiter (tab so that excel can open it easily)
    end

    fprintf(gf.fid,'\n');                           % Next line
    
    gf.TrialNumber  = gf.TrialNumber + 1;
end
 
 
 