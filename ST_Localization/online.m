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

% Last Modified by GUIDE v2.5 03-Mar-2020 09:26:26

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


% Subject-specific actions
if any( strcmp( gf.subjectDir, gf.recFerrets))
               
    isOk = start_recording(DA, gf.tank);
    
    % Stop early if something is wrong
    if ~isOk
        close(handles.figure1)
        return
    end

    % Get block name
    gf.recBlock = get_current_block(gf.tank);
    
    if isempty(gf.recBlock)
        DA.SetSysMode(0);       % Set device to idle
    end        
else    
    
    gf.recBlock = 'log';
    start_preview(DA)
end

% Pass objects 
handles.output = hObject;
guidata(hObject, handles);
h = handles;

% Reset all parameter tags (can probably be removed at some point)
tags = {'bit0C','bit1C','bit2C','bit4C','bit5C','bit6C','bit7C',...
        'leftLick','centerLick','rightLick',...
        'leftValve','centerValve','rightValve'};

for i = 1 : length(tags)

    tag = sprintf('%s.%s',gf.stimDevice, tags{i});
    DA.SetTargetVal(tag,0);   
end

% Set date
set(handles.dateH,'string',...
    sprintf('%s\n%s\n', datestr(now,'dd-mm-yyyy'),datestr(now, 'HH_MM_SS')))

% Make a new tab delimited file 
[~, paramFile, ~] = fileparts( gf.paramFile);                  % Remove extension from file name    

filename = [datestr(now,'dd_mm_yyyy XXX HH_MM_SS.FFF') ' ' gf.recBlock '.txt'];
filename = strrep( filename, 'XXX', paramFile);
filename = fullfile( gf.save_dir, gf.subjectDir, filename);

gf.fid = fopen( filename, 'wt');
logTrial(0,'header');      
set(h.saveTo, 'string', ['Save to: ' filename]);

%Set devices
gf.fStim = DA.GetDeviceSF( gf.stimDevice); 
gf.fRec = DA.GetDeviceSF( gf.recDevice);   

set(handles.devices,'string',sprintf(' %s \n %.3f',gf.stimDevice, gf.fStim))
set(handles.slideCenterRewardP, 'value', gf.centerRewardP)
set(handles.editCenterRewardP, 'string', num2str(gf.centerRewardP))

% Define color scheme
colors = struct('background', [39 40 34] ./ 255,...
                'axis',[117 113 94] ./ 255,...
                'performance', [0 1 0],...
                'performance_cmap', magma,...
                'bias', [248 39 114] ./ 255);

% Position Online GUI
set(h.figure1,'KeyPressFcn',@KeyPress,...
    'color', colors.background)

text_obj = findobj(h.figure1,'style','text');
set(text_obj, 'ForegroundColor', colors.axis,...
              'BackgroundColor', colors.background)

% Performance 
gf.levelNum = str2num(gf.filename(6:7));

if gf.levelNum < 53
    createPerformanceFig
else
    createPerformanceFig_CoordFrameProj(colors)
end

% Timeline               
% Create figure
  
h.timelineF = figure('NumberTitle',    'off',...
                      'name',           'Timeline',...
                      'color',          colors.background,...
                      'units',          'centimeters',...
                      'position',       [34.1 1.72 10 5],...
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
                    'color',      colors.background,...
                    'xcolor',     colors.axis,...
                    'ycolor',     colors.axis,...
                    'ylim',       [0 13],...
                    'ytick',      1:12,...
                    'yticklabel', yticklabels);

xlabel(h.timelineA, 'Time (seconds)')    

% Update online position
set(h.figure1,'KeyPressFcn',   @KeyPress,...
       'position',[3.8 3.6 170 32])

% Setup timer
h.tasktimer = timer('TimerFcn',         sprintf('%s',gf.filename),...
                    'BusyMode',         'drop',...
                    'ExecutionMode',    'fixedRate',...
                    'Period',           gf.period);                    


gf.beep_given = false;
gf.biasTracker    = struct('data',[],'idx',0,'window',8,'current',0,'rate',0.1,'saturation',0.2);
gf.centerPixelVal = 256; % Default value when tracking is not on
gf.centerStatus   = 0;
gf.centerReward   = 0;
gf.correctionTrial = 0;
gf.pastResponse   = 0;
gf.responseTime   = 0;
gf.startTrialTime = 0;
gf.transMat = zeros(4,4,3);
gf.timeout_start  = 0;
gf.stim.idx       = 0;
gf.startTime      = now;    
gf.status         = 'PrepareStim';                  
gf.track          = isfield(gf,'trackThreshold');

if gf.box_mode == 2
    gf.box_mode = 'platform'; 
else
    gf.box_mode = 'ring';
end    

DA.SetTargetVal( sprintf('%s.centerEnable',gf.stimDevice), 1);

