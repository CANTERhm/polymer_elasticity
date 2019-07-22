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
    
    methods(Static) % Methods for Cost Function
        
        function [J,surfx,surfy] = DoCalculation(cwave, ywave, xwave, fitNum, range)
            % DOCALCULATION Calculate the necessary quantities for the
            % surface plot of the cost function
            %
            %   input:
            %       - cwave: 5x1 double vector of model parameter
            %       - ywave: double-vector; y-values of the measured data
            %       - xwave: double-vector; x-values of the measured data
            %       - fitNum: double; number of points in the surface plot
            %       (scales with the resolution of the surface plot)
            %       - range: 3x2 double-vector; limits of the axis of the
            %       surface plot
            % 
            %   output: 
            %       - J: Matrix with the Z-values for the surface plot
            %       - surfx: X-Values for the surface plot
            %       - surfy: Y-Values for the surface plot
            
            % assign values from workspace
            Data = evalin('base', 'Data');
            hold_Ks = Data.parameter.hold_parameter.cf_Ks;
            hold_Lc = Data.parameter.hold_parameter.cf_Lc;
            hold_lk = Data.parameter.hold_parameter.cf_lk;
            hold = [hold_Ks; hold_Lc; hold_lk];
            
            % determine which parameter represent the x- and y-axis of the
            % surface plot; the third one will be kept constant
            choice = [1; 2; 3];
            variable = choice(~hold); % this parameter will represent the axis
            constant = choice(hold); % the third parameter wiil be kept constant
            
            % create variable necessary for the surface plot
            vals = UtilityFunctions.InitialValues(cwave, fitNum, range);
            kb = cwave(4,1);
            T  = cwave(5,1);
            p1 = vals(:,variable(1,1));
            p2 = vals(:,variable(2,1));
            p_const = ones(length(vals(:,constant))^2, 1).*cwave(constant, 1);
            
            % create the matrix of the coefficient-pairs used for the
            % calculation of the cost function
            h = @(x,Ks,Lc,lk)Lc.*(coth(x.*lk./(kb*T))-kb*T./(x.*lk)).*(1+x./(Ks*lk));
            [X,Y] = meshgrid(p1,p2);
            p = cat(2, X, Y);
            p = reshape(p,[],2);

            % Berechne Costfunction für ein Parameterpärchen und füge sie
            % der Matrix p hinzu
            switch constant
                case 1
                    for i = 1:1:length(p)
                        model = h(xwave,p_const(i,1),p(i,1),p(i,2));
                        p(i,3) = (1/(2*length(xwave)))*((model-ywave)'*(model-ywave));
                    end
                case 2
                    for i = 1:1:length(p)
                        model = h(xwave,p(i,1),p_const(i,1),p(i,2));
                        p(i,3) = (1/(2*length(xwave)))*((model-ywave)'*(model-ywave));
                    end
                case 3
                    for i = 1:1:length(p)
                        model = h(xwave,p(i,1),p(i,2),p_const(i,1));
                        p(i,3) = (1/(2*length(xwave)))*((model-ywave)'*(model-ywave));
                    end
            end

            % generiere output
            J = reshape(p(:,3),length(p1),length(p2));
            surfx = p1;
            surfy = p2;

        end % DoCalculation
        
        function varargout = DoSurf(surfx, surfy, J, Name, Tag, cdata)
            % DOSURF Implements the surface plot for the Cost Function
            %
            %   input:
            %       - surfx: X-Values for the surface plot
            %       - surfy: Y-Values for the surface plot
            %       - J: Matrix with Z-Values for the surface plot
            %       - Name: DisplayName of the surface plot
            %       - Tag: Tag for the surface plot
            %       - cdata: CData property of the surface object
            %
            %   output:
            %       - surface: handle to the created surface-plot
            %       - figure: handle to the figure which had been created
            %       for the surface plot
            
            % assing values from Workspace
            Data = evalin('base', 'Data');
            hold_Ks = Data.parameter.hold_parameter.cf_Ks;
            hold_Lc = Data.parameter.hold_parameter.cf_Lc;
            hold_lk = Data.parameter.hold_parameter.cf_lk;
            hold = [hold_Ks; hold_Lc; hold_lk];

            % determine which parameter represent the x- and y-axis of the
            % surface plot; the third one will be kept constant
            labels = {'K_S / Nm^{-1}'; 'L_C / m'; 'l_K / m'};
            labels = labels(~hold); 
            
            s = findobj(groot, 'Tag', Tag);
            if isempty(s)
                fig = figure('NumberTitle', 'off', 'Name', Name);
                ax = axes(fig);
                s = surf(ax, surfx, surfy, J, 'FaceAlpha', 1);

                ax.XLabel.String = labels{1, 1};
                ax.YLabel.String = labels{2, 1};
                ax.ZLabel.String = 'Costfunction';

                s.FaceColor = 'interp';
                s.FaceLighting = 'gouraud';
                s.Tag = Tag;
                s.DisplayName = Name;
                if ~isempty(cdata)
                    s.CData = cdata;
                end
                colorbar;
                colormap Jet;
                plottools;
            else
                s.XData = surfx;
                s.YData = surfy;
                s.ZData = J;
                if ~isempty(cdata)
                    s.CData = cdata;
                end
                ax = s.Parent;
                fig = ax.Parent;
            end
            
            %create output
            varargout{1} = s;
            varargout{2} = fig;
            
        end % DoSurf
        
        function vals = InitialValues(cwave, fitNum, range)
            % INITIALVALUES generates initial values for the dimensions of the
            % surface plot of the Cost Function
            %
            %   input:
            %       - cwave: 5x1 double vector of model parameter
            %       - fitNum: number of points used for every dimension in the
            %       surface plot
            %       - range: axislimits for the surface plot (in % of the related parameter value)
            %           - range(1,:): range for Ks
            %           - range(2,:): range for Lc
            %           - range(3,:): range for lk
            %
            %   output:
            %       - vals: fitNum x cwave-double vector

            % feste Parameter
            kb = ones(fitNum, 1)*cwave(4,1);
            T  = ones(fitNum, 1)*cwave(5,1);

            rs = size(range);

            if rs(1,1) == 1 && rs(1,2) == 1
                % generiere Zufalls Zahlen
                Ks_rand = sort(UtilityFunctions.RandomValue(ones(fitNum,1)*cwave(1,1), range), 'ascend');
                Lc_rand = sort(UtilityFunctions.RandomValue(ones(fitNum,1)*cwave(2,1), range), 'ascend');
                lk_rand = sort(UtilityFunctions.RandomValue(ones(fitNum,1)*cwave(3,1), range), 'ascend');
                vals = [Ks_rand, Lc_rand, lk_rand, kb, T];
            elseif rs(1,1) == 1 && rs(1,2) == 2
                % Generiere gleichmäßig verteilte Zahlen mit range(1,1)*Parameter
                % als Start und range(1,2)*Parameter als Stop
                Ks_lin = linspace(range(1,1)*cwave(1,1),range(1,2)*cwave(1,1), fitNum)';
                Lc_lin = linspace(range(1,1)*cwave(2,1),range(1,2)*cwave(2,1), fitNum)';
                lk_lin = linspace(range(1,1)*cwave(3,1),range(1,2)*cwave(3,1), fitNum)';
                vals = [Ks_lin, Lc_lin, lk_lin, kb, T];
            elseif rs(1,1) == 3 && rs(1,2) == 2
                Ks_lin = linspace(range(1,1), range(1,2), fitNum)';
                Lc_lin = linspace(range(2,1), range(2,2), fitNum)';
                lk_lin = linspace(range(3,1), range(3,2), fitNum)';
%                 Ks_lin = linspace(range(1,1)*cwave(1,1), range(1,2)*cwave(1,1), fitNum)';
%                 Lc_lin = linspace(range(2,1)*cwave(2,1), range(2,2)*cwave(2,1), fitNum)';
%                 lk_lin = linspace(range(3,1)*cwave(3,1), range(3,2)*cwave(3,1), fitNum)';
                vals = [Ks_lin, Lc_lin, lk_lin, kb, T];
            else
                ME = MException('InitialValues:invalidParameter',...
                    'Falsche Parameterform von "range"');
                throw(ME);
            end

        end % InitialValues
        
        function varOut = updateSurf(var, cwave, ywave, xwave, fitNum)
            % UPDATESURF would update the surface plot variables of the cost function, if a
            % region of interes was specified
            %   
            %   input:
            %       - var: brushed data area of the original surface plot of the
            %       cost function
            %       - cwave: 5x1 double vector of model parameter
            %       - ywave: double-vector; y-values of the measured data
            %       - xwave: double-vector; x-values of the measured data
            %       - range: axislimits for the surface plot (in % of the related parameter value)
            %           - range(1,:): range for Ks
            %           - range(2,:): range for Lc
            %           - range(3,:): range for lk
            %
            %   output:
            %       - varOut: struct with the values for the refinded
            %       surface plot
            %           - varOut.X: X-values for the surface plot
            %           - varOut.Y: Y-values for the surface plot
            %           - varOut.Z: Z-values for the surface plot

            var2 = size(var,1)/3;
            var3 = reshape(var', size(var,2), var2, []);
            X = var3(:,:,1)';
            Y = var3(:,:,2)';
            Z = var3(:,:,3)';
            XInter = linspace(min(X(1,:)), max(X(1,:)), fitNum);
            YInter = linspace(min(Y(:,1)), max(Y(:,1)), fitNum);
            Lc = cwave(2,1);
            kb = cwave(4,1);
            T  = cwave(5,1);

            % recalculate
            h = @(x,Ks,lk)Lc.*(coth(x.*lk./(kb*T))-kb*T./(x.*lk)).*(1+x./(Ks*lk));
            p1 = XInter;
            p2 = YInter;
            [X,Y] = meshgrid(p1,p2);
            p = cat(2, X, Y);
            p = reshape(p,[],2);

            % Berechne Costfunction für ein Parameterpärchen (Ks, lk) und füge sie
            % der Matrix p hinzu
            for i = 1:1:length(p)
                model = h(xwave,p(i,1),p(i,2));
                p(i,3) = (1/(2*length(xwave)))*((model-ywave)'*(model-ywave));
            end 

            J = reshape(p(:,3),length(p1),length(p2));
            surfx = p1;
            surfy = p2;

            varOut = struct('X',surfx,'Y',surfy,'Z',J);
        end % updateSurf
        
        function varargout = plotGlobMin(values, Tag)
            % PLOTGLOBMIN plots the minimum of the global minimum into the
            % surface plot of the cost function
            %
            %   input:
            %       - values: X, Y and Z values of any surface plot,
            %       representing the cost function
            %       - Tag: tag for the plotted coordinates
            %   
            %   output:
            %       - GlobMinCoords: coordinates of the global minimum
            %       - min_coords_handle: Handle to the scatter object
            %       representing the minimum coordinates
            
            [MinDim1, ind_y] = min(values.Z,[],1);
            [GlobMin,ind_x] = min(MinDim1,[],2);
            ind_y = ind_y(ind_x);

            ax = gca();
            scatter_handle = findobj('Tag', 'global_minimum');

            if isempty(scatter_handle)
                hold on
                s = scatter3(ax,values.X(ind_x), values.Y(ind_y), GlobMin, 'rx',...
                    'LineWidth', 2,...
                    'SizeData', 200,...
                    'Tag', Tag);
                hold off
            else
                scatter_handle.XData = values.X(ind_x);
                scatter_handle.YData = values.Y(ind_y);
                scatter_handle.ZData = GlobMin;
            end

            GlobMinCoords = [values.X(ind_x) values.Y(ind_y) GlobMin];
            min_coords_handle = s;
            varargout{1} = GlobMinCoords;
            varargout{2} = min_coords_handle;
            
        end % plotGlobMin
        
        function rand_value = RandomValue(value, range)
            % RANDOMVALUE generates uniformly distributed random values
            
            rand_value = value + random('Uniform', -range*value, range*value);
        end % RandomValue
        
    end
    
    methods(Static) % Miscellaneous Functions
        
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

