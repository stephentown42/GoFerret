function OB_PhotoCalibration_Jumbo(varargin)

% All measurements in mm or pixels
% X indicates Left / Right
% Y indicates Forwards / Backwards

% Start with figure
f = figure;

% Get pixels locations
[octPix, im, imPath] = getPixelLocations(subplot(2,2,1), f);

% Simulate arena
[octCM, spk] = simulateArena(subplot(2,2,2));

% Get pixel-to-mm ratio
PixPerMM = getPixPerMM(octPix, octCM);

% Get transformation
[R, d] = getTransformation( octPix, octCM, PixPerMM);

% Get speaker positions in image
speakerXY = getSpeakerPositionsInImage(spk, R, d, PixPerMM);

% Plot arena data onto image
reconstructArenaAndImage( im, octPix, octCM, speakerXY, PixPerMM, R, d)

% Save output
save( strrep(imPath, '.jpg','.mat'), 'R','d','PixPerMM','speakerXY')
saveas( f, strrep(imPath, '.jpg','.fig'))
close(f)



function [octPix, im, imPath] = getPixelLocations(ax, wf)
%
% Requests calibration image from user
%
% open image
calibDir = fullfile('C:\Users', getenv('USERNAME'),...
                    'CloudStation\Owen\Calibration Images\Jumbo');
[imName, imPath, ~] = uigetfile('*.jpg','Select calibration image', calibDir);

fprintf('Loading %s\n', imName)
set(wf,'name',imName)

imPath = fullfile( imPath, imName);
im = imread(imPath);
im = rgb2gray(im);

% Adapt contrast
im = adapthisteq(im);

% Show image
f = figure('color','w',...
            'Name','Please choose vertices in clockwise order relative to door',...
            'NumberTitle','off',...
            'MenuBar','None');           
imshow(im)
axis on
set(gcf,'position',get(0, 'ScreenSize'))


% Identify vertices
% Start at near 2 o'clock and go clockwise
[xv, yv] = ginput(7); 
hold on
close(f)

% Get Origin
origin = nan(3,2);

for i = 1 : 3    
    origin(i,1) = mean( [xv(i) xv(i+4)]);
    origin(i,2) = mean( [yv(i) yv(i+4)]);
end

origin = mean(origin);

% Move plot to overall figure
figure(wf)
axes(ax)
hold on
imshow(im)
plotByColormap(xv, yv)
plot(origin(1),origin(2),'ow','MarkerFaceColor','w')
axis tight
axis on

% Send output as structure
octPix = struct('xv',xv,'yv',yv,'origin',origin);

function [octagon, spk] = simulateArena(axH)

% Define marker position
octagon.rho   = 45.34;
octagon.theta = -pi : pi/4 : pi - pi/8;
octagon.rho   = repmat(octagon.rho, size(octagon.theta));
[octagon.xv, octagon.yv] = pol2cart(octagon.theta, octagon.rho);
     
% Calculate positions in arena of speakers
spk.rho   = 50.34;
spk.theta = -pi : pi/6 : pi - pi/6;
spk.rho   = repmat( spk.rho, size(spk.theta));
[spk.xv, spk.yv] = pol2cart(spk.theta, spk.rho);

% Define arena floor
arena.theta = -pi : pi /100 : pi;
arena.rho   = repmat(octagon.rho(1), size(arena.theta));
[arena.x, arena.y] = pol2cart(arena.theta, arena.rho);

% Define axes
ax.theta = [0 pi/2];
ax.rho = arena.rho(1:2);
[ax.xv, ax.yv] = pol2cart(ax.theta, ax.rho);

% Plot 
if nargin == 0
    figH = figure; 
    axH = axes;
else
    axes(axH)
end

hold on

patch(arena.x, arena.y, arena.x.*0,'FaceColor',[0.5 0.5 0.5],'EdgeColor','none')
plotByColormap(octagon.xv, octagon.yv)
plotByColormap(spk.xv, spk.yv)
plot([0 ax.xv(1)],[0 ax.yv(1)],'b','linewidth',2);
plot([0 ax.xv(2)],[0 ax.yv(2)],'r','linewidth',2);

ylabel('Y (cm)')
xlabel('X (cm)')

function plotByColormap(x,y)

n = numel(x);
cmap_original = colormap; % Save current colormap
cmap = colormap('jet'); % Get data
colormap(cmap_original) % Return to previous
m = size(cmap,1);

for i = 1 : n
    
    cIdx = ceil(i / n * m);    
    plot(x(i),y(i),'o','MarkerFaceColor',cmap(cIdx,:),'MarkerEdgeColor','w')        
end


