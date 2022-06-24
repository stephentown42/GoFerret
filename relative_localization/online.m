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

% Last Modified by GUIDE v2.5 16-Nov-2012 15:19:51

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



global DA gf h


handles.output = hObject;
guidata(hObject, handles);
h = handles;

% Establish connection with TDT and find out sample rates

%DAfig = figure('position',[0 0 100 100],'visible','on');

DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');

% Choose whether to record or not
choice = MFquestdlg([0.2, 0.5],'Do you want to record neural data to tank during task?', 'Neural Recordings',...
    'Yes','No','Cancel','Yes');


switch choice
    
    case 'Yes'
        gf.tankDir='S:\Data\UCL_Behaving\';
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
            clear global DA gf h
            clear
        end
        
    case 'No'
        DA.SetSysMode(2); pause(3)
        gf.recBlock = 'log';
        
    case 'Cancel'
        return
end

%     DA.SetSysMode(1);

gf.fStim = DA.GetDeviceSF(gf.stimDevice);       %was Srate in jenny's code but changed to accomodate multiple devices
gf.fRec  = DA.GetDeviceSF(gf.recDevice);

if gf.fStim == 0, gf.fStim = 48828.125; end
if gf.fRec == 0, gf.fRec = 24414.0625; end


% Load the low pass filter (<22 kHz)
gf.SpkrLowPass=load('ferretSpkrLowPass.mat');





% Reset all parameter tags

tags = {'bit0C','bit1C','bit2C','bit4C','bit5C','bit6C','bit7C',...
    'leftLick','centerLick','rightLick',...
    'leftValve','centerValve','rightValve' ,'relCircuit'};

for i = 1 : length(tags)
    
    tag = sprintf('%s.%s',gf.stimDevice, tags{i});
    DA.SetTargetVal(tag,0);
end



% Check the circuit!
if isempty(strfind(gf.paramFile,'60shift'))
    if ~DA.SetTargetVal(sprintf('%s.relCircuit', gf.stimDevice),1)
        errordlg('WRONG PROJECT - please close GoFerret and change project');
        DA.SetSysMode(0);
        return
    end
else
    if ~DA.SetTargetVal(sprintf('%s.BPCircuit', gf.stimDevice),1)
        errordlg('WRONG PROJECT - please close GoFerret and change project');
        DA.SetSysMode(0);
        return
    end
end


%Set date
t = fix(clock);
temp{1}  = sprintf('%d-%d-%d',t(3),t(2),t(1));
temp{2}  = sprintf('%d:%d:%d',t(4),t(5),t(6));
set(handles.dateH,'string',sprintf('%s\n%s\n',temp{1},temp{2}))


% Make a new tab delimited file
cd(gf.saveDir)

paramFile = gf.paramFile(1:length(gf.paramFile)-4);                  % Remove extension from file name




filename  = sprintf('%d_%d_%d %s %d_%d %s.txt', t(3), t(2), t(1), paramFile, t(4), t(5),gf.recBlock);      % Time Filename log.txt
gf.fid    = fopen(filename, 'wt');
gf.dataName=filename;

logTrial(0,'header')  % Writes header in log

