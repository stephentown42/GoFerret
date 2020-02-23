function inSig = tdtSys3playAndRecord(data, stimDevice,recDevice,spkrIdx,fStim)
%
% Connects to TDT, writes sound to buffer and plays it through DAC outputs.
% Records sound from ADC inputs and returns recorded vector.

% Connect to System 3

global DA

% %
% figure
% plot(data)
DA.SetSysMode(2); pause(2);

tRec =  length(data);% + 0.1*fStim;
% Engage TDT (preview mode)
% Assign stimulus parameters to device
if DA.SetTargetVal( sprintf('%s.length',stimDevice), length(data)) && ...               % Number of stimulus samples
   DA.WriteTargetVEX( sprintf('%s.sound',stimDevice), 0, 'F32', data) &&...
   DA.SetTargetVal( sprintf('%s.length',stimDevice),tRec)                  % Stimulus
else
    warning('Failed to Assign parameters to TDT')                           %#ok<*WNTAG>
end

% % Set spkrIdx if RX8
% if strcmp(stimDevice, 'RX8') && spkrIdx ~= 8,
%        
%     DA.SetTargetVal( sprintf('%s.sel1', stimDevice),  ceil(spkrIdx/4));
%     DA.SetTargetVal( sprintf('%s.sel10', stimDevice), spkrIdx-1);
%     DA.SetTargetVal( sprintf('%s.sel11', stimDevice), spkrIdx-5);     
% end


% Initiate play
disp( sprintf( 'Triggering sound (%.3f s)', length(data)/DA.GetDeviceSF(stimDevice)));

if strcmp(stimDevice, 'RX8') && spkrIdx == 8,
    
    if DA.SetTargetVal(sprintf('%s.play8',stimDevice),0) && ...
       DA.SetTargetVal(sprintf('%s.play8',stimDevice),1),

        pause(3)                                                        % Pause whilst sound plays
    else
        warning('Failed to initiate play') 
    end
    
else   
    DA.SetTargetVal( sprintf('%s.speaker', stimDevice), spkrIdx);    
    if DA.SetTargetVal(sprintf('%s.play',stimDevice),0) && ...
       DA.SetTargetVal(sprintf('%s.play',stimDevice),0) && ...
       DA.SetTargetVal(sprintf('%s.play',recDevice),1) && ...
         DA.SetTargetVal(sprintf('%s.play',stimDevice),1)
        pause(3)                                                        % Pause whilst sound plays
    else
        warning('Failed to initiate play') 
    end
end

% Read recorded data
L = max([tRec, 24415]);

switch recDevice
    case 'RZ6'

    inSig.chan1 = DA.ReadTargetVEX(sprintf('%s.recordA',stimDevice),0,L,'F32','F64');
    inSig.chan2 = DA.ReadTargetVEX(sprintf('%s.recordB',stimDevice),0,L,'F32','F64');

    case 'RZ6_1'
        
    inSig.chan1 = DA.ReadTargetVEX(sprintf('%s.recordA',recDevice),0,L,'F32','F64');
  %  inSig.chan2 = DA.ReadTargetVEX(sprintf('%s.record',stimDevice),0,L,'F32','F64');
end
    
% Set TDT to Standby
invoke(DA,'SetSysMode',0); 