function plotLEDposition

global DA h gf

greenY = DA.GetTargetVal( sprintf( '%s.greenY',  gf.recDevice));
greenX = DA.GetTargetVal( sprintf( '%s.greenX',  gf.recDevice));
redY   = DA.GetTargetVal( sprintf( '%s.redY',  gf.recDevice));
redX   = DA.GetTargetVal( sprintf( '%s.redX',  gf.recDevice));  

% Skip if negative result

if any(isnan([greenX redX redY greenY]))
else
    if any([greenX redX redY greenY] < 0)
        return
    end
end


% Update LED positions
set(h.LEDgreen,'XData',greenX,'YData', greenY)
set(h.LEDred,'XData',redX,'YData', redY)

% Add position to paths
greenPathX = [get(h.pathGreen,'XData') greenX];
greenPathY = [get(h.pathGreen,'YData') greenY];
redPathX   = [get(h.pathRed,'XData') redX];
redPathY   = [get(h.pathRed,'YData') redY];

nP = max([2 length(greenPathX)-100]);

set(h.pathGreen,'XData',greenPathX(nP:end),'YData',greenPathY(nP:end))
set(h.pathRed,'XData',  redPathX(nP:end),  'YData',redPathY(nP:end))

