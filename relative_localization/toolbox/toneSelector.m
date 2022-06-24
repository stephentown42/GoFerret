function [tone]=toneSelector

%  Will run through series of attenuations and tones based onwhat has been
%  done before - will save the data to an FRA folder/ file.  The file will
%  contain, date and session time - i.e. file name of the behaviour
%  including block number , presentation time, tone freq, attenuation,
%  length of tone (100 ms pips as default)

global gf
bs=strfind(gf.saveDir,'F1');
saveName=gf.saveDir(bs:end);
toneFile=[gf.saveDir '\' saveName '_FRA'];

try
    data=load(toneFile);
catch
end

% tone frequencies from min to max freq with 1/3 octave steps

freqs=gf.toneMinFreq*2.^(0:gf.toneOctInt:log(gf.toneMaxFreq/gf.toneMinFreq)/log(2));
attens=gf.toneMinAtt:gf.toneAttInt:gf.toneMaxAtt;

if exist(data,'var') % If there is a file with data in already
    
    unique(data(:,4:5),'rows')
    
    
    
    
    
    
    
    
    
    
    
else
    currentDat={'gf.TrialNumber','%d';
        'gf.dataName','%s';
        'gf.toneTime','%.3f';
        'gf.toneFreq','%.5f';
        'gf.toneAtt','%d';
        'gf.toneDur','%d';
        'occurence','%d'};
    
    gf.fidTone = fopen(toneFile,'a');
    fprintf(gf.fidTone,'\n');
    for i = 1 : length(currentDat),
        
        variable = eval(currentDat{i,1});
        format   = currentDat{i,2};
        
        fprintf(gf.fidTone, format, variable);          % Print value
        fprintf(gf.fidTone,'\t');                       % Print delimiter (tab so that excel can open it easily)
    end
    
    fprintf(gf.fidTone,'\n');
    fclose(gf.fidTone);
    save(toneFile,'currentDat', '-append');