function updateTimeline(width)
%
% Function used to continuously shift the timeline slightly ahead of the
% current time every two seconds. 
%
% width - time window in seconds in which show of events
%

global DA gf h

try

fig = h.timelineF;
ax  = h.timelineA;

% X axis
xMax(2)  = ceil(gf.sessionTime);     % session time 

if isOdd(xMax(2)) == 1,              % Make maximum value even
    xMax(2) = xMax(2) + 1;
end

if xMax(2) > xMax(1)                 %If 2 seconds has elapsed, update graph

    xMax(1) = xMax(2);

    if xMax(2) > width, 
        xMin = xMax(2) - width;
    else
        xMin = 0;
    end

    xRange = xMin : width/10 : xMax(2);

    set(h.timelineA,...
        'xlim',      [xMin xMax(2)],...
        'xtick',      xRange);
end

%%%%%%%%%%%%%%%% Get rid of objects outside view (saves memory) %%%%%%%%%%%%

% Find line objects
obj = findobj(h.timelineA,'type','line');

% if there are any such objects
if ~isempty(obj), 
    for i = 1 : length(obj),

        x = get(obj(i),'XData'); % Either a vector or a single value, depending on object type

        if max(x) < xMin,
            delete(obj(i))        
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%% Sensor plot (bits 0-2) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get sensor states
sensors = nan(1,12);

for i = 1 : 12    
   sensors(i) = DA.GetTargetVal( sprintf('%s.Spout%02d', gf.stimDevice, i)); 
end

% Shift values for plotting
sensors = (1:12)+(sensors .* 0.4)-0.2;
sensors = [sensors; sensors];

% Determine time range for line
p = gf.period / 2;
x = gf.sessionTime;
x = [x-p x+p];


% Make timeline the current figure
if get(0,'CurrentFigure') ~= h.timelineF,
    figure(h.timelineF)
end

if get(gcf,'CurrentAxes') ~= h.timelineA,    
    axes(h.timelineA)
end

% Plot
hold on
for i = 1 : 12
   p(i) = plot(x, sensors(:,i),'k');
end

switch gf.status
    case 'WaitForStart'
        set(p(6),'color',[0 0.8 0])     
        
        switch gf.modality
            case 0                
                set(p(gf.LED),'color','b')
            case 1
                set(p(gf.Speaker),'color','r')
            case 2
                set(p(gf.LED),'color','b')                
                set(p(gf.Speaker),'color','r')
        end
                
        if gf.centerStatus
            set(p(6),'LineWidth',2)
        end
        
    case 'WaitForResponse'
        
        switch gf.modality
            case 0                
                set(p(gf.LED),'color','b')
            case 1
                set(p(gf.Speaker),'color','r')
            case 2
                set(p(gf.LED),'color','b')                
                set(p(gf.Speaker),'color','r')
        end
        
    case 'timeout'
        set(p,'color',[0.5 0.5 0.5])
end

% if gf.status 
hold off

catch
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lick plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% var    = {'left'    'right' 'center'};
% color  = {'y'       'r'     'c'     };
% offset = [0         2       1       ] - 0.3;  % This is added to the y value (i.e. 1 + offset)
% 
% for i = 4 : 6,
%    
%     tag = sprintf('%s.%sLick', gf.stimDevice, var{i-3});
%     y = DA.GetTargetVal(tag);%get( eval(sprintf('h.bit%d',i)),'value');
%     
%     if y > 0,
%        
%         y = y + offset(i-3);
%                 
%         if get(0,'CurrentFigure') ~= h.timelineF,
%             figure(h.timelineF)
%         end
%         
%         if get(gcf,'CurrentAxes') ~= h.timelineA,    
%             axes(h.timelineA)
%         end
%         
%         hold on
%         plot(x, y,...
%             'marker',           '*',...
%             'markerEdgeColor',  color{i-3},...        
%             'markerFaceColor',  color{i-3},...
%             'MarkerSize',        5)        
%         
%         hold off
%     end   
% end

% 
% %%%%%%%%%%%%%%%%%%%%%%%% Solenoid plot (bits 4-6) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %         left  right   center
% %bit   = [4     5       6       ];
% color  = {'y'   'r'     'c'     };
% offset = [0     2       1       ] + 0.1;          % This is added to the y value (i.e. 1 + offset)
% 
% for i = 4 : 6,
%    
%     tag = sprintf('%s.bit%d',gf.stimDevice,i);
%     y = DA.GetTargetVal(tag);%get( eval(sprintf('h.bit%d',i)),'value');
%     
%     if y > 0,
%        
%         y = y + offset(i-3);
%         
%         
%         if get(0,'CurrentFigure') ~= h.timelineF,
%             figure(h.timelineF)
%         end
%         
%         if get(gcf,'CurrentAxes') ~= h.timelineA,    
%             axes(h.timelineA)
%         end
%         
%         hold on
%         plot(x, y,...
%             'marker',           'v',...
%             'markerEdgeColor',  color{i-3},...        
%             'markerFaceColor',  color{i-3},...
%             'MarkerSize',        5)        
%         
%         hold off
%     end   
% end
% 


