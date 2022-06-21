function crossfadeRamp(aLoc, bLoc)

thetaA=abs((aLoc-bLoc)/2); % distance in degree between the two speakers
thetaA=(pi/180)*thetaA; % convert to radians



if aLoc<bLoc % the direction of the sound movement is left to right
    rhThetaI=linspace(0,15,30*4);rhThetaI=rhThetaI(2:end);
    lhThetaI=linspace(-15,0,30*4);
    
   thetaI=0 
SR=(SL*(sin(thetaA)-sin(thetaI)))/(sin(thetaI)+sin(thetaA));

% when thetaI=0, SR==SL,
SR=(SL*(sin(thetaA)-sin(thetaI)))/(sin(thetaI)+sin(thetaA));
% when thetaI=15, SR=0 and SL=1,
% when thetaI=-15, SR=1 and SL=0