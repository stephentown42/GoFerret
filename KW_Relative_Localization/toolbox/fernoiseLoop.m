function [row, col] = fernoiseLoop
% This works for speaker 1 only

global gf DA

% Generate noise
row = [];
col = [];

spks=1;
n=length(unique(spks));

switch gf.nDBstatus
    
    case 'initialize'
        
        % Generate noise
        row   = randperm( size(gf.noiseDB,1), n);                % randperm row of hrl.NoiseDB
        col   = randperm( size(gf.noiseDB,2) - gf.nDBsamps, n);            % randperm column of hrl.NoiseDB
        noise = gf.noiseDB(row, col : (col+gf.nDBsamps-1));                  % define the noise
        noise =(noise.*10^(-(gf.noiseAttn/20)));
        %         a = gf.noiseAttn;
        
        % Load buffers
        DA.SetTargetVal(sprintf('%s.noiseBufSize',gf.stimDevice), gf.nDBsamps);                    % Sets buffer size
        for ii=1:n
            buf=strcat('%s.noiseBufInput',num2str(ii));
            DA.WriteTargetVEX(sprintf(buf,gf.stimDevice), 0, 'F32', noise);     % Loads initial noise
        end
        
        % Initialize additional parameters
        gf.nDBstatus = 'update';                % move on from the initial buffer loading
        gf.nDBload   = [0; 0];                  % load status
        
        
    case 'update'
        
        Cindex = DA.GetTargetVal(sprintf('%s.noiseBufIndex',gf.stimDevice));
        
        
        if Cindex < gf.nDBsamps/2 &&...             % If data is being read from the first half of the buffer &...
                gf.nDBload(2) == 0,                      % the second half hasn't already been loaded
            
            % Generate noise
            row   = randperm(size(gf.noiseDB,1),n);                            % randperm row of gf.noiseDB
            col   = randperm(size(gf.noiseDB,2)-(gf.nDBsamps/2),n);           % randperm row of gf.noiseDB
            noise = gf.noiseDB(row, col : (col+(gf.nDBsamps/2)-1));             % randperm column of gf.noiseDB
            noise =(noise.*10^(-(gf.noiseAttn/20)));
            
            % Load second half of buffer
            for ii=1:n
                buf=strcat('%s.noiseBufInput',num2str(ii));
                gf.nDBload(2) = DA.WriteTargetVEX(sprintf(buf,gf.stimDevice),(gf.nDBsamps/2),'F32',noise);
                gf.nDBload(1) = 0;
            end
            
            
        elseif Cindex > gf.nDBsamps/2 &&...,           % If data is being read from the second half of the buffer
                gf.nDBload(1) == 0;                          % & the first half of the buffer hasn't already been loaded
            
            
            % Generate noise
            row   = randperm(size(gf.noiseDB,1),1);                            % randperm row of gf.noiseDB
            col   = randperm(size(gf.noiseDB,2)-(gf.nDBsamps/2),1);           % randperm row of gf.noiseDB
            noise = gf.noiseDB(row, col : col+(gf.nDBsamps/2)-1);             % randperm column of gf.noiseDB
            noise =(noise.*10^(-(gf.noiseAttn/20)));
            
            % Load first half of buffer
            for ii=1:n
                buf=strcat('%s.noiseBufInput',num2str(ii));
                gf.nDBload(1) = DA.WriteTargetVEX(sprintf(buf,gf.stimDevice),0,'F32',noise);
                gf.nDBload(2) = 0;
            end
        end
end




