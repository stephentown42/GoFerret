function varargout = online(varargin)
% ONLINE MATLAB code for online.fig
%      ONLINE, by itself, creates a new ONLINE or raises gfe existing
%      singleton*.
%
%      H = ONLINE returns gfe handle to a new ONLINE or gfe handle to
%      gfe existing singleton*.
%
%      ONLINE('CALLBACK',hObject,eventData,handles,...) calls gfe local
%      function named CALLBACK in ONLINE.M wigf gfe given input arguments.
%
%      ONLINE('Property','Value',...) creates a new ONLINE or raises gfe
%      existing singleton*.  Starting from gfe left, property value pairs are
%      applied to gfe GUI before online_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to online_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit gfe above text to modify gfe response to help online

% Last Modified by GUIDE v2.5 16-Jan-2012 17:31:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @online_OpeningFcn, ...
                   'gui_OutputFcn',  @online_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before online is made visible.
function online_OpeningFcn(hObject, ~, handles, varargin)



global DA gf h saveData

gf.TrialNumber  = 1;
saveData = {};
handles.output = hObject;
guidata(hObject, handles);
h = handles;


% Establish connection with TDT 
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');

% Ensure correct project is on RX8
ProjectID = DA.GetTargetVal(sprintf('%s.ProjectID', gf.stimDevice));

% if ProjectID ~= -59
%     
%     % Close connections and windows
%     DA.CloseConnection;
%     close(handles.figure1)
%     
%     % Restore default paths
%     path(gf.defaultPaths)
% 
%     % Delete structures
%     clear global DA gf h
%     clear
%     gf = [];
% 
%     % Warn user
%     error('You have failed to select the correct project and circuit - this organization does not tolerate failure!')
% end

% Establish connection with TDT and find out sample rates
choice = MFquestdlg([0.2, 0.5],'Do you want to record neural data to tank during task?', 'Neural Recordings',...
    'Yes-LEFT', 'Yes-RIGHT','No','Yes-LEFT');


