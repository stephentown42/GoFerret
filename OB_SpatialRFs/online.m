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

    %DAfig = figure('position',[0 0 100 100],'visible','on');

    DA = actxcontrol('TDevAcc.X');
    DA.ConnectServer('Local');
    
    % Choose whether to record or not
    choice = MFquestdlg([0.2, 0.5],...
                        'Do you want to record neural data to tank during task?',...
                        'Neural Recordings','Yes','No','Cancel','No');
    
    
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
            TT.OpenTank(gf.tankDir,'R');
            gf.recBlock = TT.GetHotBlock;
            TT.CloseTank;
            TT.ReleaseServer;
            clear TT
            
            if isempty(gf.recBlock),
                gf.recBlock = 'UnknownBlock';
            end
            
        case 'No'
            DA.SetSysMode(2);
            gf.recBlock = 'log';
            
        case 'Cancel'
            return
    end          

    pause(2)
    gf.fStim = DA.GetDeviceSF(gf.stimDevice);       
    gf.fRec  = DA.GetDeviceSF(gf.recDevice);

    % Set up tracking figure
    h.trackFig = figure('color',    'k',...
                        'units',    'centimeters',...
                        'position', [1 2 15 15*0.75],...
                        'MenuBar',  'none',...
                        'Toolbar',  'none',...
                        'NumberTitle','off',...
                        'Name',      'Position');
                    
    h.trackAxs = axes('xlim',   [0 640],...
                      'ylim',   [0 480],...
                      'box',    'on',...
                      'xcolor', 'w',...
                      'ycolor', 'w',...
                      'xtick',  [],...
                      'ytick',  [],...
                      'color',  'k');

      hold on
      h.LEDgreen  = plot(-1,-1,'og','MarkerFaceColor','g');
      h.LEDred    = plot(-1,-1,'or','MarkerFaceColor','r');
      h.pathGreen = plot([0 -1],[0 -1],'color',[0.5 1 0.5]);
      h.pathRed   = plot([0 -1],[0 -1],'color',[1 0.5 0.5]);

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

% Enable RV2
if ~DA.SetTargetVal( sprintf('%s.RV2_ON', gf.recDevice), 1)
    warning('Could not initiate frame capture on RV2')
end
    
    

if isvalid(h.tasktimer) == 1,
    start(h.tasktimer);
end


function varargout = online_OutputFcn(hObject, eventdata, handles)  
varargout{1} = handles.output;







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
    case '+'      
        
        valve_WE(1,gf.centerValveTime,1)
        %valve(6, gf.centerValveTime, 1, 'center'); %valve(bit, pulse time, pulse number, %sValve)
        
    case '{'
        
        valve_WE(3,gf.leftValveTime,1)
        %valve(4, gf.leftValveTime, 1, 'left'); 
        
    case '}'
        valve_WE(5,gf.rightValveTime,1)
        %valve(5, gf.rightValveTime, 1, 'right'); 
end


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
    
    
    % Disable RV2
    DA.SetTargetVal( sprintf('%s.RV2_ON', gf.recDevice), 0);
    pause(2)

    % Stop task timer
    stop(h.tasktimer);
    
    % Set device to idle 
    % (This avoids sounds/lights being produced when you no longer have GUI control)
    DA.SetSysMode(0);

    % Close connections and windows
    DA.CloseConnection
    close(handles.figure1)
    close(h.trackFig)

    % Restore default paths
    path(gf.defaultPaths)

    % Delete structures
    clear global DA gf h
    clear

    gf = [];

    disp('session ended')
    disp('All structures removed and default paths restored')
end
