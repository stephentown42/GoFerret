function irfOut = o4golayrecComp(golaylen, trim, gap, firFlt, delaySamps)
%function irf = o4golayrec(golaylen, trim, gap, firFlt, delaySamps, PTfreq);
%
%
%  e.g. calibL = o4golayrec(8, 0, 4, 0.1)
%
%  records fourier spectra of impulse response functions to "irf"
%  from golay codes of length golaylen
%
%  presented once through tdt system 3.
%
%  trim (in ms) specifies how much of the recorded signal delay to trim off
%
%  gap (in ms) specifies how much of a time delay to leave between
%  presentations of each code in the pair
%
%  the optional firFlt is a final impulse response filter which will be
%  used to pre-filter the golay codes (if specified)

% additional loop makes an inverse filter and applies it to the golay
% codes. Output is pretty shitty though (presumably because filtering such
% a short signal is problematic).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get golay codes

    
    [ga,gb]  = golay(golaylen);
    ga       = [ga zeros(1,3*length(ga))];
    gb       = [gb zeros(1,3*length(gb))];
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Connect to System 3
    
    global DA;
    
    if ~iscom(DA),
        DAfig = figure('position',[0 0 100 100]);
        DA    = actxcontrol('TDevAcc.X');
        
        DA.ConnectServer('Local');
    end
    
    
    % Get sample rate
    irf.ADrate = DA.GetDeviceSF('RZ6');
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Delay arguments
    
    
    pre_time  = 0.01;
    pre_samps = ceil(pre_time * irf.ADrate);
    
    
    % trim (in ms) specifies how much of the recorded signal delay to trim off
    trimtaps = 0;
    if exist('trim')
        trimtaps = ceil((trim/1000)*irf.ADrate);               % convert milliseconds into samples
    end
    
    % gap (in ms) specifies how much of a time delay to leave between
    % presentations of each code in the pair
    delaytaps = 0;
    if exist('gap')
        delaytaps = ceil((gap/1000)*irf.ADrate);               % convert milliseconds into samples
    end;
    for repeats=1:2
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
    if record == 1,
        
        % Carve individual segments out of recorded buffer
        
        outbuf = [zeros(1,pre_samps) outbuf];
        delaySamps = delaySamps + pre_samps;
        
        if repeats==2
            %now build inverse filter
            irfOut=calib;
            flt=BuildInverseFilter(calib,30000);
            outSig=conv(outbuf,flt,'same');
        end
        
        inbuf   = tdtSys3play(outbuf*(10/scaleFact))';
        
        % analyse channel1
        astart  = delaySamps + trimtaps;
        bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
        
        sumA    = inbuf.chan1( astart + 1 : astart + length(ga));   %response to ga
        sumB    = inbuf.chan1( bstart + 1 : bstart + length(gb));   %response to gb
        
        % Generate time axis
        %timestep = 1 / irf.ADrate;
        %tAxis    = timestep : timestep : timestep*length(outbuf);
        %t_last   = tAxis(length(outbuf));
        
        % Plot inbuf.chan1
        figure('name',clockString('time'))
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
        plotSpect(irf.chan1, irf.ADrate);
        
        
        % analyse channel2
        astart  = delaySamps + trimtaps;
        bstart  = delaySamps + 2*trimtaps + length(ga) + delaytaps;
        
        sumA    = inbuf.chan2( astart + 1 : astart + length(ga));   %response to ga
        sumB    = inbuf.chan2( bstart + 1 : bstart + length(gb));   %response to gb
        
        % Plot inbuf.chan1
        subplot(2,2,3);
        plot(x, inbuf.chan2);
        
        xlim([0 2600])                      %set(gca,'xlim',[0,t_last]);
        title('chan2');
        xlabel('Sample')                    %xlabel('time (s)');
        ylabel('Volt');
        
        % Check lengths and produce spectrogram info
        irf.chan2 = golanal(sumA(:)',sumB(:)',ga(:)',gb(:)');
        
        subplot(2,2,4);
        plotSpect(irf.chan2, irf.ADrate);
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
    calib=irf;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write data to file
% steps   = 3;
% maxFreq = 30000;
%
% Abslevel   = 115; % Absolute level of 5 k tone
% OutputL    = irf.chan1;
% absOutputL = OutputL.*10.^(Abslevel/20);
%
% makeFRAfilter( 10^(96/20)./absOutputL, irf.ADrate, steps, maxFreq)
