classdef Callbacks
    %CALLBACKS summary of all used callbacks in polymer_elasticity
    
    methods(Static) % Button Callbacks
        
        function new_fitrange_btn_callback(~, ~)
                Gui_Elements = evalin('base', 'Gui_Elements');
                Data = evalin('base', 'Data');
                x = Data.x;
                y = Data.y;
                ax2 = Gui_Elements.ax2;


                cla(ax2);
                hold(ax2, 'on');
                corrected_line = plot(ax2, x, y, 'b.');
                hold(ax2, 'off');
                title(ax2, 'Wähle Fitbereich');

                Gui_Elements.ax2 = ax2;
                Data.corrected_line = corrected_line;
                assignin('base', 'Gui_Elements', Gui_Elements);
                assignin('base', 'Data', Data);
        end % new_fit_range_btn_callback
        
    end % methods
end

