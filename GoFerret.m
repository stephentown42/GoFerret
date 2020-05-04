function varargout = GoFerret(varargin)
% GOFERRET MATLAB code for GoFerret.fig
%      GOFERRET, by itself, creates a new GOFERRET or raises the existing
%      singleton*.
%
%      H = GOFERRET returns the handle to a new GOFERRET or the handle to
%      the existing singleton*.
%
%      GOFERRET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GOFERRET.M with the given input arguments.
%
%      GOFERRET('Property','Value',...) creates a new GOFERRET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GoFerret_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GoFerret_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GoFerret

% Last Modified by GUIDE v2.5 04-May-2020 14:17:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GoFerret_OpeningFcn, ...
                   'gui_OutputFcn',  @GoFerret_OutputFcn, ...
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


% --- Executes just before GoFerret is made visible.
function GoFerret_OpeningFcn(hObject, ~, handles, varargin)

handles.output = hObject;
guidata(hObject, handles);

if isempty(whos('global','gf')) == 0
    clear gf
end

global gf DA TT

% Read configuration file
gf = jsondecode( fileread( 'config.json'));
gf.defaultPaths = path;

% Set order from config file
ferrets = fieldnames(gf.order);

for i = 1 : numel( ferrets)
   
    field_name = ['order_' ferrets{i}(7:end)]; % Skip F number 
    
    eval( sprintf('handle_val = handles.%s;', field_name))
    eval( sprintf('handle_str = gf.order.%s;', ferrets{i}))
    
    set( handle_val, 'string', handle_str)
end

% Establish connection to TDT
DA = actxcontrol('TDevAcc.X');
gf = establish_TDev_connection(handles, DA, gf);

TT = actxcontrol('TTank.X');
establish_TTank_connection(handles, TT)


% Enable start if past 12:00
t = clock;
if t(4) > 12
    set(handles.startH,'enable','on') 
    set(handles.weight,'userdata',nan)
else
    set(handles.startH,'enable','on') 
    set(handles.weight,'userdata',0)
end    

set(handles.weightDir,'string', gf.weight_dir)

% Load folder options
load_userList(handles, gf.home_dir)
load_subjectList(handles, gf.save_dir)



function gf = establish_TDev_connection(h, DA, gf)

% Establish connection to server
if ~DA.ConnectServer('Local')    
    h.connection_status.String = 'Connection failed';
    h.connection_status.ForegroundColor = [0.8 0 0];
    error('TDT Connection Failed')
else
    h.connection_status.String = 'Connection successful';
    h.connection_status.ForegroundColor = [0 0.8 0];
end

% Confirm access to devices
gf.fStim = DA.GetDeviceSF( gf.stimDevice);       
gf.fRec = DA.GetDeviceSF( gf.recDevice);

h.stim_device.String = sprintf('%s (%.0f Hz)', gf.stimDevice, gf.fStim);
h.rec_device.String = sprintf('%s (%.0f Hz)', gf.recDevice, gf.fRec);





function establish_TTank_connection(handles, TT)

if ~TT.ConnectServer('Local','Me')       
    handles.tank_status.String = 'Could not connect to Tankconnected';
    error('Failed to open TTank connection')
else        
    handles.tank_status.String = 'Tank connected';
end



% --- Executes on button press in close.
function close_Callback(hObject, eventdata, handles)
% hObject    handle to close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Close connections and windows
global DA TT gf

DA.CloseConnection;
TT.ReleaseServer;        

% Restore default paths
path(gf.defaultPaths);

% Close GoFerret
close(handles.figure1)

clear global DA TT



%%%%%%%%%%%%%%% 1/5 User selects directory for stage files %%%%%%%%%%%%%%%%

