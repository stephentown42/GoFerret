function convertHAstimuliUniSensoryModified290515

rootDir = 'C:\Users\ferret\Documents\MATLAB\Applications\GoFerret\HA_Congruency';

load( fullfile(rootDir,'stimuliAwakeFerret_04_15.mat'))

NoData = {stimuli.StreamNB{1}*0};
% Preassign stimulus array
stim  = cell(12,2); 

% % Auditory stimuli
stim(1,1) = stimuli.StreamNB(1); %Au mod
stim(2,1) = NoData; % Vu mod
stim(3,1) = stimuli.StreamNBNoAmplitude(1); % Au (no modulation)
stim(4,1) = stimuli.StreamNB(2); % Aa mod
stim(5,1) = NoData; % Va mod
stim(6,1) = stimuli.StreamNBNoAmplitude (2);% Aa
stim(7,1) = {stimuli.TwoStreamNB}; % Au+Aa
stim(8,1) = NoData; %V no mod
stim(9,1) =  stimuli.StreamNBNoAmplitude(1);  % Au + V
stim(10,1) = stimuli.StreamNB(1); % Aumod +V 
stim(11,1) = stimuli.StreamNBNoAmplitude(1); % Au + Vumod
stim(12,1) = {stimuli.TwoStreamNB}; % Au+Aa +V
stim(13,1) = stimuli.StreamNB(1); %Au mod +Vu mod
stim(14,1) = stimuli.StreamNB(2); %Aa mod +Vu mod

% % For visual stimulus  
 stim(1,2) = NoData; %u
stim(2,2) = stimuli.envVisual(1); % Vu mod 
stim(3,2) = NoData; % u ref only
stim(4,2) = NoData; % a
stim(5,2) =stimuli.envVisual(2); % V
 stim(6,2) = NoData;% a ref only
stim(7,2) = NoData; % u+a
stim(8,2) = {ones(size(stimuli.envVisual{1},1),1)*0.5};  %V :vis no amp modulation
stim(9,2) = {ones(size(stimuli.envVisual{1},1),1)*0.5};   % Au + V
stim(10,2) = {ones(size(stimuli.envVisual{1},1),1)*0.5}; % Aumod +V 
stim(11,2) = stimuli.envVisual(1);  % Au + Vumod
stim(12,2) = {ones(size(stimuli.envVisual{1},1),1)*0.5}; % Au+Aa +V
stim(13,2) = stimuli.envVisual(1); %Au mod +Vu mod
stim(14,2) = stimuli.envVisual(2); %Aa mod +Vu mod

% for each stimulius
for i = 1 : numel(stim)
   if ~isempty(stim{i})
    stim{i} = resample(stim{i}, 2, 1);   
   end
end

% Save
saveName = fullfile( rootDir, 'stim.mat');
save( saveName, 'stim')%'headers','table');