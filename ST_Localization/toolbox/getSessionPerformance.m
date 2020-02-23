function getSessionPerformance


% Load data
pathname = 'E:\Data\Behavior\F1506_Phoenix';
[filename, pathname] = uigetfile('*.txt','Select file:',pathname);

D = importdata( fullfile( pathname, filename));

% Remove correction trials
cTidx = strcmp(D.colheaders,'CorrectionTrial?');
D.data( D.data(:,cTidx) == 1, :) = [];

% Split data by modality
modIdx  = strcmp(D.colheaders,'Modality');

[A,V] = deal(D);
A.data = A.data(A.data(:,modIdx) == 1,:);
V.data = V.data(V.data(:,modIdx) == 0,:);

% Get performance
cIdx = strcmp(D.colheaders,'Correct');
A.pCorrect = mean(A.data(:,cIdx));
V.pCorrect = mean(V.data(:,cIdx));

% Get reaction time distributions
stIdx = strcmp(D.colheaders,'StartTime');
rtIdx = strcmp(D.colheaders,'RespTime');

A.responseTime = A.data(:,rtIdx) - A.data(:,stIdx);
V.responseTime = V.data(:,rtIdx) - V.data(:,stIdx);

% Convert response time into number of stimulus repeats
stimulusDuration = 0.25;
stimulusInterval = 0.25;
stimulusRepWidth = stimulusDuration + stimulusInterval;

A.actualStimNReps = A.responseTime ./ stimulusRepWidth;
V.actualStimNReps = V.responseTime ./ stimulusRepWidth;

figure; hold on
hist(V.responseTime)
hist(A.responseTime)



end