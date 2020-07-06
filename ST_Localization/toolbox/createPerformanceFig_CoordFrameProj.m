function createPerformanceFig_CoordFrameProj(colors)

global h
              
    % Create figure
    h.performanceF = figure('NumberTitle',    'off',...
                             'name',           'Performance',...
                             'color',          colors.background,...
                             'units',          'centimeters',...
                             'position',       [15 5 12 15],...
                             'MenuBar',        'none',...
                             'KeyPressFcn',    @KeyPress);    
    
    % Create performance figure    
    h.performanceA = subplot(3,2,[1 2 3 4]);
    h.im = imagesc(zeros(12,12),'parent', h.performanceA);
    h.im = repmat(h.im, 1, 4);
    
    colormap( colors.performance_cmap)
    cbar = colorbar;
    ylabel(cbar,'N Trials','FontSize',8, 'color', colors.axis)
    
    axis(h.performanceA, 'square')
    xlabel(h.performanceA, 'Target Location', 'color', colors.axis)
    ylabel(h.performanceA, 'Response Location', 'color', colors.axis)
    title(h.performanceA, 'Performance', 'color', colors.axis)
    
    set(h.performanceA, 'FontSize',     8,...
                        'FontName',     'arial',...
                        'xdir',         'normal',...
                        'color',        colors.background,...
                        'xcolor',       colors.axis,...
                        'ycolor',       colors.axis);
        
    % Create image and line plot
    h.metrix = subplot(3,2,[5 6]);
    set(h.metrix,'nextplot','add',...
                'ylim',[0 1],...
                'color', colors.background,...
                'xcolor', colors.axis,...
                'ycolor', colors.axis)
            
    h.bias_h = plot(0, 0, 'parent', h.metrix,...
                          'Color', colors.bias,...
                          'LineWidth',1.5,...
                          'Marker','.',...
                          'LineStyle','-',...
                          'MarkerSize',3);
    
    h.perf_track = plot(0, 0.5, 'parent', h.metrix,...
                                'Color', colors.performance,...
                                'LineWidth',1.5,...
                                'Marker','.',...
                                'LineStyle','-',...
                                'MarkerSize',3);
    
    grid(h.metrix,'on')
    leg_h = legend(h.metrix,'Bias','p(Correct)','Location','SouthWest');
    set(leg_h,'color',colors.background)
    
    xlabel(h.metrix, 'Trial', 'color', colors.background)
    
    
    
function KeyPress(src,event)

global gf DA

if strcmp(event.Key,'equal')
    valveJumbo_J5(6,gf.valveTimes(6), gf.box_mode)
end

% Valves based on F numbers
for i = 1 : 12    
   if strcmp(event.Key,sprintf('f%d',i))
       valveJumbo_J5(i, gf.valveTimes(i), gf.box_mode)
   end
end

if strcmp(event.Key,'+')        
    DA.SetTargetVal( sprintf('%s.ManualPlay', gf.stimDevice),    1);
    DA.SetTargetVal( sprintf('%s.ManualPlay', gf.stimDevice),    0);
end


