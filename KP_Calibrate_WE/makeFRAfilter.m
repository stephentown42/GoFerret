function makeFRAfilter(spect, ADrate, steps, maxFreq)
% function makeNormFile(spect,ADrate,fileName,steps, maxFreq);
% fileName

%folder   = 'C:\Users\ferret\Documents\MATLAB\AnesthetizedFerret\lib\Headphone Filters\';
% fileName = sprintf('Calibration %s.txt', clockString('time'));

% cd('C:\Users\ferret\Desktop')

[filename, pathname] = uiputfile;
filename             = strcat(pathname,filename,'.txt');

f     = fopen(filename,'w');
faxis = 0 : (ADrate/2)/(length(spect)/2-1) : ADrate/2;

if ~exist('maxFreq','var')
   maxFreq = faxis(length(faxis));
end;

%i = steps;
i=1; 
while ((i <= length(faxis)) && (faxis(i) <= maxFreq)),
    
   fprintf(f,'%f, %f, %f\r\n',faxis(i), 20*log10(abs(spect(i))), angle(spect(i))*180/pi); % Freq, Attn, Phase
   i = i + 1;
  % i = i + steps;
end

fclose(f);