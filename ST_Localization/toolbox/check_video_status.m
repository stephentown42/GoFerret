function check_video_status
%
% Check if video software (python script) can communicate with TDT and
% restart script if not
%
% GLOBALS:
%   - gf: GoFerret structure with paths for python script to be run
%   - DA: COM object for communication with TDT
%
% OUTPUT:
%   - gf.video_check: binary value as to whether the check has been
%   performaed
%
% Stephen Town = 18 March 2020

global gf DA

% Get status of python from TDT intermediary
status = DA.GetTargetVal( sprintf('%s.readPyControl', gf.stimDevice));        

% Initialize if not yet defined
if ~isfield(gf, 'video_check'), gf.video_check = 0; end

% If the fix has been attempted, but failed, try again
if gf.video_check == 1 && status == 0
    gf.video_check = 0;
end

% If video isn't playing
if status == 0
    
    % If time elapsed is an interval of 5
    if mod(gf.sessionTime, 5) 
        
        if  gf.video_check == 0
            eval( sprintf('!python %s & exit &',  gf.video_path))
            pause(0.5)
            gf.video_check = 1;
        end
    else
        gf.video_check = 0;
    end
else
    gf.video_check = 1;
end