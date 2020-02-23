function createPerformanceFig_CoordFrameProj

global h
              
    % Create figure
    h.performanceF = figure('NumberTitle',    'off',...
                             'name',           'Performance',...
                             'color',          'w',...
                             'units',          'centimeters',...
                             'position',       [15 5 12 15],...
                             'MenuBar',        'none',...
                             'KeyPressFcn',    @KeyPress);    
    
    % Create performance figure    
    h.performanceA = subplot(3,2,[1 2 3 4]);
    h.im = imagesc(zeros(12,12),'parent', h.performanceA);
    h.im = repmat(h.im, 1, 4);
    
    colormap(magma)
    cbar = colorbar;
    ylabel(cbar,'N Trials','FontSize',8)
    
    axis(h.performanceA, 'square')
    xlabel(h.performanceA, 'Target Location')
    ylabel(h.performanceA, 'Response Location')
    title(h.performanceA, 'Performance')
    
    set(h.performanceA, 'FontSize',     8,...
    'FontName',     'arial',...
    'color',        'none',...
    'xcolor',       'k',...
    'xdir',         'normal',...
    'ycolor',       'k');
        
    % Create image and line plot
    h.metrix = subplot(3,2,[5 6]);
    set(h.metrix,'nextplot','add','ylim',[0 1])
    h.bias_h = plot(0, 0, 'parent', h.metrix,'Color',[0.8 0 0],...
        'LineWidth',1.5,'Marker','.','LineStyle','-','MarkerSize',3);
    
    h.perf_track = plot(0, 0.5, 'parent', h.metrix,'Color',[0 0.5 0],...
        'LineWidth',1.5,'Marker','.','LineStyle','-','MarkerSize',3);
    
    grid(h.metrix,'on')
    legend(h.metrix,'Bias','p(Correct)','Location','SouthWest')
    
    xlabel(h.metrix, 'Trial')
%     ylabel(h.metrix, 'Bias')        
    
    
