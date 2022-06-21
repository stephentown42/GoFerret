function [clean] = removeArtefact(chan)


%% threshold
% s = std(double(chan));          % standard deviation to find threshold
% thresh = mean(chan) + s*2;
% 
% xend = length(chan);          % for plotting thresh on graph
% x = [0 xend];
% y = [thresh thresh];
% y2 = [-thresh, -thresh];

thresh = 5000;

%% replace artefacts with NaNs
findup = find(chan > thresh);  % index of where trace goes above/below threshold
finddown = find(chan < -thresh);

lowerbound_up = findup - 2000;
findzero = lowerbound_up == 0;
findneg = lowerbound_up < 0;

lowerbound_up(findzero) = 1;
lowerbound_up(findneg) = 1;
upperbound_up = findup + 2000;

lowerbound_down = finddown - 2000;
findzero = lowerbound_down == 0;
findneg = lowerbound_down < 0;

lowerbound_down(findzero) = 1;
lowerbound_down(findneg) = 1;
upperbound_down = finddown + 2000;

new = chan;

for i = 1 : length(findup)
    new(lowerbound_up(i):upperbound_up(i)) = NaN;
end

for i = 1: length(finddown)
    new(lowerbound_down(i):upperbound_down(i)) = NaN;
end

new = new(1: length(chan));

%% interpolate in gaps


nanidx = isnan(new);   % index of where trace has been replaced with NaNs
nandiff = diff(nanidx);  % +1 marks leading edge, -1 marks falling

nanOnIdx = nandiff == 1;
nOn = sum(nanOnIdx);
nanOffIdx = nandiff == -1;
nOff = sum(nanOffIdx);

findnanOn = find(nandiff == 1);
findnanOff = find(nandiff == -1);

for i = 1
    if nOn == 0
        clean = chan;
        continue
        
    else
        firstnanOn = findnanOn(1);
        lastnanOn = findnanOn(nOn);
        
        firstnanOff = findnanOff(1);
        lastnanOff = findnanOff(nOff);
        
        
        if nOn == nOff
            if firstnanOn < firstnanOff
                
                for j = 1 : nOn
                    
                    nanOn = findnanOn(j) ;
                    nanOff = findnanOff(j);
                    lengthnan = nanOff - nanOn;
                    
                    valOn = new(nanOn);
                    valOff = new(nanOff+2);
                    
                    fill{j,:} = linspace (valOn, valOff, (lengthnan));
                    
                end
                
            elseif firstnanOn > firstnanOff
                
                nanOn = 1;
                nanOff = findnanOff(1);
                lengthnan = nanOff - nanOn;
                
                
                valOff = new(nanOff+2);
                valOn = valOff;         % flat line to start- trying to add in as few new freq components as poss
                
                fill{1,:} = linspace (valOn, valOff, (lengthnan + 1));
                
                for j = 1 : nOn - 1
                    
                    nanOn = findnanOn(j) ;
                    nanOff = findnanOff(j+1);
                    lengthnan = nanOff - nanOn;
                    
                    valOn = new(nanOn);
                    valOff = new(nanOff+2);
                    
                    fill{j+1,:} = linspace (valOn, valOff, (lengthnan));
                    
                end
                
                nanOn = findnanOn(nOn);
                nanOff = length(chan);
                lengthnan = nanOff - nanOn;
                
                valOn = new(nanOn);
                valOff = valOn;
                
                fill{nOn + 1,:} = linspace (valOn, valOff, (lengthnan));
                
            end
            
        elseif nOn > nOff
            
            for j = 1 : nOn - 1
                
                nanOn = findnanOn(j) ;
                nanOff = findnanOff(j);
                lengthnan = nanOff - nanOn;
                
                valOn = new(nanOn);
                valOff = new(nanOff+2);
                
                fill{j,:} = linspace (valOn, valOff, (lengthnan));
                
            end
            
            nanOn = findnanOn(nOn);
            nanOff = length(chan);
            lengthnan = nanOff - nanOn;
            
            valOn = new(nanOn);
            valOff = valOn;
            
            fill{nOn,:} = linspace (valOn, valOff, (lengthnan));
            
        elseif nOn < nOff
            
            nanOn = 1;
            nanOff = findnanOff(1);
            lengthnan = nanOff - nanOn;
            
            
            valOff = new(nanOff+2);
            valOn = valOff;         % flat line to start- trying to add in as few new freq components as poss
            
            fill{1,:} = linspace (valOn, valOff, (lengthnan + 1));
            
            for j = 1 : nOn
                
                nanOn = findnanOn(j) ;
                nanOff = findnanOff(j+1);
                lengthnan = nanOff - nanOn;
                
                valOn = new(nanOn);
                valOff = new(nanOff+2);
                
                fill{j+1,:} = linspace (valOn, valOff, (lengthnan));
                
            end
            
        end
    end
    
    
    
    numGaps = length(fill);
    
    
    Fill = zeros(length(chan),1);  % empty vector to 'hold' fill lines
    allgaps = [];
    
    for k = 1 : numGaps
        allgaps = [allgaps  fill{k}];
    end
    
    Fill(nanidx) = allgaps;
    
    new(nanidx) = 0;
    
    clean = new + Fill;
    
% %     plot(chan)
% %     hold on
% %     plot(x,y)
% %     plot(x, y2)
% %     
% %     plot(new)
% %     
    
end

end


%%%%%%%%%%%%
% %
% % if firstnanOn > firstnanOff
% %
% %     nanOn = 1;
% %     nanOff = findnanOff(1);
% %     lengthnan = nanOff - nanOn;
% %
% %
% %     valOff = new(nanOff+2);
% %     valOn = valOff;         % flat line to start- trying to add in as few new freq components as poss
% %
% %     fill{1,:} = linspace (valOn, valOff, (lengthnan + 1));
% %
% %     for j = 1 : nOn - 2
% %
% %         nanOn = findnanOn(j) ;
% %         nanOff = findnanOff(j+1);
% %         lengthnan = nanOff - nanOn;
% %
% %         valOn = new(nanOn);
% %         valOff = new(nanOff+2);
% %
% %         fill{j+1,:} = linspace (valOn, valOff, (lengthnan));
% %
% %     end
% %
% % elseif firstnanOn < firstnanOff
% %
% %     for j = 1 : nOn - 2
% %
% %         nanOn = findnanOn(j) ;
% %         nanOff = findnanOff(j+1);
% %         lengthnan = nanOff - nanOn;
% %
% %         valOn = new(nanOn);
% %         valOff = new(nanOff+2);
% %
% %         fill{j+1,:} = linspace (valOn, valOff, (lengthnan));
% %
% %      end
% % end
% %
% %
% %     if lastnanOn > lastnanOff
% %
% %
% %         nanOn = findnanOn(nOn);
% %         nanOff = length(chan);
% %         lengthnan = nanOff - nanOn;
% %
% %         valOn = new(nanOn);
% %         valOff = valOn;
% %
% %         fill{nOn + 1,:} = linspace (valOn, valOff, (lengthnan));
% %     else
% %         nanOn = findnanOn(nOn) ;
% %         nanOff = findnanOff(nOn + 1);
% %         lengthnan = nanOff - nanOn;
% %
% %         valOn = new(nanOn);
% %         valOff = new(nanOff+2);
% %
% %         fill{nOn + 1,:} = linspace (valOn, valOff, (lengthnan));
% %     end
% %

