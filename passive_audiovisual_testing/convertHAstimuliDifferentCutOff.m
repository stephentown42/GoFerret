function convertHAstimuliDifferentCutOff

rootDir = 'C:\Users\ferret2\Documents\MATLAB\Applications\GoFerret\HA_Congruency';

load( fullfile(rootDir,'stimuliAwakeFerret_DifferentCutOff.mat'))

% Preassign stimulus array
stim  = cell(6,2); 

% % For visual stimulus  
stim(1,2)  = stimuli.envVisual7(1);
stim(2,2)  = stimuli.envVisual12(1);
stim(3,2)  = stimuli.envVisual17(1);
stim(4,2)  = stimuli.envVisual7(2);
stim(5,2)  = stimuli.envVisual12(2);
stim(6,2)  = stimuli.envVisual17(2);

% Auditory stimuli
stim(1,1) = {stimuli.TwoStreamNB7}; 
stim(2,1) = {stimuli.TwoStreamNB12}; 
stim(3,1) = {stimuli.TwoStreamNB17};
stim(4:6,1) = stim(1:3,1);


% Are there blibs? No
% Vowel condition? No dual stream only

% for each stimulius
for i = 1 : numel(stim)
   
    stim{i} = resample(stim{i}, 2, 1);    
end

% Save
saveName = fullfile( rootDir, 'stim.mat');
save( saveName, 'stim');