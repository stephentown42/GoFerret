function should_skip = check_online_stim_limit(target)
%
% INPUT:
%   - target: index of target spout location (e.g. 3 or 9) that should be
%   accepted
%
% SETTINGS / GLOBALS:
%   - h: handles to graphics objects running in GoFerret
%       - h.stim_limit: check box indicating whether to restrict trials to a
%                       particular target spout
%       -h.limit_menu: drop-down menue with list of spouts that trials may
%                       be limited to
%
% OUTPUT:
%   - logical_val: value (true/false) indicating whether current trial
%   should be skipped
%
% Stephen Town 2019

% Load global containing handles to graphics objects
global h

% Define default (no values should be skipped)
should_skip = false;

% If check-box is ticked
if get(h.stim_limit,'value') == 1
   
    % Get the drop-down menu info
   limit_str = get(h.limit_menu,'string');
   limit_val = get(h.limit_menu,'value');
   
   % Get spout number from string in menubar
   limit_str = limit_str{ limit_val};
   limit_str = strrep(limit_str, 'Spout ','');
   limit_val = str2double( limit_str);
   
   % Decide if should skip
   should_skip = target ~= limit_val;   
end