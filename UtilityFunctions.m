classdef UtilityFunctions
    %UTILITYFUNCTIONS summary of all used utility function in
    %polymer_elasticity
    %
    % Copryright 2019 Julian Blaser
    % This file is part of polymer_elasticity.
    % 
    % polymer_elasticity is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    % 
    % polymer_elasticity is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    % 
    % You should have received a copy of the GNU General Public License
    % along with polymer_elasticity.  If not, see <http://www.gnu.org/licenses/>.
    
    methods(Static)
        
        function [Xr, Xl, FR_relative, new_fit_range] = CalculateRelativeFitRange(FR_relative_border, xvals, yvals, fit_range)
            % Berechnung der relativen Grenzen des ausgewählten Fitbereichs
            %
            % input: 
            %   - FR_relative_border: 1x2 double vektor mit prozentualen
            %   Grenezn (kann auch leer sein)
            %   - xvals: x-werte des der Kraftkurve
            %   - yvals: y-Werte des der Kraftkurve
            %   - fit_range: nx2 double vektor mit Koordinaten der
            %   Datenpunte im Fitbereich
            %
            % output:
            %   - Xl/ Xr: relativen Grenzen des Fitbereichs bezogen auf die
            %   gesamtlänge der Kraftkurve
            %   - FR_relative: relative Distanz zwischen Xl bzw. Xr (Xl-Xr)
            %   - new_fit_range: nx2 double vektor mit den Koordinaten der 
            %   Datenpunkte, die in FR_relative_border liegen (für den fall
            %   das fit_range leer ist und FR_relative_border nicht)
            
            new_fit_range = [];

            if isempty(FR_relative_border)

                % wenn beides, FR_relative_border und fit_range, leer sind, muss
                % abgebrochen werden
                if isempty(fit_range)
                    Data = evalin('base', 'Data');
                    Xr = Data.FR_right_border;
                    Xl = Data.FR_left_border;
                    FR_relative = Xr-Xl;
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
            % Erleichterte methode um uicontrol Style "text" zu erzeugen.
            % 
            % input: 
            %   - parent: Container, indem textLine angezeigt werden soll
            %   z.B. ein uix.HBox
            %   - text: character-vektor mit dem Anzuzeigenden Text
            %
            % Optional:
            %   - fontAngle: char-vektor mit 'normal' oder 'italic' 
            %   default: 'normal', (siehe uicontrol properties)
            %   - fontWeight: char-vektor mit 'normal' oder 'bold'
            %   default: 'normal', (siehe uicontrol properties)
            %   - horizontalAlignment: char-vektor mit 'left', 'center'
            %   oder 'right'
            %   default: 'left', (siehe uicontrol properties)
            
            
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
        
        function outVar = conversion(inVar)
            % einfache funktion um vektoren des typs "logical" in vektoren
            % des typs double zu konvertieren
            %
            % input:
            %   - inVar: nx1 logic
            % output: 
            %   - outVar: nx1 double
            %
            % Notiz:
            %   notwendig, da python die matlab-version eines boolschen
            %   vektors nicht akzeptiert
            
            outVar = ones(1, length(inVar));
            for i = 1:length(inVar)
                if inVar(i) == true
                    outVar(i) = 0;
                end
            end
        end % conversion
        
        function h_obj = plotFitRange(ax, orig_line, left_border, right_border)            
            % calculate the visualization for fit range
            left_index = floor(length(orig_line)*left_border/100);
            right_index = ceil(length(orig_line)*right_border/100);
            left_border_value = orig_line(left_index);
            right_border_value = orig_line(right_index);
            pos_x1 = left_border_value;
            pos_x2 = right_border_value;
            pos_y1 = min(ax.YLim);
            pos_y2 = max(ax.YLim);
            
            % vertex positions of polygon
            xdata = [pos_x1 pos_x2 pos_x2 pos_x1];
            ydata = [pos_y1 pos_y1 pos_y2 pos_y2];
            
            h_obj = patch(ax, 'XData', xdata, 'YData', ydata,...
                'FaceColor', '#D3D3D3',...
                'EdgeColor', '#D3D3D3',...
                'FaceAlpha', 0.5,...
                'EdgeAlpha', 0.5,...
                'Tag', 'fit_range');
        end % ploFitRange
        
    end
    
end

