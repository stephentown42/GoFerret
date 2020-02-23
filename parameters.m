function varargout = parameters(varargin)
% PARAMETERS MATLAB code for parameters.fig
%      PARAMETERS, by itself, creates a new PARAMETERS or raises the existing
%      singleton*.
%
%      H = PARAMETERS returns the handle to a new PARAMETERS or the handle to
%      the existing singleton*.
%
%      PARAMETERS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PARAMETERS.M with the given input arguments.
%
%      PARAMETERS('Property','Value',...) creates a new PARAMETERS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before parameters_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to parameters_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help parameters

% Last Modified by GUIDE v2.5 21-Dec-2011 10:18:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @parameters_OpeningFcn, ...
                   'gui_OutputFcn',  @parameters_OutputFcn, ...
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


% --- Executes just before parameters is made visible.
function parameters_OpeningFcn(hObject, ~, handles, varargin)

handles.output = hObject;
guidata(hObject, handles);

%Access parameters
global gf

directory = strcat(gf.directory,'\parameters');
cd(directory)

[a b] = textread(gf.paramFile, '%s %s'); 
a     = [a b];
set(handles.uitable1,'Data',a); 



function varargout = parameters_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;


function revert_Callback(~, ~, handles)                      %#ok<*DEFNU>

%Access parameters
cd('C:\Users\Ferret\Documents\MATLAB\Applications\GoFerret\SD_Loc\parameters')

[a b] = textread('stage1.txt', '%s %s'); 
a     = [a b];

set(handles.uitable1,'Data',a); 


function accept_Callback(~, ~, handles)

global gf

data = get(handles.uitable1,'Data');

for  i = 1 : length(data),
    var = char(data(i,1));
    val = char(data(i,2));
    eval(sprintf('gf.%s = %s;',var, val)); %Note that this coding prohibts string parameters
end

close(handles.figure1)
online






% --- Executes during object creation, after setting all properties.
function device_CreateFcn(~, ~, ~)
