function irf = PlayAndRecord(signal)
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %make diotic
% ga       = signal; 
% gb       = signal]; 
% 


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

outbuf = signal;%[ga,...
scaleFact=1;
inbuf   = tdtSys3play(outbuf*(10/scaleFact))';

figure
subplot(2,2,1)
plot(outbuf);
subplot(2,2,2)
jennyFFT(outbuf, irf.ADrate,1);

subplot(2,2,3)
plot(inbuf.chan1);
subplot(2,2,4)
jennyFFT(inbuf.chan1, irf.ADrate,1);

%flt=BuildInverseFilter(calib,maxFreq);
%outSig=conv(outBuf,flt,'same');


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
