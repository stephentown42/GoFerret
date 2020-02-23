% Just need to run this once
global DA;
DA=[];

if ~iscom(DA),
    DAfig = figure('position',[0 0 100 100]);
    DA    = actxcontrol('TDevAcc.X');

    DA.ConnectServer('Local');
end

stimDevice = 'RX8_1';
recDevice = 'RZ6_1';


% Get sample rate
fStim = DA.GetDeviceSF(stimDevice);% Engage TDT (preview mode)
fRec = DA.GetDeviceSF(recDevice);% Eng

if fStim == fRec & fRec>45000
    disp('Good: Sample rates are appropriate for playing and recording sounds <25k')
else
    disp('Check sample rates!!')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

golaylen = 8; % default is 8
% Get golay codes

[ga,gb]  = golay(golaylen); 
ga       = [ga zeros(1,3*length(ga))]; 
gb       = [gb zeros(1,3*length(gb))]; 




% Delay arguments for GOLAY CODES


pre_time  = 0.01;
pre_samps = ceil(pre_time * fStim);

trim = 0; %default to zero
% trim (in ms) specifies how much of the recorded signal delay to trim off
trimtaps = 0;
if exist('trim') 
   trimtaps = ceil((trim/1000)*fStim);               % convert milliseconds into samples
end


% gap (in ms) specifies how much of a time delay to leave between 
gap = 4;
% presentations of each code in the pair
delaytaps = 0;
if exist('gap')
   delaytaps = ceil((gap/1000)*fStim);               % convert milliseconds into samples
end;

% Build signal to play from golay pair and delays

outbuf = [ga,...
          zeros(1,trimtaps),...
          zeros(1,delaytaps),...
          gb,...
          zeros(1,trimtaps)];

% firFlt is a finite impulse response filter which will be used to pre-filter
% the golay codes if specified. (E.g. 0.1)      
if exist('firFlt') 
    outbuf = conv(firFlt,outbuf);         %if firFlt is an single value, this is just a multiplication
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Record
record    = 1;
scaleFact = max(abs(outbuf));
% inbuf     = tdtSys3play(outbuf*(10/scaleFact));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
level = 2.25;
% level = 4;
% when calibrating need to make louder as the inverse
% load('C:\Users\Ferret 2\Documents\MATLAB\Appltications\GoFerret\KP_Calibrate_WE\CalibrationFilters\CalibrationFilter_190220.mat')
% load('C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\Calibration\Calib_Chan16_Rep1.mat')
speakerNo = 16;

% outbuf = rand(1,4000);
% outbuf = envelope(outbuf,244);

% outbuf = filter(avSpkrFlt(2,:),10,outbuf);
% outbuf = conv(outbuf,calib.InvFlt,'same');
% % figure
% for i = 1:8
%     % plotSpect(fft(flt),fs,'r')
% 
%     plot(avSpkrFlt(i,:)); hold on
% end

if record == 1,   

% Carve individual segments out of recorded buffer
delaySamps = 98; % default 98 samples delay before presenting golay codes

    outbuf = [zeros(1,pre_samps) outbuf];
    delaySamps = delaySamps + pre_samps;

    %channel 13= brown
    %Channel 14 = yellow 
    %Channel 15 = Orange
    % channel 16 = Red
    %channel 17= green
    %channel 18= silver
    %channel 19= purple
    %channel 20= blue
    
    
    pause(2)
    inbuf = tdtSys3playAndRecord(outbuf*(level/scaleFact), stimDevice,recDevice,speakerNo,fStim)'; 
    
    
    % Assign voltage traces to output structure
    irf.inbuf1 = inbuf.chan1;
    %irf.inbuf2 = inbuf.chan2;
    
    % analyse channel1
    astart  = delaySamps + trimtaps;
    bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
    
    sumA    = inbuf.chan1( astart + 1 : astart + length(ga));   %response to ga
    sumB    = inbuf.chan1( bstart + 1 : bstart + length(gb));   %response to gb

    % Plot inbuf.chan1
    figure('name',          sprintf('Golay calibration: %s', datestr(now,'HH:MM')),...
           'numbertitle',   'off')
    subplot(2,2,1);
    x = 1 : length(inbuf.chan1);
    plot(x, inbuf.chan1);               %plot(tAxis,inbuf.chan1);
   

    title('chan1');
    xlim([0 5000])                      %xlim([0,t_last]);
    xlabel('Sample')                    %xlabel('time (s)'); 
    ylabel('Volt');

    % Check lengths and produce spectrogram info
    irf.chan1 = golanal(sumA(:)',sumB(:)',ga(:)',gb(:)'); 

    subplot(2,2,2); 
    [~, irf.fivekp1] = plotSpect(irf.chan1, fRec);        %fivekp = 5 kHz point


%     % analyse channel2
%     astart  = delaySamps + trimtaps;
%     bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
%     
%     sumA    = inbuf.chan2( astart + 1 : astart + length(ga));   %response to ga
%     sumB    = inbuf.chan2( bstart + 1 : bstart + length(gb));   %response to gb
%    
%     % Plot inbuf.chan1
%     subplot(2,2,3);
%     plot(x, inbuf.chan2);               
% 
%     xlim([0 2600])                      %set(gca,'xlim',[0,t_last]);
%     title('chan2'); 
%     xlabel('Sample')                    %xlabel('time (s)'); 
%     ylabel('Volt');
% 
%     % Check lengths and produce spectrogram info
%     irf.chan2 = golanal(sumA(:)',sumB(:)',ga(:)',gb(:)'); 
% 
%     subplot(2,2,4); 
%     [~, irf.fivekp2] = plotSpect(irf.chan2, irf.ADrate);        %fivekp = 5 kHz point
else
    %inbuf = tdtSys3play(outbuf*(10/scaleFact));  
    %sound(outbuf*(10/scaleFact),irf.ADrate)
    
    pause(0.5)

    % Reset Buffer
