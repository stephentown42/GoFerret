function logical_val = check_online_stim_limit(target)

global h

logical_val = false;

if get(h.stim_limit,'value') == 1
   
   limit_str = get(h.limit_menu,'string');
   limit_val = get(h.limit_menu,'value');
   
   limit_str = limit_str{ limit_val};
   limit_str = strrep(limit_str, 'Spout ','');
   limit_val = str2double( limit_str);
   
   logical_val = target ~= limit_val;   
end