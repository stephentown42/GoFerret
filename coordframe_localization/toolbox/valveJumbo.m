function valveJumbo( valveID, openTime)
%
% Open Time in seconds


% Open TDT connection if it doesn't already exist - dump this, it's so
% slow...
% if isempty(whos('global','DA'))
%     
%     ttFig = figure;
%     DA = actxcontrol('TDevAcc.X');
%     DA.ConnectServer('Local');
%     DA.SetSysMode(2);
%     fprintf('Creating new connection to TDT for valve\n')
%     pause(3)    % Allow the device to start up
% else
    global DA gf h   
% end

    % Convert openTime from seconds to samples    
    openTime = openTime * DA.GetDeviceSF('RX8');

    % Set time for valve to be open  
    DA.SetTargetVal(sprintf('RX8.valve%02d_time', valveID), openTime);  

    % Trigger valve
    DA.SetTargetVal(sprintf('RX8.valve%02d', valveID), 1);  
    DA.SetTargetVal(sprintf('RX8.valve%02d', valveID), 0);      
   
    % Close system if TDT connection wasn't originally open
% if isempty(whos('global','DA'))
%     DA.SetSysMode(0);    % Set device to idle 
%     DA.CloseConnection; % Close connections and windows
%     close(ttFig);
% end

    % Update time line
    if isfield(h,'timelineA')
       
        axes(h.timelineA);
        hold on;
        plot( gf.sessionTime, valveID,'^k');
    end