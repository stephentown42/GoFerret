
function flt=BuildInverseFilter(calib,chan,maxFreq)
% builds an inverse filter based on the calibs from 
% calib = o4golayrec(8,0,4,0.1,98);
% compensate to maxFreq

spect = eval( sprintf( 'calib.chan%d', chan));

maxBin =round(length(spect)*maxFreq/calib.ADrate);
a      = abs(spect(1:maxBin));
a      = a./a(end);
a      = 1./a;
a(1)   = 0;
%plot(a)

% a now contains the amplitudes for the inverse filter for frequencies
% below 30 kHz.

% to use the fir2 command we still need n and f.
% n should be at least 20 ms worth of signal to be able to affect
% frequencies down to ca 500 Hz.

% The vowels in VAS are sampled at half the sample rate that o4golayrec
% defaults to (ca 48kHz)

%fs=calib.ADrate/2;
fs      = calib.ADrate;
n       = floor(fs*0.006);
nyquist = fs/2;
maxfreq = maxFreq/nyquist;
L       = size(a,2);
f       = (0:(L-1))/(L-1)*maxfreq;
flt     = fir2(n,[f,1],[a, 1]);


% figure
% hold on
% plotSpect(spect, fs,'b')
% plotSpect(fft(flt),fs,'r')
