function [Timelines] = TDT_data_interpolation(TDT_data, timestamps, savePath, saveName, ferret, block, side)

%
% function to interpolate data vectors over buffer time vector, in case of issues at buffer boundaries
% saves interpolated vector into one file, then clears each one to hopefully improve memory 
%

try
    
    
    R = double(TDT_data.streams.RV_2.data(:,1:(end-394)));
    D = double(TDT_data.streams.DOut.data(:,1:(end-787)));
    C = double(TDT_data.streams.CSpt.data (:,1:(end-787)));
    
    if isfield(TDT_data.streams, 'BB_2')
        N = double(TDT_data.streams.BB_2.data (:,1:(end-394)));
    end
    
    if isfield(TDT_data.streams, 'sine')
        S = double(TDT_data.streams.sine.data(:,1:(end-787)));
    end
    
    SR24k = TDT_data.streams.RV_2.fs;
    SR48k = TDT_data.streams.DOut.fs;
    
    clear TDT_data
    
    TDT_data_interp.ferret = ferret;
    TDT_data_interp.block  = block;
    TDT_data_interp.side   = side;
    
    save(fullfile(savePath , saveName), '-struct', 'TDT_data_interp');
    disp([saveName ': it begins'])
    
    %% 24k timeline
    
    % check vectors same length
    
    t_l = length(timestamps.timestamps)*2048;
    rv2_l = length(R(1,:)) ;
    
    diff_r_t = rv2_l - t_l;
    
    if  t_l ~= rv2_l
        disp ([timestamps.blockName ' - RV2 vector length does not match. Diff = ' num2str(diff_r_t)])
        
        if diff_r_t < 1000
            
            % just remove extra sample from end
            R = R(:, 1:(end-diff_r_t));
            
        else
            Timelines.time24k = [];
        end
    end
    %elseif t_l == rv2_l
    
    y = reshape(R(1,:), 2048, length(timestamps.timestamps));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
    t = NaN(size(y)); %create empty time matrix same size as reshaped trace matrix
    
    steps = (0:2047)/SR24k; %vector of time increments
    
    for k=1:2048
        t(k,:)=timestamps.timestamps+steps(k).*ones(size(timestamps.timestamps)); %add step to each row (ones to ensure length stays correct?)
    end
    
    t = reshape(t, length(R(1,:)), 1); %put into 1xN shape
    Timelines.time24k = linspace(timestamps.timestamps(1),timestamps.timestamps(end)+steps(end),length(R(1,:)));%make sure all points have equal spacing
    
    clear y
    
    %% 48k timeline
    
    
    t2_l = length(timestamps.timestamps)*4096;
    DO_l = length(D(1,:)) ;
    
    diff_d_t = DO_l - t2_l;
    
    if  t2_l ~= DO_l
        disp ([timestamps.blockName ' - DOut vector length does not match. Diff = ' num2str(diff_r_t)])
        
        if diff_d_t < 2000
            
            % just remove extra sample from end
            
            D = D(:, 1:(end-diff_d_t));
            
        else
            Timelines.time48k = [];
        end
        
        %elseif t2_l == DO_l
    end
    
    y2 = reshape(D(1,:), 4096, length(timestamps.timestamps));  %change shape of trace matrix so each row is one buffer (there are 2048 samples per buffer)
    t2 = NaN(size(y2)); %create empty time matrix same size as reshaped trace matrix
    
    steps2 = (0:4095)/SR48k; %vector of time increments
    
    for k2=1:4096
        t2(k2,:)=timestamps.timestamps+steps2(k2).*ones(size(timestamps.timestamps)); %add step to each row (ones to ensure length stays correct?)
    end
    
    t2 = reshape(t2,length(D(1,:)),1); %put into 1xN shape
    
    Timelines.time48k = linspace(timestamps.timestamps(1),timestamps.timestamps(end)+steps2(end),length(D(1,:)));%make sure all points have equal spacing
    
    clear y2
    
    %% interpolate data vectors
    % RV2 interpolation
    
    
    
    if diff_r_t > 1000
        % extra R samples already removed above for 48k time vector
        disp(['RV2 data vector too different to time vector: ' num2str(diff_d_t)])
        RV2 = [];
        
    else
        
        for m = 1 : 3
            
            RV2_interp(m,:) = interp1(t, R(m,:) ,Timelines.time24k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
        end
        RV2 = round(RV2_interp, 1);
    end
    
    clear R RV2_interp
    
    save(fullfile(savePath, saveName), 'RV2', '-append', '-v7.3')
    disp([saveName ' RV2 saved'])
    clear RV2
    
    %% Neural interpolation (if available)
    
    if exist('N', 'var')
        
        nChan = size(N, 1);
        
        n_l = length(N(1,:)) ;
        
        diff_n_t = n_l - t_l;
        
        if  t_l ~= n_l
            disp ([timestamps.blockName ' - neural vector length does not match. Diff = ' num2str(diff_n_t)])
            
            if diff_n_t < 1000
                
                N = N(:,1:(end-diff_n_t));

                for c = 1: nChan
                    BB_2_interp(c,:) = interp1(t, N(c,:), Timelines.time24k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
                end
               BB_2 = round(BB_2_interp,3);
                
            else
                disp(['Neural data vector too different to time vector: ' num2str(diff_n_t)])
                BB_2 = [];
            end
        else
            
            for c = 1: nChan
                BB_2_interp(c,:) = interp1(t, N(c,:), Timelines.time24k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
            end
            BB_2 = round(BB_2_interp,3);
        end
        
        clear N BB_2_interp
        
        save(fullfile(savePath, saveName), 'BB_2', '-append', '-v7.3')
        disp([saveName ' neural saved'])
        clear BB_2
        
    end
    
    
    
    %% DOut interpolation
    % have figured out whether vector is too long during time48k interp above
    if diff_d_t > 2000
        disp(['Digital out data vector too different to time vector: ' num2str(diff_d_t)])
        DOut = [];
    else
        
        DOut_interp = interp1(t2, D, Timelines.time48k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
        DOut = round(DOut_interp, 1);
    end
    
    clear D
    
    save(fullfile(savePath, saveName), 'DOut', '-append', '-v7.3')
    disp([saveName ' DOut saved'])
    clear DOut
    
    
    %% sine interpolation (if available)
    
    if exist('S', 'var')
        
        
        
        s_l = length(S(1,:)) ;
        
        diff_s_t = s_l - t2_l;
        
        if  t2_l ~= s_l
            disp ([timestamps.blockName ' - sine vector length does not match. Diff = ' num2str(diff_s_t)])
            
            if diff_s_t < 1000
                
                S = S(:,1:(end-diff_s_t));
                
                sine_interp = interp1(t2, S  ,Timelines.time48k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
                sine = round(sine_interp, 3);
            else
                disp(['Sine data vector too different to time vector: ' num2str(diff_s_t)])
                sine = [];
            end
        else
            
            sine_interp = interp1(t2, S  ,Timelines.time48k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
            sine = round(sine_interp, 3);
        end
        
        clear S sine_interp
        
        save(fullfile(savePath, saveName), 'sine', '-append', '-v7.3')
        disp([saveName ' sine saved'])
        clear sine
    end
    
    
    
    %% CSpt interpolation
    
    
    
    c_l = length(C(1,:)) ;
    
    diff_c_t = c_l - t2_l;
    
    if  t2_l ~= c_l
        disp ([timestamps.blockName ' - CSpt vector length does not match. Diff = ' num2str(diff_c_t)])
        if diff_c_t < 1000
            
            C = C(:,1:(end-diff_c_t));
            for j = 1 : 2
                cspt_interp(j,:) = interp1(t2, C(j,:), Timelines.time48k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
            end
            CSpt = round(cspt_interp, 1);
            
        else
            disp(['CSpt data vector too different to time vector: ' num2str(diff_s_t)])
            CSpt = [];
        end
    else
        
        for j = 1 : 2
            cspt_interp(j,:) = interp1(t2, C(j,:), Timelines.time48k ,'linear'); %raw LFP, interpolates incase issue at buffer boundaries
        end
        CSpt = round(cspt_interp, 1);
    end
    
    clear C cspt_interp
    
    save(fullfile(savePath, saveName), 'CSpt', '-append')
    disp([saveName ' centre spout saved'])
    clear CSpt
    
    
   
if ~isempty(Timelines)

    save(fullfile(savePath , saveName), '-struct', 'Timelines', '-append', '-v7.3');
    disp([saveName ': all done'])
    
elseif isempty(Timelines)
    disp(['Unable to interpolate ' ferret ': ' block])
end
    
catch err
    err
    keyboard
end

end



















































