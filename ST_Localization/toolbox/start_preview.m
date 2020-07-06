function start_preview(DA)

if ~DA.SetSysMode(2)
    warning('Failed to set system mode')
end

% Allow the device to warm up before moving on
pause(3)