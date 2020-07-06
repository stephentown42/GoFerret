function block = get_current_block(tank_dir)
%
% Returns string containing name of current block being recorded, or empty
% if TDT connection fails

global TT

if TT.OpenTank(tank_dir, 'R')

    pause(1)
    block = TT.GetHotBlock;        
    TT.CloseTank;
else
    block = [];
    warning('Failed to open tank')
end
