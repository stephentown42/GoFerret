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

% Last Modified by GUIDE v2.5 30-Jan-2020 13:45:20

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

if isempty(whos('global','gf')) == 0,
 clear gf
end

global gf

gf.defaultPaths = path;

% User computer name to determine devices used

if strcmp(getenv('computername'),'DUMBO-PC') || strcmp(getenv('computername'),'RVC-HP1') || strcmp(getenv('computername'),'FERRET-PC')
    
    gf.stimDevice = 'RX8';
    gf.recDevice  = 'RZ2';
    
elseif strcmp(getenv('computername'),'Rockefeller-HP1')
        
    gf.stimDevice = 'RZ6';
    gf.recDevice  = 'RZ2';
    
else
    gf.stimDevice = 'RM1';
    gf.recDevice  = [];
end
 
% Enable start if past 12:00
t = clock;
if t(4) > 12
    set(handles.startH,'enable','on') 
    set(handles.weight,'userdata',nan)
else
    set(handles.startH,'enable','on') 
    set(handles.weight,'userdata',0)
end    

% Load folder options
load_userList(handles)
load_subjectList(handles)

% set(gcf,'units','pixels','position',[520 168 929 637]);



%%%%%%%%%%%%%%% 1/5 User selects directory for stage files %%%%%%%%%%%%%%%%

% Load available directories

function load_userList(handles)

    % home_dir directory
    % Please note that the home_dir directory is specific for each computer.
    % Adding GoFerret will require lines home_dir to be redefined (twice) below

    home_dir = strcat('C:\Users\',getenv('username'),'\Documents\MATLAB\Applications\GoFerret');

    % Writes files from directory (home_dir) to left listbox
   
    dir_struct                  = lsDir(home_dir);
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    set(handles.userList,   'String',handles.file_names,'Value',1)
    set(handles.userEdit,   'String',home_dir)
    
    
% Select task folder (e.g. ST_TimbreDiscrim)   
function userList_Callback(~,~,handles)                     %#ok<*DEFNU>
    
    global gf

    % Return to home_dir directory
    %  Redefine on new computers
    
    home_dir = strcat('C:\Users\',getenv('username'),'\Documents\MATLAB\Applications\GoFerret');     
    
    dir_struct           = lsDir(home_dir);
    [~,sorted_index]     = sortrows({dir_struct.name}');    
    handles.is_dir       = [dir_struct.isdir];
    handles.sorted_index = sorted_index;

    % Open selected file and load filenames (m files only)
    index_selected  = get(handles.userList,'Value');
    file_list       = get(handles.userList,'String');
    filename        = file_list{index_selected};
    filename        = fullfile(home_dir, filename);
    
    if  handles.is_dir(handles.sorted_index(index_selected))
                
        addpath(filename)
        
        gf.directory = filename;
        load_stageList(gf.directory, handles)
    end


% Load available stage files
function load_stageList(dir_path,handles)

    % Writes matlab files from stage directory (dir_path) to center listbox

    dir_path = strcat(dir_path,'\stages'); % Goes directly into stage file: could cause problems if GoFerret structure is not adhered to             
    cd(dir_path)
    
    dir_struct = dir('*.m'); % Matlab files only
    
    
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    
    % Select first
    set(handles.stageList,'String',handles.file_names,'Value',1)
    
    % Set edit box as selected file
    index_selected  = get(handles.stageList,'Value');
    file_list       = get(handles.stageList,'String');
    
    set(handles.stageEdit,'String',file_list{index_selected})
    
    % Enables default to first file without further user input
    global gf
    gf.filename = file_list{index_selected};
    gf.filename = gf.filename(1:length(gf.filename)-2); % Remove extension
    
    % Load Parameters list for default file
    load_parameterList(gf.directory,handles)

    
    
    
%%%%%%%%%%%%%%%%%%%%%%%% 2/5 Select stage file %%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stageList_Callback(~, ~, handles)
  
    global gf

    index_selected  = get(handles.stageList,'Value');
    file_list       = get(handles.stageList,'String');
    gf.filename     = file_list{index_selected};
    
    %remove '.m' extension
    gf.filename     = gf.filename(1:length(gf.filename)-2);
    
    load_parameterList(gf.directory,handles)
   
    
    function load_parameterList(dir_path, handles)

    global gf    
        
    % Writes text files from parameters directory (dir_path) to right listbox
    
    dir_path = strcat(dir_path,'\parameters'); % Goes directly into stage file: could cause problems if GoFerret structure is not adhered to             
    cd(dir_path)
    
    dir_struct                  = dir(sprintf('%s*',gf.filename(1:7))); % all file names with the 'level #' prefix
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
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

function load_subjectList(handles)

    save_dir = 'D:\Behavior';
    
    dir_struct                  = lsDir(fullfile(save_dir,'F*'));
    [sorted_names,sorted_index] = sortrows({dir_struct.name}');
    handles.file_names          = sorted_names;
    handles.is_dir              = [dir_struct.isdir];
    handles.sorted_index        = sorted_index;
    
    guidata(handles.figure1,handles)
    
    set(handles.subjectList,'String',handles.file_names,'Value',1)
    
    % Set temporary as default
    set(handles.editSaveDir,'String',save_dir)
    set(handles.subjectEdit,'String','Temporary')  
    

function subjectList_Callback(~, ~, handles)    
    
    index_selected  = get(handles.subjectList,'Value');
    file_list       = get(handles.subjectList,'String');
    save_dir        = file_list{index_selected};
    
    
    set(handles.subjectEdit,'String',save_dir)  
    
    save_dir = strcat('D:\Behavior\',save_dir);    
    set(handles.editSaveDir,'String',save_dir)
    
    
function subjectEdit_Callback(~, ~, handles)
    
save_dir = get(handles.subjectEdit,'string');
save_dir = strcat('D:\Behavior\',save_dir);

if isdir(save_dir)
    set(handles.editSaveDir,'String',save_dir)
else
    msgbox('Subject is not valid - save directory not changed','Warning','warn')
end



%%%%%%%%%%%%%%%%% 5/5 Close interface and enter online GUI %%%%%%%%%%%%%%%%
function startH_Callback(~, ~, handles)

global gf
gf.saveDir  = get(handles.editSaveDir,'string');  
gf.calibDir = get(handles.calibrationFolder,'string');  
% Add directory and subfolders to path definition
addpath( genpath( gf.directory ))

% Save weight to file
weightData = get(handles.weight,'userdata');

if ~isnan(weightData)   % If afternoon flag not set

    if numel(weightData) == 1, weightData = [0 0]; end
    
    weightDir  = get(handles.weightDir,'string');
    weightData = array2table(weightData,'variableNames',{'DateNum','Weight'});
    ferret     = get(handles.subjectEdit,'string');
    weightFile = fullfile(weightDir, [ferret '.mat']);

    if strcmp('Mon',datestr(now,'ddd'))
        figure('name',sprintf('%s: %dg %.0fg %.1fml', ferret, weightData.Weight, weightData.Weight*0.88, weightData.Weight*.06))
    end

    
    load(weightFile, 'T')
    T = [T; weightData];
    save(weightFile,'T')
end



close(handles.figure1)

parameters

       

function flush_Callback(~, ~, ~)

global DA

% Options
valve_no = [3 9];
valve_time = 2;

% Connect to TDT
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');    
DA.SetSysMode(2); % Set to preview
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

% Close connections and windows
DA.CloseConnection



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
load( fullfile( pathname, [subject '.mat']));


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
        
   
  