% Load available directories
function load_userList(handles, file_path)

    % Writes files from directory to listbox   
    S = dir(file_path);
    S = S( cat(1, S.isdir) == 1);
    
    handles.is_dir = [S.isdir];
    [handles.file_names , handles.sorted_index] = sortrows({S.name}');
        
    guidata(handles.figure1,handles)
    set(handles.userList,'String',handles.file_names,'Value',1)
    set(handles.userEdit,'String',file_path)
    
    
% Select task folder (e.g. ST_TimbreDiscrim)   
function userList_Callback(~,~,handles)                     %#ok<*DEFNU>
    
    global gf
            
    S = dir(gf.home_dir);
    S = S( cat(1, S.isdir) == 1);
    
    handles.is_dir = [S.isdir];
    [~, handles.sorted_index] = sortrows({S.name}');    
       
    % Open selected file and load filenames (m files only)
    index_selected  = get(handles.userList,'Value');
    file_list       = get(handles.userList,'String');
    filename        = file_list{index_selected};
    filename        = fullfile(gf.home_dir, filename);
    
    if  handles.is_dir(handles.sorted_index(index_selected))
                
        addpath(filename)
        
        gf.directory = filename;
        load_stageList(gf.directory, handles)
    end


% Load available stage files
function load_stageList(file_path, handles)

    % Writes matlab files from stage directory (dir_path) to center listbox
    file_path = fullfile(file_path,'stages'); % Goes directly into stage file: could cause problems if GoFerret structure is not adhered to    
    S = dir( fullfile( file_path, '*.m')); 
    
    [handles.file_names, handles.sorted_index ] = sortrows({S.name}');
    handles.is_dir = [S.isdir];
    
    guidata(handles.figure1,handles)
    
    % Select first
    set(handles.stageList,'String',handles.file_names,'Value',1)
    
    % Set edit box as selected file
    index_selected  = get(handles.stageList,'Value');
    file_list = get(handles.stageList,'String');
    
    set(handles.stageEdit,'String',file_list{index_selected})
    
    % Enables default to first file without further user input
    global gf
    [~, gf.filename, ~] = fileparts( file_list{index_selected});    
    
    % Load Parameters list for default file
    load_parameterList(gf.directory, handles)

        
    
%%%%%%%%%%%%%%%%%%%%%%%% 2/5 Select stage file %%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stageList_Callback(~, ~, handles)
  
    global gf

    index_selected  = get(handles.stageList,'Value');
    file_list       = get(handles.stageList,'String');
    gf.filename     = file_list{index_selected};
    
    %remove '.m' extension
    gf.filename     = gf.filename(1:length(gf.filename)-2);
    
    load_parameterList(gf.directory,handles)
   
    
function load_parameterList(file_path, handles)

    global gf    
            
    file_path = fullfile(file_path,'parameters');         
    S = dir( fullfile( file_path, [gf.filename(1:7) '*']));
    
    [handles.file_names, handles.sorted_index] = sortrows({S.name}');
    handles.is_dir = [S.isdir];
    
    guidata(handles.figure1,handles)
    set(handles.parameterList,'String',handles.file_names,'Value',1)
    set(handles.parameterEdit,'String',pwd)
    
    % Select first file
    set(handles.parameterList,'String',handles.file_names,'Value',1)
    
    % Set edit box as selected file
    index_selected  = get(handles.parameterList,'Value');
    file_list       = get(handles.parameterList,'String');
    
    set(handles.parameterEdit,'String',file_list{index_selected})
    
    % Enables default to first file without further user input
    gf.paramFile = file_list{index_selected};
    

    

    
%%%%%%%%%%%%%%%%%%%%%%%% 3/5 Select parameter file %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function parameterList_Callback(~, ~, handles)

    global gf

    index_selected  = get(handles.parameterList,'Value');
    file_list       = get(handles.parameterList,'String');
    gf.paramFile    = file_list{index_selected};
    
        


%%%%%%%%%%%%%%%%%%%%%%%%%%% 4/5 Select subject %%%%%%%%%%%%%%%%%%%%%%%%%%

function load_subjectList(handles, file_path)   
    
    dir_struct = dir( fullfile(file_path, 'F*'));
    handles.is_dir = [dir_struct.isdir];
    [handles.file_names, handles.sorted_index ] = sortrows({dir_struct.name}');                             
    
    guidata(handles.figure1,handles)
    
    set(handles.subjectList,'String',handles.file_names,'Value',1)
    
    % Set temporary as default
    set(handles.editSaveDir,'String', file_path)
    set(handles.subjectEdit,'String','Temporary')  
    

function subjectList_Callback(~, ~, handles)    
    
    index_selected  = get(handles.subjectList,'Value');
    file_list = get(handles.subjectList,'String');
    ferret = file_list{index_selected};
    
    global gf    
    set(handles.editSaveDir,'String', fullfile(gf.save_dir, ferret))
    
    
    
function subjectEdit_Callback(~, ~, handles)
    
save_dir = fullfile( get(handles.editSaveDir,'string'),...
                     get(handles.subjectEdit,'string'));

set(handles.editSaveDir,'String',save_dir)



%%%%%%%%%%%%%%%%% 5/5 Close interface and enter online GUI %%%%%%%%%%%%%%%%
function startH_Callback(~, ~, handles)

global gf

% Confirm file paths
config = jsondecode( fileread( 'config.json'));
gf.tank_parent = config.tank_parent;
gf.weight_dir = config.weight_dir;

gf.calibDir = get(handles.calibrationFolder,'string');  
gf.saveDir = get(handles.editSaveDir,'string');  
[~, gf.subjectDir] = fileparts(gf.saveDir);
gf.tank = fullfile(gf.tank_parent, gf.subjectDir);  % Note that for non-recording animals, this file doesn't need to exist

% Add directory and subfolders to path definition
if isfolder( gf.directory)
    addpath( genpath( gf.directory ))
else
    fprintf('Failed to add paths...\n%s\n', gf.directory)
    return
end

% Save weight to file
weightData = get(handles.weight,'userdata');
% set(handles.weight,'string','0')

if ~isnan(weightData)   % If afternoon flag not set

    if numel(weightData) == 1, weightData = [0 0]; end
    
    % Get weight directory
    weightDir  = get(handles.weightDir,'string');
    weightData = array2table(weightData,'variableNames',{'DateNum','Weight'});
    
    % Get ferret from gui
    ferret = handles.subjectList.String;
    ferret = ferret{handles.subjectList.Value};
    
    % Check file for this animal exists
    weightFile = fullfile(weightDir, [ferret '.csv']);

    if ~exist(weightFile,'file')
        error('Could not find weight file')
    end
    
    % Report husbandy limits for animal if Monday
    if strcmp('Mon',datestr(now,'ddd'))
        figure('name',sprintf('%s: %dg %.0fg %.1fml', ferret, weightData.Weight, weightData.Weight*0.88, weightData.Weight*.06))
    end

    % Add data to table
    T = readtable(weightFile, 'delimiter', ',');
    T = [T; weightData];
    writetable(T, weightFile, 'delimiter', ',')
end

parameters

       

function flush_Callback(~, ~, ~)

global DA

% Options
valve_no = [3 9];
valve_time = 2;

status = DA.SetSysMode(2); % Set to preview
fprintf('Flushing (%d)\n', status)
pause(3)

% For each response valve
for i = 1 : numel(valve_no)
    
    valveJumbo_J5(valve_no(i), valve_time, 'platform'); 
    pause(valve_time)
    
    valveJumbo_J5(valve_no(i), valve_time, 'ring'); 
    pause(valve_time)
end

% Flush center spout
valveJumbo_J5(6, valve_time, 'periphery'); 
pause(valve_time)

% Close connection
DA.SetSysMode(0);




% --- Outputs from this function are returned to the command line.
function varargout = GoFerret_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



%%%%%%%%%%%%%%%%%%%%%%%%% Browse functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function browseSaveDir_Callback(~, ~, ~)

    path = uigetdir;


function userBrowse_Callback(~, ~, ~)

    path = uigetdir;

function stageBrowse_Callback(~, ~, ~)

    path = uigetdir;

function parameterBrowse_Callback(~, ~, ~)

    path = uigetdir;




function plotWeight_Callback(hObject, eventdata, handles)

[T, subject] = getWeightFile(handles); % Load data 
today = ceil(now);

% Remove spuriously small values (for when weight measurement is skipped)
T(T.Weight < 100,:) = [];

% Sort by weight
T = sortrows(T);

% close competing figures
f = findobj(0,'type','figure','tag','WeightPlot');
if ~isempty(f), close(f); end

figure('name',          subject,...
       'numbertitle',   'off',...
       'tag',           'WeightPlot',...
       'userdata',      T)  % Plot data
hold on
   
% Plot all weights
plot(T.DateNum,T.Weight,'k')

% Mark specific days
days = datestr(T.DateNum,'DDD');    
days = double(days);

monIdx = ismember(days, double('Mon'),'rows'); % Mark start of week
friIdx = ismember(days, double('Fri'),'rows'); % Mark end of week
satIdx = ismember(days, double('Sat'),'rows'); % Mark weekends
sunIdx = ismember(days, double('Sun'),'rows');
wkeIdx = any([satIdx sunIdx],2);

plot(T.DateNum(monIdx),T.Weight(monIdx),'or','MarkerFaceColor',[1 0.5 0.5])
plot(T.DateNum(friIdx),T.Weight(friIdx),'ob','MarkerFaceColor',[0.5 0.5 1])
plot(T.DateNum(wkeIdx),T.Weight(wkeIdx),'o','MarkerEdgeColor',[0 0.5 0],'MarkerFaceColor',[0.5 1 0.5])

% Set axes
xlabel('Date')
ylabel('Weight (g)')
dateaxis('x',6)
box off
   


function removeWeight_Callback(hObject, eventdata, handles)
    
% Look for open figure
f = findobj(0,'type','figure','tag','WeightPlot');

if isempty(f)
    plotWeight_Callback(hObject, eventdata, handles)
    f = findobj(0,'type','figure','tag','WeightPlot');
end

% Enable data curose
obj = datacursormode(f);
set(obj,'displayStyle','datatip','snapToDataVertex','off','enable','on')
title('Select data point to remove and then press return')
pause

% Filter based on selection
c_info = getCursorInfo(obj);
T = get(f,'userData');
T(c_info.DataIndex,:) = [];

% Save updated data
saveWeightFile(handles, T)

% Replot data to confirm
close(f)
plotWeight_Callback(hObject, eventdata, handles)



function addWeight_Callback(hObject, eventdata, handles)

[T, subject] = getWeightFile(handles); % Load data 

% Request data from user
prompt = {sprintf('Enter weight for %s:', subject), 'Date'};
name = 'Weight (g)';
numlines = 1;
defaultanswer = {'',datestr(now,'dd-mm-yy')};
w = inputdlg(prompt,name,numlines,defaultanswer);

% Parse answers
t = datenum(w(2),'dd-mm-yy');
w = str2double(w(1));

S = array2table([t, w],'variableNames',{'DateNum','Weight'});
T = [T; S];

saveWeightFile(handles, T)
    

function [T, subject] = getWeightFile(h)

% Get subject
strs = get(h.subjectList,'string');
val  = get(h.subjectList,'value');
subject = strs{val};

% Load weight file
pathname = get(h.weightDir,'string');
T = readtable( fullfile( pathname, [subject '.csv']), 'delimiter',',');


function saveWeightFile(h, T)

% Get subject
strs = get(h.subjectList,'string');
val  = get(h.subjectList,'value');
subject = strs{val};

% Load weight file
pathname = get(h.weightDir,'string');
save( fullfile( pathname, [subject '.mat']),'T');


function weight_Callback(hObject, eventdata, handles)
  
set(handles.startH,'enable','on') 
set(hObject,'userdata',[now str2double(get(hObject,'String'))])


function userEdit_Callback(~, ~, ~)
function userEdit_CreateFcn(~, ~, ~)
function stageEdit_Callback(~, ~, ~)
function stageEdit_CreateFcn(~, ~, ~)
function userList_CreateFcn(~, ~, ~)
function stageList_CreateFcn(~, ~, ~)
function parameterList_CreateFcn(~, ~, ~)
function editSaveDir_Callback(~, ~, ~)
function editSaveDir_CreateFcn(~, ~, ~)
function parameterEdit_Callback(~, ~, ~)
function parameterEdit_CreateFcn(~, ~, ~)
function subjectEdit_CreateFcn(~,~,~)  
function subjectList_CreateFcn(~,~,~)
function calibrationFolder_Callback(~,~,~)
function calibrationFolder_CreateFcn(~,~,~)
function weightDir_Callback(hObject, eventdata, handles)
function weightDir_CreateFcn(hObject, eventdata, handles)
function weight_CreateFcn(hObject, eventdata, handles)


% Rapid list box fill
function Quick1701_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)    
function Quick1703_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1801_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1807_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1808_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1810_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1811_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)    
function Quick1902_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)    
function Quick1901_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)    
function Quick1904_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
function Quick1905_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)    
function Quick0_Callback(hObject, eventdata, handles)
    populateListBoxes(hObject, handles)
    
