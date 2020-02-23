function makeNormFile(spect, ADrate, fileName, steps, maxFreq)
% function makeNormFile(spect,ADrate,fileName,steps, maxFreq);
% fileName
f     = fopen(fileName,'w');
faxis = 0 : (ADrate/2)/(length(spect)/2-1) : ADrate/2;

if ~exist('maxFreq','var')
   maxFreq = faxis(length(faxis));
end;

i = steps;

while ((i <= length(faxis)) && (faxis(i) <= maxFreq)),
    
   fprintf(f,'%f, %f, %f\r\n',faxis(i), 20*log10(abs(spect(i))), angle(spect(i))*180/pi); % Freq, Attn, Phase
   
   i = i + steps;
end

fclose(f);