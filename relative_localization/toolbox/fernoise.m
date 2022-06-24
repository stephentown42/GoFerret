%function fernoise(nlength,attenuation)  %uncomment if want to run as function

%makes noise for ferret behaviour 
%in expts using a database of 100 set noises, don't run this as a function
%run to make a database with 100 rows 5 seconds long at 48000 sample rate

%% sample rate
global box
box.fs=25000;

%% variables (comment out for function)
nlength=5; %comment out if want to run as function (length of noise in seconds)
noiseDB=zeros(100,nlength*box.fs); %comment out if want to run as function to make a single noise
attenutation=0; %comment out if want to run as function

%% make 100 noises for database
for i=1:100 %comment out if want to run as function to make a single noise
% bin size parameter
LBin=round(0.015*box.fs);

%random noise (UNIFORM)
noise=rand(1,nlength*box.fs); %make a noise x s long
noise=(noise.*10^(-(attenuation/20))); %attenuate noise in dB
%now you want to vary the amps in 15 ms bins:
noiseamp=randn(1,(nlength*box.fs)/LBin); % generate the amplitude values as
%noiseamp=abs(noiseamp);    % a series of GAUSSIAN random numbers

%now run through the noise and vary the amplitudes in dB:
for cc=1:18
    noise(1,1:LBin)=(noise(1,1:LBin).*10^(-(noiseamp(1,1)/20))); % does 1st LBin
    for ii=2:length(noiseamp) % does all LBins in sound
        start = (ii-1)*LBin+1;
        stop  = ii * LBin;
        noise(1,start:stop)=(noise(1,start:stop).*10^(-(noiseamp(1,ii)/20)));
    end
    
    noiseDB(i,:)=noise; %comment out if want to run as function to make a single noise
end %comment out if want to run as function to make a single noise

%sound(noise,box.fs)
%plot(noise)
 end

% plot(noise)
% sound(noise)
