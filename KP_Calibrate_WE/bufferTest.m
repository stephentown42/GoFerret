% Buffer test
%
% 
% ST note 5 Nov 2012 
% I think this script is designed to help determine the delay for a
% specific device. Parameter tags look a bit old now - script may need
% updating.

global DA

% Signal length
len = 2146; %samples
DA.SetTargetVal('RZ6.length',len);

% Length to record
recordT     = 1;                                % seconds
sampleRate  = DA.GetDeviceSF('RZ6');                       % hz
recordS     = ceil( recordT * sampleRate);      % samples

DA.SetTargetVal('RZ6.recLength',recordS);

% Reset Buffer
DA.SetTargetVal('RZ6.reset',0)
DA.SetTargetVal('RZ6.reset',1)
DA.SetTargetVal('RZ6.reset',0)

% Single transition signal

signal       = zeros(1,len);
signal(1000) = 0.1;

rec = tdtSys3play(signal);

pause(0.5)


% Reset Buffer
DA.SetTargetVal('RZ6.reset',0);
DA.SetTargetVal('RZ6.reset',1);
DA.SetTargetVal('RZ6.reset',0);

% Plot data
f = figure;

subplot(2,1,1)
plot(1:len, signal,'k')
box off

subplot(2,1,2)
hold on
plot(1:length(rec.chan1), rec.chan1,'k')
xlim([0 2500])

    % Time of signal
    Rmax = max(rec.chan1);
    i    = find(rec.chan1 == Rmax); 
    
    %plot([i i],[0 Rmax*1.25],'r')
    text(i, Rmax*1.3, sprintf('%d, %.3f',i,Rmax),'FontSize',8,'color','r')
    
    %Median signal
    Rmed = median(rec.chan1(1:len+98));

    plot(1:length(rec.chan1), Rmed*ones(1,length(rec.chan1)))
    text(250, 0.01, sprintf('%.3f', Rmed),'FontSize',8,'color','b')