function [R, d] = getTransformation( octPix, octCM, PixPerMM)

% Format measured data for calculation (to deal with full circle)
Measured = [6 5 4 3 2 1 7];             
Measured = [octPix.xv(Measured)';
            octPix.yv(Measured)';
            zeros(1,7)];
        
octPix.origin = [octPix.origin'; 0];
Measured = [Measured octPix.origin];    % Produce an 3 x n matrix with n measured (or calculated) positions    
Measured = Measured ./ PixPerMM;    % Convert pixels to millimeters


% Estimate rotation and translation from reference to measured
index = octCM.theta == pi/2;
octCM.xv(index) = [];
octCM.yv(index) = [];

Ref = [ octCM.xv 0;
        octCM.yv 0;
        zeros(1,8)];     

% Run calculation                
[R, ~] = svd_test(Ref, Measured);

% Overrule d
d = octPix.origin ./ PixPerMM;



function PixPerMM = getPixPerMM(octPix, octCM)

% Estimate diameter from image
idx = [ 1 5; 2 6; 3 7];
diameter = zeros(3,1);

for i = 1 : 3
   
    x(1) = octPix.xv(idx(i,1));
    x(2) = octPix.xv(idx(i,2));    
    y(1) = octPix.yv(idx(i,1));
    y(2) = octPix.yv(idx(i,2));
    
    diameter(i) = abs(hypot(diff(x), diff(y)));
end

diameter = mean(diameter);

% Compare to actual radius of box
actualDiameter = (20*octCM.rho(1));   % x 10 becuase octCM is in cm and we need mm
PixPerMM(1) = diameter / actualDiameter;

% Estimate value from length of side
a = zeros(6,1);

for i = 1 : 6   
    x = octPix.xv(i:i+1);
    y = octPix.yv(i:i+1);   
    a(i) = abs(hypot(diff(x), diff(y)));
end

a = mean(a);
actual_a = hypot( diff(octCM.xv(1:2)), diff(octCM.yv(1:2)));
actual_a = abs(actual_a) * 10;  % cm to mm conversion
PixPerMM(2) = a / actual_a;

% Average across approaches
fprintf('\tEstimated PixPerMM: %.4f (by diameter) and %.4f (by side)\n', PixPerMM)
PixPerMM = mean(PixPerMM);




function spkIM = getSpeakerPositionsInImage(spk, R, d, PixPerMM)

Reality2IM = @(x,y,d,R,PixPerMM) (d + R * [x; y; 0]) .*  PixPerMM;

n = numel(spk.xv);
spkIM = zeros(3,n);

for i = 1 : n
   spkIM(:,i) = Reality2IM( spk.xv(i)*10, spk.yv(i)*10, d, R, PixPerMM); 
end



function reconstructArenaAndImage(im, octPix, octCM, speakerXY, PixPerMM, R, d)

% Define transfer functions
Reality2IM = @(x,y,d,R,PixPerMM) (d + R * [x; y; 0]) .*  PixPerMM;
IM2Reality = @(x,y,d,R,PixPerMM)  R' * (([x; y; 0] ./ PixPerMM) - d);       %#ok<*NASGU>

% Plot calibration image
subplot(2,2,3)
imshow(im)
set(gca,'xdir','normal','ydir','normal')
hold on

% Origin
origin = Reality2IM( 0, 0, d, R, PixPerMM);
plot(origin(1),origin(2),'ow','MarkerFaceColor','w')

% Arena Axes
y_norm = Reality2IM( 0, 453.4, d, R, PixPerMM);
x_norm = Reality2IM( 453.4, 0, d, R, PixPerMM);

plot([origin(1) x_norm(1)],[origin(2) x_norm(2)],'b','LineWidth',1)
plot([origin(1) y_norm(1)],[origin(2) y_norm(2)],'r','LineWidth',1)    

% Octagon
n = numel(octCM.xv);
octProjIM = zeros(3,n);

for i = 1 : n  
    octProjIM(:,i) = Reality2IM( octCM.xv(i)*10, octCM.yv(i)*10, d, R, PixPerMM);
end

plotByColormap(octProjIM(1,:), octProjIM(2,:))
plotByColormap(speakerXY(1,:), speakerXY(2,:))


% Plot observed points in the arena
subplot(2,2,4)
hold on

n = numel(octPix.xv);
octProjR = zeros(3,n);

for i = 1 : n  
    octProjR(:,i) = IM2Reality( octPix.xv(i), octPix.yv(i), d, R, PixPerMM);
end

plotByColormap(octProjR(1,:), octProjR(2,:))
xlabel('X (mm)')
ylabel('Y (mm)')