switch choice
    
    case 'Yes-LEFT'
        
        gf.tankDir='F:\UCL_Behaving\';
        sl=strfind(gf.saveDir,'\');
        gf.subjectDir=gf.saveDir(sl(end)+1:end);
        gf.tankDir = fullfile(gf.tankDir, gf.subjectDir);
        
        if ~isdir(gf.tankDir),
            warning('Tank \n %s \n does not exist - please create in open Ex')          %#ok<*WNTAG>
        end
        
        DA.SetTankName(gf.tankDir)
        DA.SetSysMode(3);
        
        pause(3)
        
        % Get block name
        TT = actxcontrol('TTank.X');
        TT.ConnectServer('Local','Me');
        tankOpen=TT.OpenTank(gf.tankDir,'R')
        pause(1)
        gf.recBlock = TT.GetHotBlock;
        gf.recBlock = TT.GetHotBlock
        TT.CloseTank;
        TT.ReleaseServer;
        clear TT
        
        if isempty(gf.recBlock),
            gf.recBlock = 'UnknownBlock';
            
            disp('Unknown Block - start GoFerret again')
            %             % Set device to idle
            % (This avoids sounds/lights being produced when you no longer have GUI control)
            DA.SetSysMode(0);
            
            % Close connections and windows
            DA.CloseConnection
            
            close(handles.figure1)
            
            % Restore default paths
            path(gf.defaultPaths)
            
            % Delete structures
            clear global DA gf h saveData
            clear
        end
        t = fix(clock);
        paramFile = gf.paramFile(1:length(gf.paramFile)-4);
        temp{1}  = sprintf('%d-%d-%d',t(3),t(2),t(1));
        temp{2}  = sprintf('%d:%d:%d',t(4),t(5),t(6));
        filename  = sprintf('%d_%d_%d %s %d_%d_%s_LHS log.txt', t(3), t(2), t(1), paramFile, t(4), t(5), gf.recBlock);      % Time Filename log.txt
        gf.saveName = sprintf('%d_%d_%d %s %d_%d_%s_LHS log', t(1), t(2), t(3), paramFile, t(4), t(5), gf.recBlock);
        
    case 'Yes-RIGHT'
                
        gf.tankDir='F:\UCL_Behaving\';
        sl=strfind(gf.saveDir,'\');
        gf.subjectDir=gf.saveDir(sl(end)+1:end);
        gf.tankDir = fullfile(gf.tankDir, gf.subjectDir);
        
        if ~isdir(gf.tankDir),
            warning('Tank \n %s \n does not exist - please create in open Ex')          %#ok<*WNTAG>
        end
        
        DA.SetTankName(gf.tankDir)
        DA.SetSysMode(3);
        
        pause(3)
        
        % Get block name
        TT = actxcontrol('TTank.X');
        TT.ConnectServer('Local','Me');
        tankOpen=TT.OpenTank(gf.tankDir,'R')
        pause(1)
        gf.recBlock = TT.GetHotBlock;
        gf.recBlock = TT.GetHotBlock;
        TT.CloseTank;
        TT.ReleaseServer;
        clear TT
        

        t = fix(clock);
        paramFile = gf.paramFile(1:length(gf.paramFile)-4);
        temp{1}  = sprintf('%d-%d-%d',t(3),t(2),t(1));
        temp{2}  = sprintf('%d:%d:%d',t(4),t(5),t(6));
        filename  = sprintf('%d_%d_%d %s %d_%d_%s_RHS log.txt', t(3), t(2), t(1), paramFile, t(4), t(5), gf.recBlock);      % Time Filename log.txt
        gf.saveName = sprintf('%d_%d_%d %s %d_%d_%s_RHS log', t(1), t(2), t(3), paramFile, t(4), t(5), gf.recBlock);
        
%         if isempty(gf.recBlock),
%             gf.recBlock = 'UnknownBlock';
%             
%             disp('Unknown Block - start GoFerret again')
%             %             % Set device to idle
%             % (This avoids sounds/lights being produced when you no longer have GUI control)
%             DA.SetSysMode(0);
%             
%             % Close connections and windows
%             DA.CloseConnection
%             
%             close(handles.figure1)
%             
%             % Restore default paths
%             path(gf.defaultPaths)
%             
%             % Delete structures
%             clear global DA gf h saveData
%             clear
%         end
        
    case 'No'
        
        sl=strfind(gf.saveDir,'\');
        gf.subjectDir=gf.saveDir(sl(end)+1:end);
        
        %DAfig = figure('position',[0 0 100 100],'visible','on');
        
        DA = actxcontrol('TDevAcc.X');
        DA.ConnectServer('Local');
        gf.systemStatus = DA.SetSysMode(2);
        errorCount = 0;
        
        while ~gf.systemStatus && errorCount < 10
            
            errorCount = errorCount + 1;
            clear global DA
            fprintf('Redialing TDT - stupid!!!\n')
            DA = actxcontrol('TDevAcc.X');
            DA.ConnectServer('Local');
            gf.systemStatus = DA.SetSysMode(2);
            pause(3)
        end
        
        if ~gf.systemStatus
            error('Could not start TDT')
        end
        t = fix(clock);
        paramFile = gf.paramFile(1:length(gf.paramFile)-4);
        temp{1}  = sprintf('%d-%d-%d',t(3),t(2),t(1));
        temp{2}  = sprintf('%d:%d:%d',t(4),t(5),t(6));
        filename  = sprintf('%d_%d_%d %s %d_%d log.txt', t(3), t(2), t(1), paramFile, t(4), t(5));      % Time Filename log.txt
        gf.saveName = sprintf('%d_%d_%d %s %d_%d log', t(1), t(2), t(3), paramFile, t(4), t(5));
        
        pause(3)
end
    gf.fStim = DA.GetDeviceSF(gf.stimDevice);       %was Srate in jenny's code but changed to accomodate multiple devices
%gf.fRec  = DA.GetDeviceSF(gf.recDevice);
    

% send trigger to TDT for start pulse for wireless
    pause(2)
    DA.SetTargetVal('RX8.startPulse', 1);
    DA.SetTargetVal('RZ2.startPulse', 1);
    pause(0.5)
    DA.SetTargetVal('RX8.startPulse', 0);
    DA.SetTargetVal('RZ2.startPulse', 0);
   
    % Reset all parameter tags

    tags = {'bit0C','bit1C','bit2C','bit4C','bit5C','bit6C','bit7C',...
            'leftLick','centerLick','rightLick',...
            'leftValve','centerValve','rightValve'};

    for i = 1 : length(tags)

        tag = sprintf('%s.%s',gf.stimDevice, tags{i});
        DA.SetTargetVal(tag,0);   
    end

%Set date 
set(handles.dateH,'string',sprintf('%s\n%s\n',temp{1},temp{2}))
    
% Make a new tab delimited file 
cd(gf.saveDir)

            % Remove extension from file name
gf.fid    = fopen(filename, 'wt');

logTrial(0,'header')  % Writes header in log

set(h.saveTo, 'string', strcat('Save to: ',gf.saveDir,'\', filename))

%Set devices
set(handles.devices,'string',sprintf(' %s \n %.3f',gf.stimDevice, gf.fStim))

% Initialize GUI control parameters    

if isfield(gf,'holdMin') && isfield(gf,'holdSteps') && isfield(gf,'holdMax'),
    set(handles.editHoldMin,    'string', num2str(gf.holdMin))  
    set(handles.editHoldSteps,  'string', num2str(gf.holdSteps)) 
    set(handles.editHoldMax,    'string', num2str(gf.holdMax))    
end

if isfield(gf,'attenMin') && isfield(gf,'attenSteps') && isfield(gf,'attenMax'),
    set(handles.editAttenMin,   'string', num2str(gf.attenMin))
    set(handles.editAttenSteps, 'string', num2str(gf.attenSteps))
    set(handles.editAttenMax,   'string', num2str(gf.attenMax))   
end

set(handles.slideCenterRewardP, 'value', gf.centerRewardP)
set(handles.editCenterRewardP, 'string', num2str(gf.centerRewardP))

% Initialize GUI circuit control
set(handles.enableControl,'value',0)


    
% Position Online GUI
    set(h.figure1, 'units',         'centimeters',...
                   'position',      [ 0   14   33    9.5442],...
                   'KeyPressFcn',   @KeyPress)

% Performance               
    % Create figure
    h.performanceF = figure('NumberTitle',    'off',...
                             'name',           'Performance (no trials yet completed)',...
                             'color',          'w',...
                             'units',          'centimeters',...
                             'position',       [17.6079    1.2690   30.1396    8.5131],...
                             'MenuBar',        'none',...
                             'KeyPressFcn',    @KeyPress);    
    % Create axes            
    gf.performance = zeros(12,12,2);
    
    h.performanceA(1) = subplot(1,2,1); 
    h.performanceM(1) = imagesc(gf.performance(:,:,1));    
    h.colorbar = colorbar;
    xlabel('Response Location')
    ylabel('Target Location')
    ylabel(h.colorbar,'N Trials','FontSize',8)
    title('Visual Trials')
    
    h.performanceA(2) = subplot(1,2,2); 
    h.performanceM(2) = imagesc(gf.performance(:,:,2));   
    h.colorbar = colorbar;
    xlabel('Response Location')
    ylabel('Target Location')
    ylabel(h.colorbar,'N Trials','FontSize',8)
    title('Auditory Trials')
    
    gf.performance = repmat(gf.performance,[1 1 numel(gf.modalities)]);
    set(h.performanceA, 'FontSize',     8,...
                        'FontName',     'arial',...
                        'color',        'none',...
                        'xcolor',       'k',...
                        'xdir',         'normal',...
                        'ycolor',       'k');
        
    
    
   
                   
% Timeline               
    % Create figure
    h.timelineF = figure('NumberTitle',    'off',...
                          'name',           'Timeline',...
                          'color',          'w',...
                          'units',          'centimeters',...
                          'position',       [0.3969    1.6140   14.7638   24.2094],...
                          'MenuBar',        'none',...
                          'KeyPressFcn',    @KeyPress);    

    % Create axes labels
    yticklabels = cell(12,1);
    
    for i = 1 : 12
        yticklabels{i} = sprintf('IR%02d',i);
    end
    
    yticklabels{6} = 'Center';
                 
    % Create axes
    h.timelineA = axes('position',   [0.1 0.1 0.85 0.85],...
                        'FontSize',   8,...
                        'FontName',   'arial',...
                        'color',      'none',...
                        'ylim',       [0 13],...
                        'ytick',      1:12,...
                        'yticklabel', yticklabels);
                    

    xlabel('Time (seconds)')    

    % Update online position
    set(h.figure1, 'units',         'centimeters',...
               'position',      [ 0   14   33    9.5442],...
               'KeyPressFcn',   @KeyPress)
       
   %Create a TCPIP object to talk to other matlabs
   try
       h.tcpip = tcpip('localhost', 30000, 'NetworkRole', 'client');
       fopen(h.tcpip);
   catch
       
%        Data = 1:64;
%        Data = (Data'*Data)/64;
%        Str  = 'Warning: IP connection failed, please check webcam and use for tracking';
%        msgbox(Str,'Title','custom',Data,hot(64))
%        msgbox('')
%        h.tcpip = NaN;
   end

% Setup timer
    h.tasktimer = timer( 'TimerFcn',         sprintf('%s',gf.filename),...
                        'BusyMode',         'drop',...
                        'ExecutionMode',    'fixedRate',...
                        'Period',           gf.period);                    
                
    gf.startTrialTime  = 0;
    gf.startTime       = now;
    gf.centerStatus    = 0;
    gf.status          = 'PrepareStim';
    
%     if gf.subjectDir == 'F1507_Emu'||gf.subjectDir =='F1504_Kiwi'||gf.subjectDir =='F1510_Beaker'
%         gf.ferretIntensity = 0.6;
%     else
%         gf.ferretIntensity = 0.36;
%     end
    
    % number of correct/total trials at start is zero.
    gf.visCorrect = 0;
    gf.audCorrect = 0;
    gf.totalVisNonCorr = 0;
    gf.totalAudNonCorr = 0;
    
    DA.SetTargetVal( sprintf('%s.centerEnable',gf.stimDevice), 1)
    
    if isvalid(h.tasktimer) == 1,
        start(h.tasktimer);
    end


function varargout = online_OutputFcn(~, ~, ~)  %#ok<STOUT>
%varargout{1} = handles.output;

global h

set(h.figure1, 'units',         'centimeters',...
               'position',      [ 0   14   33    9.5442],...
               'KeyPressFcn',   @KeyPress)


%%%%%%%%%%%%%%%%%%%%%%% CONTROLABLE PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% gf.variable = str2num( get(handles.variable,'value'))
% 

% Hold time controls
function setHoldMin_Callback(~, ~, handles)

global gf
gf.holdMin = str2num( get(handles.editHoldMin,'string')); %#ok<*ST2NM>

function setHoldSteps_Callback(~, ~, handles)

global gf
gf.holdSteps = str2num( get(handles.editHoldSteps,'string'));

function setHoldMax_Callback(~, ~, handles)

global gf
gf.holdMax = str2num( get(handles.editHoldMax,'string'));


% Attenuation controls
function setAttenMin_Callback(~, ~, handles)

global gf
gf.attenMin = str2num( get(handles.editAttenMin,'string'));

function setAttenSteps_Callback(~, ~, handles)

global gf
gf.attenSteps = str2num( get(handles.editAttenSteps,'string'));

function setAttenMax_Callback(~, ~, handles)

global gf
gf.attenMax = str2num( get(handles.editAttenMax,'string'));


% Pitch controls
function setPitchMin_Callback(~, ~, handles)

global gf
gf.pitchMin = str2num( get(handles.editPitchMin,'string'));

function setPitchSteps_Callback(~, ~, handles)

global gf
gf.pitchSteps = str2num( get(handles.editPitchSteps,'string'));

function setPitchMax_Callback(~, ~, handles)

global gf
gf.pitchMax = str2num( get(handles.editPitchMax,'string'));

% Valve time controls

function setLeftValveTime_Callback(~, ~, handles)

global gf
gf.leftValveTime = str2num( get(handles.editLeftValveTime,'string')); 

function setCenterValveTime_Callback(~, ~, handles)

global gf
gf.centerValveTime = str2num( get(handles.editCenterValveTime,'string')); 

function setRightValveTime_Callback(~, ~, handles)

global gf
gf.rightValveTime = str2num( get(handles.editRightValveTime,'string')); 




%%%%%%%%%%%%%%%%%%%%%%%%%%%% Key Press %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Monitors key pressed when online GUI is current figure
%
%	Key:        name of the key that was pressed, in lower case
%	Character:  character interpretation of the key(s) that was pressed
%	Modifier:   name(s) of the modifier key(s) (i.e., control, shift) pressed
%
function KeyPress(src,event)

global gf

if strcmp(event.Key,'equal')
    valveJumbo(6,gf.valveTimes(6))
end

% Valves based on F numbers
for i = 1 : 12    
   if strcmp(event.Key,sprintf('f%d',i))
       valveJumbo(i, gf.valveTimes(i))
   end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Circuit Controls %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Buttons that allow the user interface to control parameters within the
% RPvdsEX circuit directly.

% Safety switch 
function enableControl_Callback(~, ~, handles)

global DA gf

%Update all control tickboxes
set(handles.bit0C,'Value', DA.GetTargetVal(sprintf('%s.bit0C',gf.stimDevice)))
set(handles.bit1C,'Value', DA.GetTargetVal(sprintf('%s.bit1C',gf.stimDevice)))
set(handles.bit2C,'Value', DA.GetTargetVal(sprintf('%s.bit2C',gf.stimDevice)))
set(handles.bit7C,'Value', DA.GetTargetVal(sprintf('%s.bit7C',gf.stimDevice)))

%Bit 0 Control
function bit0C_Callback(~, ~, handles)

global DA gf

if get(handles.enableControl,'value') == 1,

    tag = sprintf('%s.bit0C',gf.stimDevice);
    val = get(handles.bit0C,'value');

    DA.SetTargetVal(tag, val);
end

%Bit 1 Control
function bit1C_Callback(~, ~, handles)

global DA gf

if get(handles.enableControl,'value') == 1,

    tag = sprintf('%s.bit1C',gf.stimDevice);
    val = get(handles.bit1C,'value');

    DA.SetTargetVal(tag, val);
end

%Bit 2 Control
function bit2C_Callback(~, ~, handles)

global DA gf

if get(handles.enableControl,'value') == 1,

    tag = sprintf('%s.bit2C',gf.stimDevice);
    val = get(handles.bit2C,'value');

    DA.SetTargetVal(tag, val);
end

%Bit 7 Control
function bit7C_Callback(~, ~, handles)

global DA gf

if get(handles.enableControl,'value') == 1,

    tag = sprintf('%s.bit7C',gf.stimDevice);
    val = get(handles.bit7C,'value');

    DA.SetTargetVal(tag, val);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% Valve Controls %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Left Valve Control
function leftValveC_Callback(~, ~, handles)

global gf

if get(handles.leftValveC,'value') == 1 && get(handles.enableControl,'value') == 1,
    valve(4, gf.leftValveTime, 1, 'left');                                                 %valve(bit, pulse time, pulse number, %sValve)
end

%Center Valve Control
function centerValveC_Callback(~, ~, handles)

global gf

if get(handles.centerValveC,'value') == 1 && get(handles.enableControl,'value') == 1,
    valve(6, gf.centerValveTime, 1, 'center'); 
end

%Right Valve Control
function rightValveC_Callback(~, ~, handles)

global gf

if get(handles.rightValveC,'value') == 1 && get(handles.enableControl,'value') == 1,
    valve(5, gf.rightValveTime, 1, 'right'); 
end

function slideCenterRewardP_Callback(~, ~, handles)

global gf

val = get(handles.slideCenterRewardP,'value');

set(handles.editCenterRewardP, 'string', sprintf('%.2f',val));
gf.centerRewardP = val;


function editCenterRewardP_Callback(~, ~, handles)

global gf

str              = get(handles.editCenterRewardP,'string');  
gf.centerRewardP = str2num(str); %#ok<ST2NM>



%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GRAPHICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%PLOT SOUND WAVEFORM
function plotWaveform_Callback(~, ~, ~)

plotWaveform   %see toolbox


%PLOT SPECTROGRAM OF STIMULUS
function plotSpectrogram_Callback(~, ~, ~)

plotSpectrogram % see toolbox


%%%%%%%%%%%%%%%%%%%%%%%%% EXIT BUTTON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Exit_Callback(~, ~, handles)                                 %#ok<*DEFNU>

global DA gf h      

% Check valves are closed
tags = {'valve1out','valve2out','valve8out'};
val  = NaN(3,1);

for i = 1 : length(tags)
    
    tag    = sprintf('%s.%s',gf.stimDevice, tags{i});
    val(i) = DA.GetTargetVal(tag);   
end

if any(val)    
    msgbox('Warning: Valves open. Please close manually or wait until closed\n Program will not close until valves do')
    val
else

    % Reset all parameter tags
    % tags = {'bit0C','bit1C','bit2C','bit4C','bit5C','bit6C','bit7C',...
    %         'leftLick','centerLick','rightLick',...
    %         'leftValve','centerValve','rightValve'};
    % 
    % for i = 1 : length(tags)
    %     
    %     tag = sprintf('%s.%s',gf.stimDevice, tags{i});
    %     DA.SetTargetVal(tag,0);   
    % end
    
    % Close log file
    fclose(gf.fid);
    
    
    % Close tcpip connection
    if isa(h.tcpip,'tcpip')
         if strcmp('open', h.tcpip.Status)
            fwrite(h.tcpip, 1);
            h.tcpip;
            fclose(h.tcpip);
            delete(h.tcpip);
         end
    end
    
    % Stop task timer
    stop(h.tasktimer);
    
    % Set device to idle 
    % (This avoids sounds/lights being produced when you no longer have GUI control)
    
    % send end pulse to TDT for synchronisation with wireless
    DA.SetTargetVal('RX8.endPulse', 1);
    DA.SetTargetVal('RZ2.endPulse', 1);
    pause(0.5)
    DA.SetTargetVal('RX8.endPulse', 0);
    DA.SetTargetVal('RZ2.endPulse', 0);
    
    pause(2) % so end pulse has time to complete before TDT shuts down
    
    DA.SetSysMode(0); % turns off TDT

    % Close connections and windows
    DA.CloseConnection

    close(handles.figure1)
    close(h.timelineF)
    close(h.performanceF)

    % Restore default paths
    path(gf.defaultPaths)


    visPercent = round(gf.visCorrect/gf.totalVisNonCorr *100);
    audPercent = round(gf.audCorrect/gf.totalAudNonCorr *100);
    
    disp (['Number of trials = ',num2str(gf.TrialNumber-1)])
    disp (['Visual performance = ', num2str(gf.visCorrect),'/',num2str(gf.totalVisNonCorr), ': ', num2str(visPercent),'%'])
    disp (['Auditory performance = ', num2str(gf.audCorrect),'/',num2str(gf.totalAudNonCorr), ': ', num2str(audPercent),'%'])
    
%     if exist('saveData', 'var')
%         T = dotmatTable(saveData);
%         save([gf.saveName ' TABLE.mat'], 'T');
%     end
%     
    % Delete structures
    clear global DA gf h saveData
    clear

    gf = [];
    
    disp('session ended')
    disp('All structures removed and default paths restored')
    
end



function leftLick_Callback(~,~,~)
function rightLick_Callback(~,~,~)
function centerLick_Callback(~,~,~)
function bit0_Callback(~,~,~)
function bit1_Callback(~,~,~)
function bit2_Callback(~,~,~)
function bit4_Callback(~,~,~)
function bit5_Callback(~,~,~)
function bit6_Callback(~,~,~)
function bit7_Callback(~,~,~)
function leftValve_Callback(~,~,~)
function rightValve_Callback(~,~,~)
function centerValve_Callback(~,~,~)
function led_Callback(~,~,~)

function editHoldMax_Callback(~, ~, ~)
function editHoldMax_CreateFcn(~, ~, ~)
function editHoldSteps_Callback(~, ~, ~)
function editHoldSteps_CreateFcn(~, ~, ~)
function editHoldMin_Callback(~, ~, ~)
function editHoldMin_CreateFcn(~, ~, ~)

function editAttenMax_Callback(~, ~, ~)
function editAttenMax_CreateFcn(~, ~, ~)
function editAttenSteps_Callback(~, ~, ~)
function editAttenSteps_CreateFcn(~, ~, ~)
function editAttenMin_Callback(~, ~, ~)
function editAttenMin_CreateFcn(~, ~, ~)

function editPitchMax_Callback(~, ~, ~)
function editPitchMax_CreateFcn(~, ~, ~)
function editPitchSteps_Callback(~, ~, ~)
function editPitchSteps_CreateFcn(~, ~, ~)
function editPitchMin_Callback(~, ~, ~)
function editPitchMin_CreateFcn(~, ~, ~)

function editLeftValveTime_Callback(~, ~, ~)
function editLeftValveTime_CreateFcn(~, ~, ~)
function editRightValveTime_Callback(~, ~, ~)
function editRightValveTime_CreateFcn(~, ~, ~)
function editCenterValveTime_Callback(~, ~, ~)
function editCenterValveTime_CreateFcn(~, ~, ~)

function slideCenterRewardP_CreateFcn(~, ~, ~)
function editCenterRewardP_CreateFcn(~, ~, ~)

