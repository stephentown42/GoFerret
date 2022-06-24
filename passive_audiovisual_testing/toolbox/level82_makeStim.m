function level82_makeStim

fStim = 48828.125;

pitchRange = [149,200,263,330,459];
attnRange  = [0 -4.5 -9 -12.5 -18];
% formants   = [460,1105,2857,4205;
%               730,2058,2857,4205];
formants   = [437	2761	2975	4263;
              936	1551	2975	4263];
           
count = 0;

for i = 1 : size(formants,1)
    
    f1 = formants(i,1);
    f2 = formants(i,2);
    f3 = formants(i,3);    
    f4 = formants(i,4);
    
    for j = 1 : length(pitchRange),
        
        f0 = pitchRange(j);
        
        for k = 1 : length(attnRange)
            
            atten = attnRange(k);            
            
            if ismember(formants(i,:), [936,1551,2975,4263],'rows'), atten = atten - 5; end
            if ismember(formants(i,:), [730 2058 2857 4205],'rows'), atten = atten - 2; end
            
            % Generate vowel
            vowel = newMakeVowel2009(0.25, fStim, f0, f1, f2, f3, f4);
            
            
            % envelope to prevent clicking transients
            vowel = envelope(vowel,250);
            vowel = vowel.*10^(-(atten/20));
            
            
            % Send to cell array
            count       = count + 1;
            stim{count} = [vowel, 0.* vowel, vowel, 0.* vowel];            
        end
    end
end

% Save to file
saveDir  = 'C:\Users\ferret\Documents\MATLAB\Applications\GoFerret\MRC_speech_test';
saveName = 'stim_Vowels_ai.mat';

save( fullfile( saveDir, saveName), 'stim')