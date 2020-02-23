cd('C:\Calibrations\21 May 2012')
load('OldBlue')

steps   = 3;
 maxFreq = 30000;
 
 Abslevel   = 95; %86;
 OutputL    = calib.chan1;
 absOutputL = OutputL.*10.^(Abslevel/20);
 
 makeFRAfilter( 10^(96/20)./absOutputL, calib.ADrate, steps, maxFreq) 