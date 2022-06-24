function convertHAstimuli

rootDir = 'C:\Users\ferret\Documents\MATLAB\Applications\GoFerret\HA_Congruency';

load( fullfile(rootDir,'stimuliAwakeFerret_test2.mat'))


% Preassign stimulus array
stim  = cell(12,2); 
headers = {'envVisual','WithBlibs','vowel'};
table = zeros(12,1);

% % For visual stimulus  
stim(1:6,2)  = stimuli.envVisual(1);
stim(7:12,2) = stimuli.envVisual(2);
    
table(1:6,1)  = 1;
table(7:12,1) = 2;  

% Auditory stimuli- updated on 29/05/2014
stim(1,1) = stimuli.StreamWB(1); %u
stim(2,1) = stimuli.StreamNB(1); % u
stim(3,1) = stimuli.StreamWB(2); % a
stim(4,1) = stimuli.StreamNB(2); % a
stim(5,1) = {stimuli.TwoStreamWB}; % u+a
stim(6,1) = {stimuli.TwoStreamNB}; % u+a

stim(7:12,1) = stim(1:6,1);

% Are there blibs?
table(1:6,2)  = [1 0 1 0 1 0];
table(7:12,2) = [1 0 1 0 1 0];

% Vowel condition
table(1:6,3) = [1 1 2 2 3 3];
table(7:12,3) = [1 1 2 2 3 3];

% for each stimulius
for i = 1 : numel(stim)
   
    stim{i} = resample(stim{i}, 2, 1);    
end

% Save
saveName = fullfile( rootDir, 'stim.mat');
save( saveName, 'stim','headers','table');