function populateListBoxes(hObject, handles)
    
    % Get subject
   ferret = get(hObject,'String');
   myTask = 'ST_Localization';
   
   % Set subject list box   
   setListBox(handles.subjectList, ferret);
   subjectList_Callback(0,0,handles)
   
   % Set task (this can be expanded later if other people want to use Jumbo)
%    set(handles.userList,'value',6)
%    userList_Callback(0,0,handles)
   
   % Hard code level and parameters file
   switch ferret
       case 'F1701_Pendleton'
           myLevel = 'level53_test.m';
           myParam = 'level53_Pendleton.txt';
           
       case 'F1703_Grainger'
           myLevel = 'level53_test.m';
           myParam = 'level53_Grainger.txt';
           
       case 'F1808_Skittles'
           myTask = 'ST_SRF';
           myLevel = 'level03_SRF.m';
           myParam = 'level03_SRF.txt';
           
       case 'F1810_Ursula'
           myLevel = 'level55_test.m';
           myParam = 'level55_Ursula.txt';
           
       case 'F1811_Dory'
           myLevel = 'level53_test.m';
           myParam = 'level53_Dory.txt';
           
       case 'F1901_Crumble'
           myLevel = 'level55_test.m';
           myParam = 'level55_Crumble.txt';
           
       case 'F1902_Eclair'
           myLevel = 'level53_test.m';
           myParam = 'level53_Eclair.txt';
           
       case 'F1904_Flan'
           myLevel = 'level53_test.m';
           myParam = 'level53_Flan.txt';
           
       case 'F1905_Sponge'
           myLevel = 'level55_test.m';
           myParam = 'level55_Sponge.txt';
           
       case 'F0_Developer'
           myLevel = 'level53_test_Calibration.m';
           myParam = 'level53_Calibration';
   end
   
   % Set level
   setListBox(handles.userList, myTask);
   userList_Callback(0,0,handles)
   
   % Set level
   setListBox(handles.stageList, myLevel);
   stageList_Callback(0,0,handles)
    
   % Set parameters
   setListBox(handles.parameterList, myParam);
   parameterList_Callback(0,0,handles)
   
       
