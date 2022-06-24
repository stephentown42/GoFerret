function matched = rename_wireless(ferret)

%try

if strcmp(ferret, 'K')
    F = '1504_Kiwi';
    behPath = 'E:\Data\Behavior\F1504_Kiwi';
    fPath   = 'F:\Wireless\MATLAB_matched\F1504_Kiwi';
    
elseif strcmp(ferret, 'E')
     F = '1507_Emu';
    behPath = 'E:\Data\Behavior\F1507_Emu';
    fPath   = 'F:\Wireless\MATLAB_matched\F1507_Emu';
    
elseif strcmp(ferret, 'B')
     F = '1510_Beaker';
    behPath = 'E:\Data\Behavior\F1510_Beaker';
    fPath   = 'F:\Wireless\MATLAB_matched\F1510_Beaker';
    
elseif strcmp(ferret, 'A')
     F = '1511_Animal';
    behPath = 'E:\Data\Behavior\F1511_Animal';
    fPath   = 'F:\Wireless\MATLAB_matched\F1511_Animal';

end

wlPath  = 'E:\Multi Channel DataManager';

saveDir    = dir(fPath);
savedFiles = {saveDir(:).name};

txtDir = dir(fullfile(behPath,'*Block*.txt'));
wlDir  = dir(fullfile(wlPath,'*.h5'));

blocklist = makeBlockList(txtDir);      % Get list of blocks and datenums
WLlist = makeWLlist(wlDir, wlPath);     % Get list of wireless recordings, and datenums of start and end

matched = matchdates(blocklist, WLlist, wlPath, fPath, savedFiles);    % Match blocks with datnums within ranges of wireless recordings

savefile = [F '_WirelessTDTmatch_' date '.mat'];
save(fullfile(fPath, savefile), 'matched', 'blocklist', 'WLlist')
% 
% catch err
%     err
%     keyboard
% end

end



function blocklist = makeBlockList(txtDir)

blocklist = cell(size(txtDir,1),2);   % preassign cell array

for i = 1 : size(txtDir,1)
    
    behFile = txtDir(i).name;
    
    % Extract date info from text file name
    underscores = strfind(behFile, '_');
    spaces = strfind(behFile, ' ');
    
    day   = str2double (behFile(1 : underscores(1)-1));
    month = str2double (behFile(underscores(1)+1 : underscores(2)-1));
    year  = str2double (behFile(underscores(2)+1 : spaces(1)-1));
    
    if numel(underscores) == 6
        
        
        hour  = str2double (behFile(spaces(2)+1 : underscores(4)-1));
        min   = str2double (behFile(underscores(4)+1 : underscores(5)-1)) + 1; % Plus one so that just incase there is a sub-minute delay as text file doesn't have seconds
        % Extract block name
        if strfind(behFile, 'HS')
            block = behFile(underscores(5)+1 : spaces(end)-1);
        else
            
            block = behFile(underscores(6)+1 : spaces(end)-1);
        end
        
    elseif numel(underscores) == 7
        hour  = str2double (behFile(spaces(2)+1 : underscores(5)-1));
        min   = str2double (behFile(underscores(5)+1 : underscores(6)-1)) + 1;
        % Extract block name
        block = behFile(underscores(6)+1 : spaces(end)-1);
        
    elseif numel(underscores) == 5
        hour  = str2double (behFile(spaces(2)+1 : underscores(4)-1));
        min   = str2double (behFile(underscores(4)+1 : underscores(5)-1)) + 1;
        % Extract block name
        block = behFile(underscores(5)+1 :spaces(end)-1);
    elseif numel(underscores) == 8
        hour  = str2double (behFile(spaces(2)+1 : underscores(6)-1));
        min   = str2double (behFile(underscores(6)+1 : underscores(7)-1)) + 1;
        % Extract block name
        block = behFile(underscores(7)+1 :spaces(end)-1);
    end
    
    % convert to datenum
    behDatenum = datenum([year,month,day,hour,min,0]);
    
    % make list of block list next to respective datnum
    blocklist(i,:) = {block, behDatenum};
    

end

% Order by date
S = cell2mat(blocklist(:,2));
[~, SIdx] = sort(S);
blocklist = blocklist(SIdx,:);

end


function WLlist = makeWLlist(wlDir, wlPath)

WLlist = cell(size(wlDir,1),4);

for i = 1: size(WLlist,1)
    
    try
    
    wlFile = wlDir(i).name;
    
    % Extrace date info from wireless file name
    dashes = strfind(wlFile, '-');
    
    wldate = wlFile(1:10);
    HH = wlFile(dashes(3)-2 : dashes(3)-1);
    MM = wlFile(dashes(3)+1 : dashes(4)-1);
    SS = wlFile(dashes(4)+1 : dashes(4)+2);
    
    DateString = [wldate ' ' HH ':' MM ':' SS];
    formatIn ='yyyy-mm-dd HH:MM:SS';
    
    wlDatenum = datenum(DateString,formatIn);
       
    % Extract length of wireless recording
    file = fullfile(wlPath , wlFile);

    timestamps = h5read(file, '/Data/Recording_0/AnalogStream/Stream_0/ChannelDataTimeStamps');
    reclength  = timestamps(3)/10^6;
    
    MM_end = num2str(str2double(MM) + reclength);
    
    DateString_end = [wldate ' ' HH ':' MM_end ':' SS];
    formatIn ='yyyy-mm-dd HH:MM:SS';
    
    wlDatenum_end = datenum(DateString_end,formatIn);
    
    
    WLlist(i,:) = {wlFile, wlDatenum, reclength, wlDatenum_end};
    
    catch err
        err
        keyboard
    end
end

S = cell2mat(WLlist(:,2));
[~, SIdx] = sort(S);
WLlist = WLlist(SIdx,:);

end


function matched = matchdates(blocklist, WLlist, wlPath, fPath, savedFiles)

nWL = size(WLlist, 1);
nB  = size(blocklist, 1);

rowmatched = cell(nB , nWL);

for i = 1 : nWL
    
    wrec = cell2mat(WLlist(i,1));
    wl1  = cell2mat(WLlist(i,2));
    wl2  = cell2mat(WLlist(i,4));
    
    for j = 1 : nB
        
        block  = cell2mat(blocklist(j,1));
        blockT = cell2mat(blocklist(j,2));
        
        if blockT > wl1 && blockT < wl2
            
            rowmatched(j,i) = WLlist(i);
            
            originalfile = fullfile(wlPath, wrec);
            newname = [wrec(1:16) '_' block '.h5'];
            
            check = cellfun( @(x) strcmp(x, newname), savedFiles );
            
            if sum(check) == 1
                continue
            else
            end
            
            copiedfile = fullfile(fPath, newname);
            
            copyfile(originalfile, copiedfile)
            
        else
            rowmatched(j,i) = {''};
            
        end
        
    end
end

rowMatch = cell(nB, 1);

for k = 1 : nB
    row = [rowmatched{k,:}];
    rowMatch(k,1) = {row};
end

matched = [blocklist(:,1), rowMatch] ;


end
