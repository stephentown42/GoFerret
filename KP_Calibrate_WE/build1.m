%build 1

global DA

%Connect to TDT

DA = actxcontrol('TDevAcc.X');
DA.ConnectServer('Local');
invoke(DA,'SetSysMode',1);

 
SampleRate = DA.GetDeviceSF('RZ6');

%Variables
Data       = tone(SampleRate, 300, 1);
BufferSize = length(Data);

%Load variables to device
DA.SetTargetVal('RZ6.BufferSize',BufferSize)
DA.WriteTargetVEX('RZ6.Data',0,'F32',Data)

%Trigger sound
DA.SetTargetVal('RZ6.play',0)
DA.SetTargetVal('RZ6.play',1)
DA.SetTargetVal('RZ6.play',0)

DA.GetTargetVal('RZ6.Index')

%Plot data
if exist('f','var') == 0,
    f = figure;
end

hold on
    %Matlab
   % subplot(1,2,1)
    x = 1 : BufferSize;
    plot(x,Data,'g')
    
    %OpenEx
    BufferSize2 = DA.GetTargetVal('RZ6.BufferSize');
    Data2       = DA.ReadTargetVEX('RZ6.Data',0,BufferSize2,'F32','F32');
    
    %subplot(1,2,2)    
    x = 1 : BufferSize2;
    plot(x,Data2,'r')

hold off