% Perform one-off calculations for clicks for neural testing (14 March 2019)
if isfield(gf,'clicks')        
    gf.clicks = initialize_clicks( gf.clicks, gf.fStim);                
end

% Set tracking threshold
if gf.track
    DA.SetTargetVal( sprintf('%s.track_thresh',gf.stimDevice), gf.trackThreshold);
end

% Run video function in background (requires '&' operator)
pause(2)

if any( strcmp( gf.subjectDir, gf.trackFerrets))
    gf.video_path = gf.high_res_video;
else
    gf.video_path = gf.split_screen_video;
end

eval( sprintf('!python %s & exit &',  gf.video_path))
    
if isvalid(h.tasktimer) == 1
    start(h.tasktimer);
end


function varargout = online_OutputFcn(~, ~, ~)  %#ok<STOUT>
%varargout{1} = handles.output;

global h

set(h.figure1,'KeyPressFcn',   @KeyPress)  % This is the 3rd time you've repeated this line!!!


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

global gf DA

if strcmp(event.Key,'equal')
    valveJumbo_J5(6,gf.valveTimes(6), gf.box_mode)
end

% Valves based on F numbers
for i = 1 : 12    
   if strcmp(event.Key,sprintf('f%d',i))
       valveJumbo_J5(i, gf.valveTimes(i), gf.box_mode)
   end
end

if strcmp(event.Key,'+')        
    DA.SetTargetVal( sprintf('%s.ManualPlay', gf.stimDevice),    1);
    DA.SetTargetVal( sprintf('%s.ManualPlay', gf.stimDevice),    0);
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

% send end pulse to TDT for synchronisation with wireless
DA.SetTargetVal('RX8.endPulse', 1);
DA.SetTargetVal('RZ2.endPulse', 1);
pause(0.5)
DA.SetTargetVal('RX8.endPulse', 0);
DA.SetTargetVal('RZ2.endPulse', 0);


% Display performance
fprintf('%d trials\n', gf.TrialNumber-1)

for i = 1 : nUnique(h.im)
  
    cMat     = get(h.im(i),'CData');
    nTrials  = sum(cMat(:));
    nCorrect = sum(cMat(eye(12)==1)); 
    pCorrect = nCorrect / nTrials * 100;    
    
    fprintf('\t%.1f %% (%d\\%d)', pCorrect, nCorrect, nTrials)
    fprintf('\n')
end

% Close log file and reset gf structure
fclose(gf.fid);
gf = reset_gf(gf);

% Stop task timer
stop(h.tasktimer);

% Set device to idle
% (This avoids sounds/lights being produced when you no longer have GUI control)
DA.SetSysMode(0);

% Delete graphics 
close(handles.figure1)
close(h.timelineF)
close(h.performanceF)
clear global h

% Delete structures
disp('session ended')
disp('All structures removed and default paths restored')





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


% --- Executes on button press in stim_limit.
function stim_limit_Callback(hObject, eventdata, handles)
function limit_menu_Callback(hObject, eventdata, handles)
function limit_menu_CreateFcn(hObject, eventdata, handles)


% --- Executes on slider movement.
function slider3_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'value',gf.valveTimes(3))

function slider6_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'value',gf.valveTimes(6))

function slider9_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'value',gf.valveTimes(9))

function valveTime3_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'string',num2str(gf.valveTimes(3)))

function valveTime6_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'string',num2str(gf.valveTimes(6)))

function valveTime9_CreateFcn(hObject, eventdata, handles)
global gf
set(hObject,'string',num2str(gf.valveTimes(9)))

function slider3_Callback(hObject, eventdata, handles)
update_valve_time(3, get(hObject,'value'))
set( handles.valveTime3,'string', num2str( get(hObject,'value')))

function slider6_Callback(hObject, eventdata, handles)
update_valve_time(6, get(hObject,'value'))
set( handles.valveTime6,'string', num2str( get(hObject,'value')))

function slider9_Callback(hObject, eventdata, handles)
update_valve_time(9, get(hObject,'value'))
set( handles.valveTime9,'string', num2str( get(hObject,'value')))

function valveTime3_Callback(hObject, eventdata, handles)
update_valve_time(3, str2double(get(hObject,'string')))

function valveTime6_Callback(hObject, eventdata, handles)
update_valve_time(6, str2double(get(hObject,'string')))

function valveTime9_Callback(hObject, eventdata, handles)
update_valve_time(9, str2double(get(hObject,'string')))

function update_valve_time(idx, value)

global gf
gf.valveTimes(idx) = value;


% --- Executes on button press in s6_override.
function s6_override_Callback(hObject, eventdata, handles)

global DA gf

 DA.SetTargetVal( sprintf('%s.s6_override', gf.stimDevice),  hObject.Value);  

