function createPerformanceFig

global h
              
    % Create figure
    h.performanceF = figure('NumberTitle',    'off',...
                             'name',           'Performance (no trials yet completed)',...
                             'color',          'w',...
                             'units',          'centimeters',...
                             'position',       [29.2936    1.2690   20   16.65],...
                             'MenuBar',        'none',...
                             'KeyPressFcn',    @KeyPress);    
    % Create axes            
    tStr = {'Visual','Auditory','AV: Visual Cxt','AV: Auditory Cxt'};
    
    for i = 1 : 4
        
        h.performanceA(i) = subplot(2,2,i); 
        h.im(i) = imagesc(zeros(12,12));    
        cbar = colorbar;
        
        axis square
        xlabel('Target Location')
        ylabel('Response Location')
        ylabel(cbar,'N Trials','FontSize',8)
        title(tStr{i})
    end
        
    set(h.performanceA, 'FontSize',     8,...
                        'FontName',     'arial',...
                        'color',        'none',...
                        'xcolor',       'k',...
                        'xdir',         'normal',...
                        'ycolor',       'k');