
calibDir = 'C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\Calibration171219';
chans = 13:20;
for currChan = chans
            figure

    for rep = 1:3
        load(fullfile(calibDir,['Calib_Chan',num2str(currChan),'_Rep',num2str(rep),'.mat']))
        spkrFlt(rep,:) = BuildInverseFilter(calib,1,24414);
            plotSpect(fft(spkrFlt(rep,:)), calib.ADrate)

    end
    avSpkrFlt(currChan==chans,:) = mean(spkrFlt);
    
    plotSpect(fft(avSpkrFlt(currChan==chans,:)), calib.ADrate,'r')
    kaja = [];
end

% speaker 1 = Chan 13
% Speaker 2 = chan 16
% Speaker 3 = Chan 15
% Speaker 4 = Chan 14
% Speaker 5 = Chan 17
% Speaker 6 = Chan 20
% Speaker 7 = Chan 19
% Speaker 8 = Chan 18


chanOrder = [1 4 3 2 5 8 7 6]; % channel order
    
avSpkrFlt(:,end+1)= chanOrder';
avSpkrFlt = sortrows(avSpkrFlt,294);
avSpkrFlt = avSpkrFlt(:,1:end-1);
fs = calib.ADrate;
% saveDir = 'C:\Users\Ferret 2\Documents\MATLAB\Applications\GoFerret\KP_Calibrate_WE\CalibrationFilters';
% save(fullfile(saveDir,'CalibrationFilter_190220.mat'),'avSpkrFlt','fs')
