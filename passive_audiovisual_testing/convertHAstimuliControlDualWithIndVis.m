function convertHAstimuliControlDualWithIndVis

rootDir = 'C:\Users\ferret2\Documents\MATLAB\Applications\GoFerret\HA_Congruency';

load( fullfile(rootDir,'stimuliAwakeFerret_02_16.mat'))


% Preassign stimulus array
stim  = cell(7,2); 
headers = {'envVisual','vowel'};
table = zeros(7,1);

NoData = {stimuli.StreamNB{1}*0};
% % For visual stimulus  
stim(1,2)  = NoData;% No visual
stim(2,2)  = stimuli.envVisual(1);
stim(3,2)  = NoData;% No visual
stim(4,2)  = stimuli.envVisual(2);
stim(5,2)  = NoData;% No visual
stim(6,2)  = stimuli.envVisual(1);
stim(7,2)  = stimuli.envVisual(2);
stim(8,2)  = stimuli.envVisual(2);
stim(9,2)  = stimuli.envVisual(1);
stim(9,2)  = stimuli.envVisual(1);
stim(10,2)  = {stimuli.IndEnv};
    
table(1,1)  = 0;
table(2,1)  = 1;
table(3,1)  = 0;
table(4,1)  = 2;
table(5,1)  = 0;
table(6,1)  = 1;
table(7,1)  = 2;
table(8,1)  = 0;
table(9,1)  = 1;

% Auditory stimuli- updated on 29/05/2014
stim(1,1) = stimuli.StreamNB(1); %A1
stim(2,1) = stimuli.StreamNB(1); % A1V1
stim(3,1) = stimuli.StreamNB(2); % A2
stim(4,1) = stimuli.StreamNB(2); % A2V2
stim(5,1) = {stimuli.TwoStreamNB}; % u+a V0
stim(6,1) = {stimuli.TwoStreamNB}; % u+a V1
stim(7,1) = {stimuli.TwoStreamNB}; % u+a V2
stim(8,1) = stimuli.StreamNB(1); % A1V2
stim(9,1) = stimuli.StreamNB(2); % A2V1
stim(10,1) = {stimuli.TwoStreamNB}; % u+a VInd

% Vowel condition
table(1:9,2) = [1 1 2 2 3 3 3 1 2];


% for each stimulius
for i = 1 : numel(stim)
   if ~isempty(stim{i})
    stim{i} = resample(stim{i}, 2, 1);   
   end
end


% Save
saveName = fullfile( rootDir, 'stim.mat');
save( saveName, 'stim','headers','table');