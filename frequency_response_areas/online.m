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

% Last Modified by GUIDE v2.5 19-Jul-2019 11:51:19

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

% Establish connection with TDT 
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');

sl=strfind(gf.saveDir,'\');
gf.subjectDir=gf.saveDir(sl(end)+1:end);

recFerrets = {'F1808_Skittles','F1807_Cheeseburger',...
              'F1703_Grainger','F1701_Pendleton','F1904_Flan','F1905_Sponge',...
              'F1810_Ursula','F1811_Dory','F1901_Crumble','F1902_Eclair','F0_Developer'};

if any( strcmp( gf.subjectDir, recFerrets))
    choice = 'Yes';%('Do you want to record neural data to tank during task?','s');
else
    choice = 'No';
end


switch choice
    
    case 'Yes'
        
        gf.tankDir='D:\UCL_Behaving';
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
        tankOpen=TT.OpenTank(gf.tankDir,'R');
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
     
    gf.systemStatus = DA.SetSysMode(2);         
    errorCount      = 0;
    
    while ~gf.systemStatus && errorCount < 10
    
       errorCount = errorCount + 1;
       clear global DA 
       fprintf('Redialing TDT\n')
       DA = actxcontrol('TDevAcc.X');
       DA.ConnectServer('Local');
       gf.systemStatus = DA.SetSysMode(2);
       pause(3)      
    end
    
    if ~gf.systemStatus
        error('Could not start TDT')
    end
    
    gf.recBlock = 'log';
    pause(3)
end

% Get sample rates 
gf.fStim = DA.GetDeviceSF(gf.stimDevice);       
gf.fRec  = DA.GetDeviceSF(gf.recDevice);

% Make a new tab delimited file 
filename  = sprintf('%s_%s_%s_%s.txt',...
                        datestr(now,'YYYY-mm-dd'),...
                        gf.paramFile(1:end-4),...
                        datestr(now, 'HH-MM-SS'),...
                        gf.recBlock); 

gf.fid = fopen( fullfile( gf.saveDir, filename), 'wt');
logTrial_FRA('header');      

% Show key parameters in gui
set(handles.dateH,'string',datestr(now))
set(handles.devices,'string',sprintf(' %s \n %.3f',gf.stimDevice, gf.fStim))
set(h.saveTo, 'string', strcat('Save to: ',gf.saveDir,'\', filename));

% Timeline               
% Create figure
h.timelineF = figure('NumberTitle',    'off',...
                      'name',           'Timeline',...
                      'color',          'w',...
                      'units',          'centimeters',...
                      'position',       [34.1 1.72 14.8 24.2],...
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

xlabel(h.timelineA, 'Time (seconds)')    

% Update online position
set(h.figure1,'position',[3.8 3.6 170 32])

% Setup timer
h.tasktimer = timer('TimerFcn',         sprintf('%s',gf.filename),...
                    'BusyMode',         'drop',...
                    'ExecutionMode',    'fixedRate',...
                    'Period',           gf.period);                    

gf.startTime = now;    
gf.status = 'PrepareStim';                  
gf.stim = initialize_FRA(gf.freq, gf.dB_SPL, 'directed');
gf.stim_index = 1;
    
if isvalid(h.tasktimer) == 1,
    start(h.tasktimer);
end


function varargout = online_OutputFcn(~, ~, ~)  %#ok<STOUT>
%varargout{1} = handles.output;

global h

set(h.figure1,'KeyPressFcn',   @KeyPress)  % This is the 3rd time you've repeated this line!!!






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

% Close log file
fclose(gf.fid);

% Stop task timer
stop(h.tasktimer);

% Set device to idle
% (This avoids sounds/lights being produced when you no longer have GUI control)
DA.SetSysMode(0);

% Close connections and windows
DA.CloseConnection;

close(handles.figure1)
close(h.timelineF)

% Restore default paths
path(gf.defaultPaths);

% Delete structures
clear global DA gf h
clear

gf = [];

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
