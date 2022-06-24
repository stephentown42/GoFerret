function checkSnips

global DA gf h 

if get(h.drawWaveforms,'value')
    
    % Check whether current settings match those in the previous cycle
    if gf.waveformStore ~= get(h.drawStore,'value') ||...
       gf.waveformChan  ~= get(h.drawChan,'value'),
   
        cla(h.waveformAxes)
    end
    
    % Get current snip buffer index    
    currentIdx = DA.GetTargetVal(sprintf('%s.ssnip',gf.recDevice));
    
    
    % If new data has been added to store
    if currentIdx > gf.ssnip,

        values = DA.ReadTargetVEX( sprintf('%s.dsnip',gf.recDevice),...
                                   gf.ssnip,...                     % offset points
                                   currentIdx - gf.ssnip,...        % number of words to read
                                   'F32','F32');



        gf.ssnip = currentIdx;
    end
end