function [blue, red, mask] = checkTrackingData_WIRELESS(trk)

% Get tracking data
if ~exist('trk','var'),

    [trkFile, trkDir, ~] = uigetfile('C:\Data\Owen\Blocks\*.mat');

    trk = load( fullfile(trkDir, trkFile));
end

% Get calibration image
[jpgFile, dataDir, ~] = uigetfile('C:\Users\Stephen\Dropbox\Owen\Calibration Images\*.jpg');

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

    IN = inpolygon(trk.blue(:,2),trk.blue(:,3),xv,yv);
    trk.blue(IN,:) = NaN;

    IN = inpolygon(trk.red(:,2),trk.red(:,3),xv,yv);
    trk.red(IN,:) = NaN;

    % Plot density map
    [f, im] = addRGDensities(im, trk);
end

% Make mask binary
mask( mask>1) = 1;

% Declare specific variables
blue       = trk.blue;
red         = trk.red;
blueThresh = trk.blueThresh;
redThresh   = trk.redThresh;


if exist('trkFile','var')
    
    % Save details
    saveName = regexprep(trkFile, '.mat','_cut.mat');
    saveName = fullfile( trkDir, saveName);

    % Save
    save( saveName, 'blue','red','redThresh','blueThresh','im')
end

% Close figure
close(f)



function [f, im] = addRGDensities(im, trk)

% Reset image
im(:,:,1) = im(:,:,3) .* 0;
im(:,:,2) = im(:,:,3) .* 0;

% Define edges
xEdges = 0 : 1 : size(im,2);
yEdges = 0 : 1 : size(im,1);

% Run histogram
n = hist3(trk.blue(:,[3 2]),{yEdges,xEdges});
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



