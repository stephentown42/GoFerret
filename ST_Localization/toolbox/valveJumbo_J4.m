function valveJumbo_J4( valveID, openTime)
%
% Valve ID on clock-face
% Open Time in seconds


global DA gf h   

% Convert openTime from seconds to samples    
openTime = openTime * DA.GetDeviceSF('RX8');

% Get multiplexing setting
valveMux = getMUXfamily(valveID);

DA.SetTargetVal( sprintf('%s.Valv-mux-01', gf.stimDevice),  valveMux(1));
DA.SetTargetVal( sprintf('%s.Valv-mux-10', gf.stimDevice),  valveMux(2));  
DA.SetTargetVal( sprintf('%s.Valv-mux-11', gf.stimDevice),  valveMux(2));  
DA.SetTargetVal( sprintf('%s.Valv-mux-12', gf.stimDevice),  valveMux(2));  


% Set time for valve to be open 
DA.SetTargetVal('RX8.valveTime', openTime);  

% Label valve (if forces completion of label before trigger)
if DA.SetTargetVal('RX8.valveIdx',  valveID);  

    % Trigger valve
    DA.SetTargetVal('RX8.valveTrigger', 1);  
    DA.SetTargetVal('RX8.valveTrigger', 0);     
end



% Update time line
if isfield(h,'timelineA')

    axes(h.timelineA);
    hold on;
    plot( gf.sessionTime, valveID,'^k');
end

function y = getMUXfamily(x)

x = ['0' dec2base(x-1, 4)];   % Convert to quarternery numeral for mux input
x = ['0',x];                  % Add zero to cope with case where x < 0 and function returns shorter output
y = [str2num(x(end-1)), str2num(x(end))];    % Reformat from char to double
       