set(h.saveTo, 'string', strcat('Save to: ',gf.saveDir,'\', filename))

%Set devices
set(handles.devices,'string',sprintf(' %s \n %.3f',gf.stimDevice, gf.fStim))




% Initialize GUI control parameters
gf.subjectDir=[];
if strcmp(gf.subjectDir,'F1301_Ladybird')
    gf.holdMax=801;
end

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

%     if isfield(gf,'pitchRange'),
%         set(handles.editPitchMin,   'string', num2str(min(gf.pitchRange)))
%         set(handles.editPitchSteps, 'string', num2str(length(gf.pitchRange)))
%         set(handles.editPitchMax,   'string', num2str(max(gf.pitchRange)))
%     end
%
%     if isfield(gf,'pitchMin') && isfield(gf,'pitchSteps') && isfield(gf,'pitchMax'),
%         set(handles.editPitchMin,   'string', num2str(gf.pitchMin))
%         set(handles.editPitchSteps, 'string', num2str(gf.pitchSteps))
%         set(handles.editPitchMax,   'string', num2str(gf.pitchMax))
%     end

% set(handles.editLeftValveTime,  'string',num2str(gf.rewardTime))
set(handles.editCenterValveTime,'string',num2str(gf.rewardTime))
%set(handles.editRightValveTime, 'string',num2str(gf.rewardTime))


set(handles.editCenterRewardP, 'string', num2str(gf.centerRewardP))





% Position Online GUI
set(h.figure1, 'units',         'centimeters','KeyPressFcn',   @KeyPress)


%'position',      [ 0   14   33    9.5442],...
% Performance
% Create figure
h.performanceF = figure('NumberTitle',    'off',...
    'name',           'Performance (no trials yet completed)',...
    'color',          'k',...
    'units',          'centimeters',...
    'position',       [ 40   1.2426    9    5],...
    'MenuBar',        'none',...
    'KeyPressFcn',    @KeyPress);
% Create axes
h.performanceA = axes( 'position',      [0.1 0.1 0.6 0.85],...
    'FontSize',     8,...
    'FontName',     'arial',...
    'color',        'none',...
    'xcolor',       'w',...
    'xdir',         'reverse',...
    'xlim',         [0 10],...
    'ycolor',       'w',...
    'ylim',         [0 6],...
    'ytick',        1:5,...
    'yaxislocation','right',...
    'yticklabel',   {'Right - Incorrect','Right - Correct','Aborted','Left - Correct','Left - Incorrect'});
xlabel('Trials (n)')

% Create bars
colors = [255 160 122;   % Right-incorrect: lightsalmon1
    255 0   0  ;   % Right-correct: 	 red
    150 150 150;   % Aborted:         grey
    255 255 0  ;   % Left-correct:    yellow
    255 246 143];  % Left-incorrect:  kahki 1

for i = 1 : 5,
    hold on
    barh(i, 0, 'FaceColor', colors(i,:)/255, 'edgecolor','none','barWidth', 0.1)
    hold off
end

% Timeline
% Create figure
h.timelineF = figure('NumberTitle',    'off',...
    'name',           'Timeline',...
    'color',          'w',...
    'units',          'centimeters',...
    'position',       [34    7.5 15    5],...
    'MenuBar',        'none',...
    'KeyPressFcn',    @KeyPress);

h.timelineA = axes('position',   [0.1 0.1 0.85 0.85],...
    'FontSize',   8,...
    'FontName',   'arial',...
    'color',      'none',...
    'ylim',       [0 3.5],...
    'ytick',      [0.8 1.8 2.8],...
    'yticklabel', {'Left','Center','Right'});


xlabel('Time (seconds)')
ylabel('Events')

set(h.figure1, 'units',         'centimeters',...
    'position',      [ 29   15   21    9.5],...
    'KeyPressFcn',   @KeyPress)




% Set the NOISE LOOP
if strfind(gf.paramFile,'level11')
    load noiseDB24414.mat
    gf.noiseDB=noiseDB24414;
    gf.nDBsamps=floor(gf.fStim)*2;
    fs=strfind(gf.paramFile,'.');
    d=datevec(now);
    dd=[num2str(d(3)) '_' num2str(d(2)) '_' num2str(d(1))];
    dt=[num2str(d(4)) '_' num2str(d(5))];
    filenameN=[dd ' ' gf.paramFile(1:fs(1)-1) dt '_noiseIndices.txt'];
    gf.nDBfid=fopen(filenameN,'wt');
    gf.nDBstatus='initialize';
end


% Get the Reference/Target Locations
gf.nTar=size([gf.lTar,gf.rTar],2);


% Make a matrix with the parameter combinations

rlLtar(1:size(gf.lTar,2),gf.nRefSpks+1)=gf.lTar';
rlRtar(1:size(gf.rTar,2),gf.nRefSpks+1)=gf.rTar';

if isempty(strfind(gf.paramFile,'60shift'))
    for ii=1:gf.nRefSpks
        rlLtar(:,ii)=rlLtar(:,gf.nRefSpks+1)-(gf.nRefSpks+1-ii);
        rlRtar(:,ii)=rlRtar(:,gf.nRefSpks+1)+(gf.nRefSpks+1-ii);
    end
else
    for ii=1:gf.nRefSpks
        rlLtar(:,ii)=rlLtar(:,gf.nRefSpks+1)-(gf.nRefSpks+2-ii);
        rlRtar(:,ii)=rlRtar(:,gf.nRefSpks+1)+(gf.nRefSpks+2-ii);
    end
end

gf.rlp=[rlLtar;rlRtar];

if gf.extraHard
    if size(gf.rlp,2)>2
        gf.rlp=[gf.rlp;8,7,6;2,3,4;8,7,6;2,3,4;8,7,6;2,3,4];
    else
        gf.rlp=[gf.rlp;8,7;7,6;8,7;7,6;8,7;7,6;2,3;3,4;2,3;3,4;2,3;3,4];
    end
end

if gf.extraRight
    gf.rlp=[gf.rlp;10,9;11,10;12,11;13,12;14,13];
    gf.rlTrialIdx=randperm(size(gf.rlp,1));
    gf.rlTrialNo=1;
end

if gf.sameLoc
    same=[9,9;10,10;11,11;12,12;13,13;14,14];
    gf.rlp=[gf.rlp;gf.rlp;same];
else
    if size(gf.rlp,1)<5
        gf.rlp=repmat(gf.rlp,3,1);
    else
    end
end
gf.doOnce=0;
gf.rlTrialIdx=randperm(size(gf.rlp,1));
gf.rlTrialNo=1;
gf.filt=0;




% Setup timer
h.tasktimer = timer( 'TimerFcn',         sprintf('%s',gf.filename),...
    'BusyMode',         'drop',...
    'ExecutionMode',    'fixedRate',...
    'Period',           gf.period);

gf.pInd               = 0;
gf.lastPeripheralResp = 0;
gf.startTime          = now;
gf.status             = 'PrepareStim';

DA.SetTargetVal( sprintf('%s.centerEnable',gf.stimDevice), 1);

% Enable LEDs
if isfield(gf,'includeLEDs'),
    if gf.includeLEDs == 1,
        %
        %            DA.SetTargetVal( sprintf('%s.ledThreshold',gf.stimDevice), 0.1);
    end
end

if isvalid(h.tasktimer) == 1,
    start(h.tasktimer);
end


function varargout = online_OutputFcn(~, ~, ~)  %#ok<STOUT>
%varargout{1} = handles.output;

global h

set(h.figure1, 'units',         'centimeters','KeyPressFcn',   @KeyPress)
%'position',      [ 0   14   33    9.5442],...

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



% Valve time controls


function setCenterValveTime_Callback(~, ~, handles)

global gf
gf.rewardTime = str2num( get(handles.editCenterValveTime,'string'));



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

switch event.Character
    case '!'
        valve_WE(1,100,1)
    case '"'
        valve_WE(2,gf.rewardTime,1)
    case '*'
        valve_WE(8,gf.rewardTime,1)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Circuit Controls %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Buttons that allow the user interface to control parameters within the
% RPvdsEX circuit directly.

% Safety switch
% function enableControl_Callback(~, ~, handles)
%
% global DA gf
%
% %Update all control tickboxes
% set(handles.bit0C,'Value', DA.GetTargetVal(sprintf('%s.bit0C',gf.stimDevice)))
% set(handles.bit1C,'Value', DA.GetTargetVal(sprintf('%s.bit1C',gf.stimDevice)))
% set(handles.bit2C,'Value', DA.GetTargetVal(sprintf('%s.bit2C',gf.stimDevice)))
% set(handles.bit7C,'Value', DA.GetTargetVal(sprintf('%s.bit7C',gf.stimDevice)))
%
% %Bit 0 Control
% function bit0C_Callback(~, ~, handles)
%
% global DA gf
%
% if get(handles.enableControl,'value') == 1,
%
%     tag = sprintf('%s.bit0C',gf.stimDevice);
%     val = get(handles.bit0C,'value');
%
%     DA.SetTargetVal(tag, val);
% end
%
% %Bit 1 Control
% function bit1C_Callback(~, ~, handles)
%
% global DA gf
%
% if get(handles.enableControl,'value') == 1,
%
%     tag = sprintf('%s.bit1C',gf.stimDevice);
%     val = get(handles.bit1C,'value');
%
%     DA.SetTargetVal(tag, val);
% end
%
% %Bit 2 Control
% function bit2C_Callback(~, ~, handles)
%
% global DA gf
%
% if get(handles.enableControl,'value') == 1,
%
%     tag = sprintf('%s.bit2C',gf.stimDevice);
%     val = get(handles.bit2C,'value');
%
%     DA.SetTargetVal(tag, val);
% end
%
% %Bit 7 Control
% function bit7C_Callback(~, ~, handles)
%
% global DA gf
%
% if get(handles.enableControl,'value') == 1,
%
%     tag = sprintf('%s.bit7C',gf.stimDevice);
%     val = get(handles.bit7C,'value');
%
%     DA.SetTargetVal(tag, val);
% end

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
    
    % Report data to command window
    rIncorrect = get( findobj(h.performanceA,'XData',1), 'YData'); % Left  incorrect
    rCorrect = get( findobj(h.performanceA,'XData',2), 'YData'); % Left  incorrect
    aborted = get( findobj(h.performanceA,'XData',3), 'YData'); % Left  incorrect
    lCorrect = get( findobj(h.performanceA,'XData',4), 'YData'); % Left  incorrect
    lIncorrect = get( findobj(h.performanceA,'XData',5), 'YData'); % Left  incorrect
    
    nCorrect = rCorrect+lCorrect;
    totalTrials=rCorrect+lCorrect+rIncorrect+lIncorrect;
    
    fprintf('Trials: %d, Correct: %.0f percent (%d / %d)\n',...
        gf.TrialNumber - 1,...
        nCorrect/totalTrials * 100,...
        nCorrect,...
        totalTrials)
    
    % Close log file
    fclose(gf.fid);
    
    % Stop task timer
    stop(h.tasktimer);
    
    % Stop the noise loop
    if strfind(gf.paramFile,'level11')
        fclose(gf.nDBfid);
    end
    
    % Set device to idle
    % (This avoids sounds/lights being produced when you no longer have GUI control)
    DA.SetSysMode(0);
    
    % Close connections and windows
    DA.CloseConnection
    
    close(handles.figure1)
    close(h.timelineF)
    close(h.performanceF)
    
    % Restore default paths
    path(gf.defaultPaths)
    
    % Delete structures
    clear global DA gf h
    clear
    
    gf = [];
    
    disp('session ended')
    disp('All structures removed and default paths restored')
    clear all
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


function editCenterRewardP_CreateFcn(~, ~, ~)