%     DA.SetTargetVal('RZ6.reset',0);
%     DA.SetTargetVal('RZ6.reset',1);
%     DA.SetTargetVal('RZ6.reset',0);
    
   %plot data

   
    for i = 1 : 2,
        
        figure
        subplot(2,1,1)
        x = 1 : length(outbuf);
        plot(x,outbuf)
        title(sprintf('Outbuffer %d', i))
        
        y = eval(sprintf('inbuf.chan%d',i));
        x = 1 : length(y);
        
        subplot(2,1,2)
        plot(x,y,'k')
        title(sprintf('Input %d',i));
        xlim([0 2600])
    end
end

% now save 
calib = irf;

calib.ADrate = fStim;
calib.InvFlt = BuildInverseFilter(calib,1,24414);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% level = 2.25;
level = 4;
% when calibrating need to make louder as the inverse
% load('C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\CalibrationFilters\CalibrationFilter_190220.mat')
% load('C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\Calibration\Calib_Chan16_Rep1.mat')

outbuf = rand(1,4000);
outbuf = envelope(outbuf,244);

% outbuf = filter(avSpkrFlt(2,:),10,outbuf);
outbuf = conv(outbuf,calib.InvFlt,'same');
% % figure
% for i = 1:8
%     % plotSpect(fft(flt),fs,'r')
% 
%     plot(avSpkrFlt(i,:)); hold on
% end

if record == 1,   

% Carve individual segments out of recorded buffer
delaySamps = 98; % default 98 samples delay before presenting golay codes

    outbuf = [zeros(1,pre_samps) outbuf];
    delaySamps = delaySamps + pre_samps;

    %channel 13= brown
    %Channel 14 = yellow 
    %Channel 15 = Orange
    % channel 16 = Red
    %channel 17= green
    %channel 18= silver
    %channel 19= purple
    %channel 20= blue
    
    
    pause(2)
    inbuf = tdtSys3playAndRecord(outbuf*(level/scaleFact), stimDevice,recDevice,speakerNo,fStim)'; 
    
    
    % Assign voltage traces to output structure
    irf.inbuf1 = inbuf.chan1;
    %irf.inbuf2 = inbuf.chan2;
    
    % analyse channel1
    astart  = delaySamps + trimtaps;
    bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
    
    sumA    = inbuf.chan1( astart + 1 : astart + length(ga));   %response to ga
    sumB    = inbuf.chan1( bstart + 1 : bstart + length(gb));   %response to gb

    % Plot inbuf.chan1
    figure('name',          sprintf('Golay calibration: %s', datestr(now,'HH:MM')),...
           'numbertitle',   'off')
    subplot(2,2,1);
    x = 1 : length(inbuf.chan1);
    plot(x, inbuf.chan1);               %plot(tAxis,inbuf.chan1);
   

    title('chan1');
    xlim([0 5000])                      %xlim([0,t_last]);
    xlabel('Sample')                    %xlabel('time (s)'); 
    ylabel('Volt');

    % Check lengths and produce spectrogram info
    irf.chan1 = golanal(sumA(:)',sumB(:)',ga(:)',gb(:)'); 

    subplot(2,2,2); 
    [~, irf.fivekp1] = plotSpect(irf.chan1, fRec);        %fivekp = 5 kHz point


%     % analyse channel2
%     astart  = delaySamps + trimtaps;
%     bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
%     
%     sumA    = inbuf.chan2( astart + 1 : astart + length(ga));   %response to ga
%     sumB    = inbuf.chan2( bstart + 1 : bstart + length(gb));   %response to gb
%    
%     % Plot inbuf.chan1
%     subplot(2,2,3);
%     plot(x, inbuf.chan2);               
% 
%     xlim([0 2600])                      %set(gca,'xlim',[0,t_last]);
%     title('chan2'); 
%     xlabel('Sample')                    %xlabel('time (s)'); 
%     ylabel('Volt');
% 
%     % Check lengths and produce spectrogram info
%     irf.chan2 = golanal(sumA(:)',sumB(:)',ga(:)',gb(:)'); 
% 
%     subplot(2,2,4); 
%     [~, irf.fivekp2] = plotSpect(irf.chan2, irf.ADrate);        %fivekp = 5 kHz point
else
    %inbuf = tdtSys3play(outbuf*(10/scaleFact));  
    %sound(outbuf*(10/scaleFact),irf.ADrate)
    
    pause(0.5)

    % Reset Buffer
%     DA.SetTargetVal('RZ6.reset',0);
%     DA.SetTargetVal('RZ6.reset',1);
%     DA.SetTargetVal('RZ6.reset',0);
    
   %plot data

   
    for i = 1 : 2,
        
        figure
        subplot(2,1,1)
        x = 1 : length(outbuf);
        plot(x,outbuf)
        title(sprintf('Outbuffer %d', i))
        
        y = eval(sprintf('inbuf.chan%d',i));
        x = 1 : length(y);
        
        subplot(2,1,2)
        plot(x,y,'k')
        title(sprintf('Input %d',i));
        xlim([0 2600])
    end
end


%%
save(['C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\Calibration\Calib_Chan',num2str(speakerNo),'_Rep1.mat','calib'])