function requiredVoltage = getJumboCalib(requestedLevel, speaker)

% Parameters from calibration on 31 Dec 2015
% (C:\Users\Ferret\Dropbox\Admin, Equipment & Protocols\Jumbo_Calib_31Dec2015.mat')

a = [ 0.104395909802309
      0.091084731517392
      0.107308561755101
      0.109010204818070
      0.098688795705109] .* 1e-3;
    
b = [0.117041145676533
     0.117995261774343
     0.117640829919595
     0.116138934526336
     0.117539141687601];
 
myFun = @(x,a,b) a*exp(b*x);

speakerID = [1 2 10 11 12];

% Filter parameters for requested speaker
idx = speakerID == speaker;

if ~any(idx)    
%    fprintf('Speaker calib not found - applying generic calibration\n')
   b = mean(b);
   a = mean(a);
   idx = 1;
end

a = a(idx);
b = b(idx);

% Apply correction for B&K to dB SPL
requestedLevel = requestedLevel + 5.5;

% Apply speaker specific correction (31 Oct 2019)
C.speaker = [2 5 6 7 9 10 11];
C.correction = [0.5 -1 -3 -2 1.5 2 1.5];

if any(C.speaker == speaker)
    requestedLevel = requestedLevel + C.correction( C.speaker == speaker);
end

% Get requested voltage
requiredVoltage = myFun( requestedLevel, a, b);

% Apply safety limit
if requiredVoltage > 1.05
    error('Voltage = %.3f - are you sure? If so, change the safety limits')
end