classdef UtilityFunctions
    %UTILITYFUNCTIONS summary of all used utility function in
    %polymer_elasticity
    
    methods(Static)
        
        function [Xr, Xl, FR_relative, new_fit_range] = CalculateRelativeFitRange(FR_relative_border, xvals, yvals, fit_range)
            new_fit_range = [];

            if isempty(FR_relative_border)

                % wenn beides, FR_relative_border und fit_range, leer sind, muss
                % abgebrochen werden
                if isempty(fit_range)
                    return
                end

                DS_Y_R = find(xvals == xvals(end)); % letzer Wert der ausgewählten kurve entspricht 100%
                if length(DS_Y_R) > 1
                    DS_Y_R = DS_Y_R(1);
                end

                FR_Y_L = find(xvals == fit_range(1,1)); % linke Grenze des fitbereichs;
                if length(FR_Y_L) > 1
                    FR_Y_L = FR_Y_L(1);
                end

                FR_Y_R = find(xvals == fit_range(end,1)); % rechte Grenze des fitbereichs
                if length(FR_Y_R) > 1
                    FR_Y_R = FR_Y_R(1);
                end

                Xl = FR_Y_L/DS_Y_R*100; % linke Grenze relativ
                Xr = FR_Y_R/DS_Y_R*100; % rechte Grenze relativ
                FR_relative = Xr-Xl; % relative Distanz des fitbereichs
            elseif isa(FR_relative_border, 'double')
                % wenn der input FR_relativ ein 1x2 vektor mit relativen grenzen
                % ist!
                % in diesem bedingungsteil kann fit_range auch leer sein 
                Xl = FR_relative_border(1,1)*100; % neue rechte grenze
                Xr = FR_relative_border(1,2)*100; % neue linke grenze
                FR_relative = Xr-Xl; 
                l_index = round(length(xvals)*Xl/100);
                r_index = round(length(xvals)*Xr/100);
                new_fr_x = xvals(l_index:r_index, 1);
                new_fr_y = yvals(l_index:r_index, 1);
                new_fit_range = [new_fr_x new_fr_y];
            end
        end % CalculateRelativeFitRange
        
        function textLine(parent, text, varargin)
            % input parser
            p = inputParser;
            
            addRequired(p, 'parent');
            addRequired(p, 'text');
            addParameter(p, 'fontAngle', 'normal');
            addParameter(p, 'fontWeight', 'normal');
            addParameter(p, 'horizontalAlignment', 'left');
            
            parse(p, parent, text, varargin{:});
            
            parent = p.Results.parent;
            text = p.Results.text;
            fontAngle = p.Results.fontAngle;
            fontWeight = p.Results.fontWeight;
            horizontalAlignment = p.Results.horizontalAlignment;
            
            % create uicontrol for displaying text
            line = uicontrol('Parent', parent, 'Style', 'text');
            line.FontAngle = fontAngle;
            line.FontWeight = fontWeight;
            line.HorizontalAlignment = horizontalAlignment;
            line.String = text;
        end % textLine
        
    end
    
end

