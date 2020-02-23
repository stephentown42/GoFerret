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

% Last Modified by GUIDE v2.5 07-Dec-2013 18:58:48

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
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
    
gf.tankDir='D:\UCL_Behaving';
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
TT.OpenTank(gf.tankDir,'R');
gf.recBlock = TT.GetHotBlock;
TT.CloseTank;
TT.ReleaseServer;
clear TT

if isempty(gf.recBlock),
    gf.recBlock = 'UnknownBlock';
end

pause(2)
gf.fStim = DA.GetDeviceSF(gf.stimDevice);       
gf.fRec  = DA.GetDeviceSF(gf.recDevice);

% Run video function in background (requires '&' operator)
trackFerrets = {'F1701_Pendleton','F1703_Grainger','F1808_Skittles'};
if any( strcmp( gf.subjectDir, trackFerrets))
    !python C:\Users\Dumbo\Documents\MATLAB\Applications\GoFerret\ST_SRF\toolbox\ST_SRF_vid_HighRes.py & exit &
else
    !python C:\Users\Dumbo\Documents\MATLAB\Applications\GoFerret\ST_SRF\toolbox\ST_SRF_vid_LowRes.py & exit &
end

%Set date
t = fix(clock); 
temp{1}  = sprintf('%d-%d-%d',t(3),t(2),t(1)); 
temp{2}  = sprintf('%d:%d:%d',t(4),t(5),t(6));
set(handles.dateH,'string',sprintf('%s\n%s\n',temp{1},temp{2}))
    
    
% Make a new tab delimited file 
    cd(gf.saveDir)
    
    paramFile   = gf.paramFile(1:length(gf.paramFile)-4);                  % Remove extension from file name
    gf.saveName = sprintf('%d_%d_%d %s %d_%d log.mat', t(3), t(2), t(1), paramFile, t(4), t(5));      % Time Filename log.txt   
    gf.saveName = fullfile( gf.saveDir, gf.saveName);
    
    set(h.saveTo, 'string', strcat('Save to: ',gf.saveName))
    
    %Set devices
    set(handles.devices,'string',sprintf(' %s \n %.3f',gf.stimDevice, gf.fStim)) 

    
% Position Online GUI
    set(h.figure1, 'KeyPressFcn',   @KeyPress)

% Setup timer
    h.tasktimer = timer( 'TimerFcn',         sprintf('%s',gf.filename),...
                         'BusyMode',         'drop',...
                         'ExecutionMode',    'fixedRate',...
                         'Period',           gf.period);                    

% Initialize states                     
    gf.startTime       = now;    
    gf.status          = 'PrepareStim';                  

    

if isvalid(h.tasktimer) == 1,
    start(h.tasktimer);
end


function varargout = online_OutputFcn(hObject, eventdata, handles)  
varargout{1} = handles.output;


function KeyPress(src,event)
%
%   Monitors key pressed when online GUI is current figure
%
%	Key:        name of the key that was pressed, in lower case
%	Character:  character interpretation of the key(s) that was pressed
%	Modifier:   name(s) of the modifier key(s) (i.e., control, shift) pressed
%
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


function Exit_Callback(~, ~, handles)                                 %#ok<*DEFNU>

global DA gf h      

    % Stop task timer
    pause(2)
    stop(h.tasktimer);
    
    % Set device to idle 
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

    gf = [];

    disp('session ended')
    disp('All structures removed and default paths restored')
