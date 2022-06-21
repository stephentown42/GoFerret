function [green, red, mask] = checkTrackingData_autoPhoto(trk, block)
try
% Get tracking data
if ~exist('trk','var'),

    [trkFile, trkDir, ~] = uigetfile('C:\Data\Owen\Blocks\*.mat');

    trk = load( fullfile(trkDir, trkFile));
end

% Get calibration image
% % [jpgFile, dataDir, ~] = uigetfile('C:\Users\Soraya\Dropbox\Soraya\Jumbo_calibration\*.jpg');
% % 
% % im = imread( fullfile( dataDir, jpgFile));
% % im = rgb2gray(im);



imPath = 'C:\Users\Soraya\Dropbox\Soraya\Jumbo_calibration';
    imDir  = dir(fullfile(imPath, '*.jpg'));
    
    imN = length(imDir);
    
    for j = 1: imN
        
        imName = imDir(j).name;
        
        % extract date info
        imY = str2num(imName(1:4));
        imMo = str2num(imName(6:7));
        imD = str2num(imName(9:10));
        imH = str2num(imName(12:13));
        imMn = str2num(imName(15:16));
        imS  = str2num(imName(18:19));
        
        dateVec = [imY, imMo, imD, imH, imMn, imS];
        
        % convert to datenum
        n = datenum(dateVec);
        
        
        dateDir(j).imName = imName;
        dateDir(j).dateVec = dateVec;
        dateDir(j).dateNum = n;
        
        
    end
        
   
        
       [ref] = SelectFromReference('A', 'Atr', 'T');



 
    blockidx    = strfind(ref.Block, block);
    bidx = ~cellfun(@isempty, blockidx);
    txtdate     = ref.Date{bidx}; 
    txtfile = ref.TextFile{bidx};
           
% extract time and date from filename
    
    spidx  = strfind(txtfile, ' ');
    txtend = txtfile(spidx(2)+1 : end);
        
    uscidx = strfind(txtend, '_');
    spidx2 = strfind(txtend, ' ');
    
    h = txtend(1:uscidx(1)-1);
    
    if numel(uscidx) == 1
    m = txtend(uscidx(1)+1:spidx(1)-1);
    else
    m = txtend(uscidx(1)+1:uscidx(2)-1);
    end
    
    datestr = [txtdate ' ' num2str(h) ':' num2str(m) ':00'];
    formatIn = 'dd-mm-yyyy HH:MM:SS';
    txtdn = datenum(datestr, formatIn);
    
    %% find closest matching calib photo
    
    sub = [dateDir.dateNum] - txtdn;
    
    [~, midx] = min(abs(sub));
    
    imMatch = dateDir(midx).imName;

dataDir = imPath;
jpgFile = imMatch;

im = imread( fullfile( dataDir, jpgFile));
im = rgb2gray(im);





im2(:,:,1) = im .* 0;
im2(:,:,2) = im .* 0;
im2(:,:,3) = im .* 1;

im = im2;
mask = im(:,:,1) ==1;


% Plot density map
[f, im] = addRGDensities(im, trk);

% Run loop until image clear
while strcmp('No', questdlg('Happy?','','Yes','No','No'))

    % Select region of interest to exclude
    [mask_temp, xv, yv] = roipoly;
    
    mask = mask + mask_temp;
    
    close(f)

    IN = inpolygon(trk.green(:,2),trk.green(:,3),xv,yv);
    trk.green(IN,:) = NaN;

    IN = inpolygon(trk.red(:,2),trk.red(:,3),xv,yv);
    trk.red(IN,:) = NaN;

    % Plot density map
    [f, im] = addRGDensities(im, trk);
end

% Make mask binary
mask( mask>1) = 1;

% Declare specific variables
green       = trk.green;
red         = trk.red;
greenThresh = trk.greenThresh;
redThresh   = trk.redThresh;


if exist('trkFile','var')
    
    % Save details
    saveName = regexprep(trkFile, '.mat','_cut.mat');
    saveName = fullfile( trkDir, saveName);

    % Save
    save( saveName, 'green','red','redThresh','greenThresh','im')
end

% Close figure
close(f)
catch err
    err
    keyboard
end


function [f, im] = addRGDensities(im, trk)

% Reset image
im(:,:,1) = im(:,:,3) .* 0;
im(:,:,2) = im(:,:,3) .* 0;

% Define edges
xEdges = 0 : 1 : size(im,2);
yEdges = 0 : 1 : size(im,1);

% Run histogram
n = hist3(trk.green(:,[3 2]),{yEdges,xEdges});
n = 1 + n(1:end-1, 1:end-1);    % Crop
n = log(n);                     % Switch to log scale
n = n./ max(n(:));              % Normalize
im(:,:,2) = n .* 255;           % Convert to RGB scale for image

n = hist3(trk.red(:,[3 2]),{yEdges,xEdges});
n = 1 + n(1:end-1, 1:end-1);    % Crop
n = log(n);                     % Switch to log scale
n = n./ max(n(:));              % Normalize
im(:,:,1) = n .* 255;           % Convert to RGB scale for image

% Draw
f = figure; image(im);



