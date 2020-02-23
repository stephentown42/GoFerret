% building a filter to flatten out the panasonic headphones.

calib = o4golayrec(8,0,4,0.1);

% from calib.chan1 we now extract amplitudes for frequencies up to 15 kHz
% and invert them to make a compensation filter.

maxBin  = round(length(calib.chan1)*15000/calib.ADrate);
a       = abs(calib.chan1(1:maxBin));
a       = a./a(end);
a(1)    = 9999;
a       = 1./a;
a(1)    = 0;

plot(a)

% a now contains the amplitudes for the inverse filter for frequencies
% below 15 kHz.

% to use the fir2 command we still need n and f.
% n should be at least 20 ms worth of signal to be able to affect
% frequencies down to ca 500 Hz.

% The vowels in VAS are sampled at half the sample rate that o4golayrec
% defaults to (ca 48kHz)

fs      = calib.ADrate/2;
%fs     = calib.ADrate;
n       = floor(fs*0.006);
nyquist = fs/2;
maxfreq = 15000/nyquist;
L       = size(a,2);
f       = (0:(L-1))/(L-1)*maxfreq;
flt     = fir2(n,[f,1],[a, 1]);


cd c:/jan/wphysio6/modules/DDEvowels/
save VowFltspBox flt


%plotspect(fft(flt),fs)