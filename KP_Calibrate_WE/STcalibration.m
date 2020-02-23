function varargout = STcalibration(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @STcalibration_OpeningFcn, ...
                   'gui_OutputFcn',  @STcalibration_OutputFcn, ...
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


function STcalibration_OpeningFcn(hObject,~,handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

global DA
DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');




function varargout = STcalibration_OutputFcn(~,~,handles) 
varargout{1} = handles.output;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Device (Helper functions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function device = getDevice(handles) %#ok<*DEFNU>

global DA

device.error = 0;

RX8 = get(handles.RX8on,'value');
RZ6 = get(handles.RZ6on,'value');

if RZ6 && ~RX8,
    device.type       = 'RZ6';
    device.fStim      = DA.GetDeviceSF(device.type);
    device.delaySamps = 86;
    
    % Get input channel
    if get(handles.inA,'value') && ~get(handles.inB,'value')        
        device.in = 'A';    
    elseif ~get(handles.inA,'value') && get(handles.inB,'value') 
        device.in = 'B';        
    elseif get(handles.inA,'value') && get(handles.inB,'value')
        msgbox('Multiple RZ6 inputs selected - please select only one to continue',...
                'Warning','warn')
        device.error = 1;
    elseif ~get(handles.inA,'value') && ~get(handles.inB,'value')
        msgbox('No RZ6 inputs selected - please select to continue',...
                'Warning','warn'); 
        device.error = 1;
    end
    
    % Get output channel  
    device.spkrIdx = NaN;   
    
    if get(handles.outA,'value') && ~get(handles.outB,'value')
        device.out     = 'A';
        device.spkrIdx = 1;        
    elseif ~get(handles.outA,'value') && get(handles.outB,'value')
        device.out     = 'B';        
        device.spkrIdx = 2;   
    elseif get(handles.outA,'value') && get(handles.outB,'value')
        msgbox('Multiple RZ6 outputs selected - please select only one to continue')
        device.error = 1;
    elseif ~get(handles.outA,'value') && ~get(handles.outB,'value')
        msgbox('No RZ6 outputs selected - please select to continue'); 
        device.error = 1;
    end
    
    list = get( handles.RZ6inputGain, 'string');        % Input Gain
    val  = get( handles.RZ6inputGain, 'value');    
    device.inputGain  = str2num( list{val});
    
    list = get( handles.RZ6outputAttn, 'string');       % Output Attn
    val  = get( handles.RZ6outputAttn, 'value');
    device.outputAttn = str2num( list{val});
    
elseif RX8 && ~RZ6,
    
    device.type       = 'RX8';
    device.fStim      = DA.GetDeviceSF(device.type);
    device.in         = 'Ch1';
    device.inputGain  = 'Not applicable';    
    device.outputGain = 'Not applicable';
    device.delaySamps =86;
    
    % Get output channel
    list           = get(handles.RX8output,'string');
    val            = get(handles.RX8output,'value');
    device.out     = list{val};   
    device.spkrIdx = str2num( regexprep(device.out,'Speaker ',''));
else
    msgbox('Device options incompatible','Warning','warn')
    device.error = 1;
end


if isfield(device,'delaySamps');
    set(handles.delaySamps,'string',num2str(device.delaySamps))
end

function build0play(signal, device)

% Play sounds using the build0.rco file in the GolayCalib.wsp project
% DO NOT use this function to record sounds as there are no pauses for
% buffer reading before device mode change

global DA
DA.SetSysMode(1);
pause(3)
DA.WriteTargetVEX( sprintf('%s.data', device.type), 0, 'F32', signal);
DA.SetTargetVal( sprintf('%s.length', device.type), length(signal));
DA.SetTargetVal( sprintf('%s.play', device.type), 0);
DA.SetTargetVal( sprintf('%s.play', device.type), 1);
pause(length(signal)/device.fStim)
DA.SetSysMode(0);


function deviceDelay_Callback(~, ~, handles)
% Send a single pulse (placed within a one second long zero vector) through 
% the system to measure the delay caused by  DAC & ADC. 
%
% Requires feedback loop from DAC output to ADC input without
% speaker or amplifier.

device      = getDevice(handles);        % see Device section above
signal      = zeros( round(device.fStim), 1);
idx         = round(length(signal)/10);
signal(idx) = 1;

% Run through TDT
global DA
DA.SetSysMode(2);
pause(3)

% Flow processing for original 8 speakers
if DA.SetTargetVal( sprintf('%s.sel1', device.type),  ceil(device.spkrIdx/4)),
    DA.SetTargetVal( sprintf('%s.sel10', device.type), device.spkrIdx-1);
    DA.SetTargetVal( sprintf('%s.sel11', device.type), device.spkrIdx-5);

elseif DA.SetTargetVal( sprintf('%s.sel1KW', device.type),  ceil(device.spkrIdx/12)),
    DA.SetTargetVal( sprintf('%s.sel10KW', device.type), device.spkrIdx-9);
    DA.SetTargetVal( sprintf('%s.sel11KW', device.type), device.spkrIdx-13);    
end


DA.WriteTargetVEX( sprintf('%s.data', device.type), 0, 'F32', signal');
DA.SetTargetVal( sprintf('%s.length', device.type), length(signal));
DA.SetTargetVal( sprintf('%s.play', device.type), 0);
DA.SetTargetVal( sprintf('%s.play', device.type), 1);
pause(length(signal)/device.fStim)

% Get recorded data
rec = DA.ReadTargetVEX( sprintf('%s.record',device.type),0,length(signal),'F32','F64');
pause(3)

% Calculate delay
stimIdx = find(signal == max(signal));
recIdx  = find(rec == max(rec));
delay   = recIdx - stimIdx;

% User warnings
if max(rec) < 1/3;
    msgbox('Recorded data indicate lack of input - check hardware (BNC) connections','Warning','warn')
end

if delay < 0, 
    msgbox('Delay is less than zero - something wrong','Warning','warn')
end

% Draw
figure('NumberTitle','off','Name',sprintf('%s delay = %d samples', device.type, delay))
hold on
plot(signal);  plot(idx, signal(stimIdx),'ok')
plot(rec,'r'); plot(recIdx, rec(recIdx),'ok')
xlim([recIdx-delay*5 stimIdx+delay*5])
hold off

% Close TDT
DA.SetSysMode(0);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             Golay Codes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function playGolay_Callback(~, ~, handles)

global DA

golaylen    = str2num( get(handles.golaylen, 'string'));                    %#ok<*ST2NM>
trim        = str2num( get(handles.trim,'string'));
gap         = str2num( get(handles.gap,'string'));
firFlt      = str2num( get(handles.firFlt,'string'));
delaySamps  = str2num( get(handles.delaySamps,'string'));

device  = getDevice(handles);        % see Device section above

% If checks on user input reveal no errors
if ~device.error,

    
    % Produce Golay codes
    calib = o4golayrec(golaylen, trim, gap, firFlt, delaySamps, device.type, device.spkrIdx);

    % Include more info in calibration file to allow better interpretation during usage
    calib.device = device; 

    % Error tree:
    % Check for clipping and also consistency of results with user input 
    % (I.e do we see a golay signal on the input channel chosen by the user
    error = 0;

    if max(calib.inbuf1) < 0.1 && max(calib.inbuf2) < 0.1,
        error = 1;
        msgbox('Voltage traces indicate no input to device - please check. Data will not be saved',...
                'Warning','Warn')    
    else

        if strcmp(calib.device.in,'A') && max(calib.inbuf2) > max(calib.inbuf1),    
            error = 1;
            msgbox('Warning, voltage recordings indicate device input on IN-B whilst user has selected IN-A. Please amend - data will not be saved!',...
                    'Warning','warn'); 
        end

        if strcmp(calib.device.in,'B') && max(calib.inbuf1) > max(calib.inbuf2),
            error = 1;
            msgbox('Warning, voltage recordings indicate device input on IN-A whilst user has selected IN-B. Please amend - data will not be saved!',...
                    'Warning','warn'); 
        end

        if max(calib.inbuf1) > 9 || max(calib.inbuf2) > 9,
            error = 1;
            msgbox('Warning, Clipping detected, please alter gain / attn settings - data will not be saved!',...
                    'Warning','warn'); 
        end   
    end
    
    if ~error,        
        set(handles.fivekp1text,'string',sprintf('In-A, 5 kHz value = %.1f dB', calib.fivekp1))       
        set(handles.fivekp2text,'string',sprintf('In-B, 5 kHz value = %.1f dB', calib.fivekp2))
        
        uisave('calib',sprintf('%s.m', datestr(now,'dd-mmm-yy')))        
    else        
        set(handles.fivekp1text,'string','In-A, 5 kHz value = ?')        
        set(handles.fivekp2text,'string','In-B, 5 kHz value = ?')
    end    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Tones
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 5k tone
function play5k_Callback(~,~,handles)

device = getDevice(handles);        % see Device section above

if get(handles.toneCalib,'value'),
    set(handles.toneCalib,'value',0)
    msgbox('Turned tone calibration off for 5 kHz standard')
end

token = tone(device.fStim, 5e3, 1);
size(token)

build0play(token, device) % see Device section above



% Make calibration file for tones
function makeToneCalibration_Callback(~, ~, ~)

% Make user get the calibration file to load the calib structure
uiimport('-file','C:\Calibrations')

if ~exist('calib','var')

    msgbox('Loaded file does not contain calib structure. Please check file',...
            'Warning','warn')
else
    % Dialog box for arguments
    prompt      = {'Level for a 5 kHz tone (dB):','Steps:','Max Frequency (Hz):'};
    dlg_title   = 'makeFRAfilter arguments';
    num_lines 	= 1;
    def         = {'','1','30000'};    
    answer      = inputdlg(prompt,dlg_title,num_lines,def); 
    tone5k      = str2num(answer{1});
    steps       = str2num(answer{2});
    maxFreq     = str2num(answer{3});
    
    % Select calibration data based on device input settings
    if ~isfield(calib,'device'),
        
        figure
        subplot(1,2,1); plotSpect(calib.chan1, calib.ADrate); title('chan1')
        subplot(1,2,2); plotSpect(calib.chan2, calib.ADrate); title('chan2')
        
        chan = input('Which channel do you want to take calibration data from');
        OutputL = eval( sprintf('calib.chan%d', chan));        
    else        
        if strcmp( calib.device.in,'A')
            fivekp  = calib.fivekp1;
            OutputL = calib.chan1;    

        elseif strcmp( calib.device.in,'B')       
            fivekp  = calib.fivekp2;
            OutputL = calib.chan2;    
        end
    end
    
    % Create tone filter
    absOutputL = OutputL.*10.^((tone5k-fivekp)/20);
    
    makeFRAfilter( 10^(96/20)./absOutputL, calib.ADrate, steps, maxFreq)
end




% Attenuation sweep
function attnSweep_Callback(~,~,handles)

device = getDevice(handles);        % see Device section above

if get(handles.toneCalib,'value'),
    set(handles.toneCalib,'value',0)
    msgbox('Turned tone calibration off for attenuation sweep')
end

% Get attenuation vector
attnMin  = str2num( get(handles.attnMin,'string'));
attnMax  = str2num( get(handles.attnMax,'string'));
attnStep = str2num( get(handles.attnStep,'string'));
attns    = attnMin : attnStep : attnMax; 
nAttn    = length(attns);

% Generate stimulus
token = tone(device.fStim, 5e3, 1);
token = [token, zeros(size(token))];    % Add interval pre-emptively

% Create stimulus series
stim = zeros( length(token) * nAttn, 1);

for i = 1 : nAttn,    
    start = length(token) * (i-1) + 1;
    stop  = length(token) * i;
    
    stim(start:stop) = token .* 10 ^ (-attns(i) /20);    
end

build0play(stim, device) % see Device section above


% Plot output and provide analysis
%
%
%
%

return


% Frequency sweep
function freqSweep_Callback(~,~,handles)

device = getDevice(handles);        % see Device section above

% Get sweep parameters
freqMin  = str2num( get(handles.freqMin,'string'));
freqMax  = str2num( get(handles.freqMax,'string'));
freqStep = str2num( get(handles.freqStep,'string'));
freqs    = freqMin(1) * 2.^(0 : freqStep(1) : log(freqMax(1)/freqMin(1)) /log(2)); % Octave spacing
nFreq    = length(freqs);


% Get calibration attenuations if needed
if get(handles.toneCalib,'value'),    
    toneCalib = importdata(uigetfile('C:\\Calibrations'));    
end

% Generate stimulus sweep
stim = zeros(ceil(nFreq * device.fStim * 2), 1);

for i = 1 : nFreq,
   
    if get(handles.toneCalib,'value'),
        calibAttn = interp1(toneCalib(:,1), toneCalib(:,2), freqs(i), 'linear');    
    else
        calibAttn = 0;
    end
    
    
    token = tone(device.fStim, freqs(i), 1);
    token = token .* 10 ^ (-calibAttn /20);     % Apply calibration attn        
 
    start = length(token)*2 * (i-1) + 1;
    stop  = start + length(token) - 1;
    
    stim(start:stop) = token;
end

% Play from TDT
if length(stim) > 5e6,
    msgbox('Stimulus exceeds buffer length','Warning','warn')
else    
    build0play(stim', device) % see Device section above
end

return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         Make filters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function makeInverseFlt_Callback(~, ~, ~)

% Get calibration file
[filename, pathname] = uigetfile('C:\Calibrations');
load(fullfile(pathname, filename));

if ~exist('calib','var')

    msgbox('Loaded file does not contain calib structure. Please check file',...
            'Warning','warn')
else
    
    % Select calibration data based on device input settings
    if ~isfield(calib,'device'),
        
        figure
        subplot(1,2,1); plotSpect(calib.chan1, calib.ADrate); title('chan1')
        subplot(1,2,2); plotSpect(calib.chan2, calib.ADrate); title('chan2')
        
        chan = input('Which channel do you want to take calibration data from? ');
        
    else        
        if strcmp( calib.device.in,'A')
            chan = 1;   

        elseif strcmp( calib.device.in,'B')       
            chan = 2;  
            
        else
            chan = input('Choose channel:');
        end
    end
        
    flt = BuildInverseFilter(calib, chan, 30000);
        
    uisave('flt',fullfile(pathname, filename))
    
end


% Play noise
function pushbutton11_Callback(~,~,handles)

device = getDevice(handles);        % see Device section above
noise  = rand(floor(device.fStim),1); 

applyInverseFilter(noise, device)



% Play golay codes with filters
function inverseGolay_Callback(~, ~, handles)

[filename, pathname] = uigetfile('C:\Calibrations');
load(fullfile(pathname, filename));                     % Contains 'flt'

golaylen    = str2num( get(handles.golaylen, 'string'));                    %#ok<*ST2NM>
trim        = str2num( get(handles.trim,'string'));
gap         = str2num( get(handles.gap,'string'));
delaySamps  = str2num( get(handles.delaySamps,'string'));

device  = getDevice(handles);        % see Device section above


calib = o4golayrec(golaylen, trim, gap, flt, delaySamps, device.type, device.spkrIdx);


function applyInverseFilter(signal, device)

% Load filter
[filename, pathname] = uigetfile('C:\Calibrations');
load(fullfile(pathname, filename));

% Test without inverse filter
unfltSig = tdtSys3play( signal', device.type, device.spkrIdx);

eval( sprintf('unfltSpect = unfltSig.chan%s;',regexprep(device.in,'Ch','')));

% Draw spectrum
figure('color','w')
subplot(2,2,1); plot(unfltSig.chan1);   title('Unfiltered')
subplot(2,2,2); plotSpect(unfltSpect, device.fStim); title('Unfiltered: chan1')



% Filter and play again
% if get(handles.applyInverseFilterToNoise, 'value'),

    
    fltNoise = conv(signal, flt);            
    fltSig   = tdtSys3play( fltNoise', device.type, device.spkrIdx);
        
        % Plot    
    eval( sprintf('fltSpect = fltSig.chan%s;',regexprep(device.in,'Ch','')));
    subplot(2,2,3); plot(fltSig.chan1); title('Filtered')
    subplot(2,2,4); plotSpect(fltSpect, device.fStim); title('Filtered: chan1')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function exit_Callback(~, ~, handles)

global DA

% Close connection
DA.SetSysMode(0);
DA.CloseConnection;

clear DA
close(handles.figure1)


function playVAS_Callback(~,~,~)

function defineBnK_Callback(~,~,~)
function golaylen_Callback(~,~,~)
function golaylen_CreateFcn(~,~,~)
function trim_Callback(~,~,~)
function trim_CreateFcn(~,~,~)
function gap_Callback(~,~,~)
function gap_CreateFcn(~,~,~)
function firFlt_Callback(~,~,~)
function firFlt_CreateFcn(~,~,~)
function delaySamps_Callback(~,~,~)
function delaySamps_CreateFcn(~,~,~)
function RX8output_CreateFcn(~, ~, ~)
function RX8output_Callback(~, ~, ~)
function inA_Callback(~, ~, ~)
function inB_Callback(~, ~, ~)
function outA_Callback(~,~,~)
function outB_Callback(~,~,~)
function RZ6outputAttn_Callback(~,~,~)
function RZ6outputAttn_CreateFcn(~,~,~)
function RZ6inputGain_Callback(~,~,~)
function RZ6inputGain_CreateFcn(~,~,~)
function attnMin_Callback(~,~,~)
function attnMin_CreateFcn(~,~,~)
function attnMax_Callback(~,~,~)
function attnMax_CreateFcn(~,~,~)
function attnStep_Callback(~,~,~)
function attnStep_CreateFcn(~,~,~)
function freqMin_Callback(~,~,~)
function freqMin_CreateFcn(~,~,~)
function freqMax_Callback(~,~,~)
function freqMax_CreateFcn(~,~,~)
function freqStep_Callback(~,~,~)
function freqStep_CreateFcn(~,~,~)
function toneCalib_Callback(~, ~, ~)
