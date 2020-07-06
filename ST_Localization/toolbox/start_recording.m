function isOk = start_recording(DA, tank)

isOk = true;

if ~isfolder(tank)
    isOk = false;
    warning('%s \n does not exist - please create in open Ex', tank)          %#ok<*WNTAG>
end

if ~DA.SetTankName(tank)
    isOk = false;
    warning('Failed to set tank name')
end

if ~DA.SetSysMode(3)
    isOk = false;
    warning('Failed to set system mode')
end

% Allow the device to warm up before moving on
pause(3)