function setListBox(h,target)
    
    all_strings = get(h,'string');
    targetVal   = find(strcmp(all_strings, target));
    if ~isempty(targetVal)
        set(h,'value', targetVal)
    end
        
   
% Manual check of TDT connection 
function check_connection_Callback(~, ~, ~)

global DA

fprintf('Running connection test...\n')

if DA.SetSysMode(0)
    fprintf('\tSuccessful state switch to idle...\n')
else
    fprintf('\tFailed switch to idle\n')
    return
end

if DA.SetSysMode(1)
    fprintf('\tSuccessful state switch to standby, please wait...\n')
    pause(3)
end

if DA.SetSysMode(0)
    fprintf('\tSuccessful state switch to idle - all checks passed :)\n')
end


% --- Executes on button press in redial_tdt.
function redial_tdt_Callback(~, ~, ~)
%
% Here I'm using the ability to acquire a positive value for the sample
% rate as an indicator of success. If this doesn't happen then usually
% there's a failed connection (and it's faster than changing the status of
% the device)

global DA gf

if DA.GetDeviceSF( gf.stimDevice) == 0
    fprintf('TDT connection stalled - performing redial\n')
else
    fprintf('TDT connection looks ok - skipping request\n')
    return
end

nDials = 10;
connection_sucks = true;
dial_idx = 1;

while connection_sucks && dial_idx <= nDials
   
    fprintf('\tAttempt %d/%d:', dial_idx, nDials)
    
    DA = actxcontrol('TDevAcc.X'); 
    DA.ConnectServer('Local')    
    pause(1)
    connection_sucks = DA.GetDeviceSF( gf.stimDevice) > 0;
    
    if connection_sucks        
        fprintf('Failed\n')
        dial_idx = dial_idx + 1;
    else
        fprintf('Successful!\n')
        return
    end
end


    
