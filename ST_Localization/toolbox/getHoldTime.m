function [H, currentHoldTime] = getHoldTime(H)

if isfield(H,'Range')  
    
    H.Idx = H.Idx + 1;
    
    if H.Idx > H.N
        H = initializeRange(H); % Reinitialize after completing range
    end
else
    H = initializeRange(H); % Initialization on first run
end

currentHoldTime = H.Range(H.Idx);



function H = initializeRange(H)


H.Range = H.Max - H.Min;
H.Range = H.Min : H.Range/H.Steps : H.Max;
H.Range = H.Range( randperm( numel(H.Range)));
H.N     = numel(H.Range);
H.Idx   = 1;