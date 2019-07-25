classdef Callbacks
    %CALLBACKS summary of all used callbacks in polymer_elasticity
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
    
    methods(Static) % Button Callbacks
        
        function new_fitrange_btn_callback(~, ~)
            % Callback für den Button "Neuer Fitberich"
                Gui_Elements = evalin('base', 'Gui_Elements');
                Data = evalin('base', 'Data');
                x = Data.orig_line(:,1);
                y = Data.orig_line(:,2);
                main_axes = Gui_Elements.main_axes;


                cla(main_axes);
                hold(main_axes, 'on');
                orig_line = plot(main_axes, x, y, 'b.',...
                    'ButtonDownFcn', @Callbacks.SetStartPoint);
                hold(main_axes, 'off');

                Data.orig_line_object = orig_line;
                Data.burshed_data = [];
                assignin('base', 'Data', Data);
        end % new_fit_range_btn_callback
        
        function data_brush_btn_callback(src, ~)
            % Callback für den Button "Markiere Datenbereich"
            Gui_Elements = evalin('base', 'Gui_Elements');
            Data = evalin('base', 'Data');
            h = Gui_Elements.data_brush;
            reimport_data_btn = Gui_Elements.reimport_data_btn;
            new_fitrange_btn = Gui_Elements.new_fitrange_btn;
            main_axes = Gui_Elements.main_axes;

            try
                xoffset = Data.xoffset;
                yoffset = Data.yoffset;
            catch
            end

            switch src.Value
                case src.Min % Raised
                    h.Enable = 'off';
                    reimport_data_btn.Enable = 'on';
                    new_fitrange_btn.Enable = 'on';
                    main_axes.PickableParts = 'visible';
                    for i = 1:length(main_axes.Children)
                        main_axes.Children(i).PickableParts = 'visible';
                    end
                    try
                        xoffset.PickableParts = 'visible';
                        yoffset.PickableParts = 'visible';
                    catch
                    end
                case src.Max % Depressed
                    h.Enable = 'on';
                    reimport_data_btn.Enable = 'off';
                    new_fitrange_btn.Enable = 'off';
                    main_axes.PickableParts = 'none';
                    for i = 1:length(main_axes.Children)
                        main_axes.Children(i).PickableParts = 'none';
                    end
                    try
                        xoffset.PickableParts = 'none';
                        yoffset.PickableParts = 'none';
                    catch
                    end
            end
            
            % output
            Data.borders_from_table = false;
            assignin('base', 'Data', Data);
        end % data_brush_btn_callback
        
        function reimport_data_btn_callback(~, ~)
            % Callback für den Button "Reimportiere DataSelection"
            
            try
                DataSelection = evalin('base', 'DataSelection');
                Gui_Elements = evalin('base', 'Gui_Elements');
                Data = evalin('base', 'Data');
            catch
                return
            end

            main_axes = Gui_Elements.main_axes;
            x_orig = DataSelection(:,1);
            y_orig = DataSelection(:,2);

            try
                xoffset = Data.xoffset;
                yoffset = Data.yoffset;
                delete(xoffset);
                delete(yoffset);
            catch
            end

            % setzte alle axes neu auf
            cla(main_axes);
            hold(main_axes, 'on');
            orig_line = plot(main_axes, x_orig, y_orig, 'b.',...
                'ButtonDownFcn', @Callbacks.SetStartPoint);
            hold(main_axes, 'off');

            % weise orig_line neue Daten zu
            Data.orig_line_object = orig_line;
            Data.orig_line = [x_orig y_orig];
            Data.A_bl_range = [];
            Data.brushed_data = [];
            Data.corrected_line = [];
            Data.fit_line = [];
            Data.fit_line_object = [];
            Data.fit_range_object = [];
            Data.FR_left_border = [];
            Data.FR_right_border = [];
            Data.xoffset = [];
            Data.yoffset = [];

            % output in den "base workspace"
            assignin('base', 'Data', Data);
        end % reimport_data_btn_callback
        
        function calculate_costfunction_btn_callback(~,~)
            % CALCULATE_COSTFUNCTION_BTN_CALLBACK calculates the
            % Costfunction of the fit and polts it as a surface-plot
            
            % input
            Data = evalin('base', 'Data');
            Gui_Elements = evalin('base', 'Gui_Elements');
            DataSelection = evalin('base', 'DataSelection');
            
            % procedure
            cwave = [Data.parameter.variable_parameter.cf_Ks;...
                Data.parameter.variable_parameter.cf_Lc;...
                Data.parameter.variable_parameter.cf_lk;...
                Data.parameter.constant_parameter.kb;...
                Data.parameter.constant_parameter.T];
            range = Data.cf_parameter_range;
            kraft = -DataSelection(:,2);
            weg = DataSelection(:,1);
            
            plotNumber = Data.cf_plotnumber;
            fitNum = Data.cf_fitnum;
            Name1 = ['Costfunction' num2str(plotNumber)];
            Tag_figure1 = ['costfunction' num2str(plotNumber)];
            
            % surface plot overview
            [J, surfx, surfy] = UtilityFunctions.DoCalculation(cwave, weg, kraft, fitNum, range);
            [surf_object, surf_figure] = UtilityFunctions.DoSurf(surfx, surfy, J, Name1, Tag_figure1, []);
            surf_figure.DeleteFcn = @Callbacks.DeleteCostFunctionFigure;
            
            % create a data brush-object for cost function
            ax = surf_object.Parent;
            fig = ax.Parent;
            h = brush(fig);
            h.Enable = 'off';
            h.ActionPostCallback = @Callbacks.CostFunctionROIProcessingCallback;
            
            % output
            Data.cf_surf_object.(Tag_figure1) = surf_object;
            Data.cf_surf_data.(Tag_figure1).X = surfx;
            Data.cf_surf_data.(Tag_figure1).Y = surfy;
            Data.cf_surf_data.(Tag_figure1).Z = J;
            Gui_Elements.cf_data_brush.(Tag_figure1) = h;
            assignin('base', 'Data', Data);
            assignin('base', 'Gui_Elements', Gui_Elements);
            
        end % calculate_costfunction_btn_callback
        
    end
    
    methods(Static) % Resize Callbacks
        
        function TableResizeCallback(~, ~)
            % resize callback für die Tabelle der Fitergebnisse
            
%             Gui_Elements = evalin('base', 'Gui_Elements');
%             table = Gui_Elements.results_table;
%             table_2 = Gui_Elements.results_table_2;
%             table_width = table.Position(3);
%             table_width_2 = table_2.Position(3);
% 
%             % berechne die neue spaltenbreite
%             new_col_width = floor(table_width/length(table.ColumnName));
%             new_col_width_2 = floor(table_width_2/length(table_2.ColumnName));
% 
%             % passe spaltenbreite an
%             table.ColumnWidth = {new_col_width};
%             table_2.ColumnWidth = {new_col_width_2};
        end % TableResizeCallback
        
        function SlidePanelResizeCallback(src, ~)
            % resize callback für die Elemente des slide-panels
            
            Gui_Elements = evalin('base', 'Gui_Elements');
            axes_box = Gui_Elements.axes_box;
            long = Gui_Elements.slide_panel_extended_width;
            short = Gui_Elements.slide_panel_shrinked_width;
            
            % unfolding behavior
            switch src.Value
                case src.Min % Raised
                    src.String = '>>';
                    axes_box.Widths(1) = short;
                case src.Max % Depressed
                    src.String = '<<';
                    axes_box.Widths(1) = long;
            end
        end % SlidePanelResizeCallback
        
        function ResizeElements(~, ~)
            Gui_Elements = evalin('base', 'Gui_Elements');
            Data = evalin('base', 'Data');
            
            main_axes = Gui_Elements.main_axes;
            orig_line = Data.orig_line;
            A_bl_range = Data.A_bl_range;
            Xl = Data.FR_left_border;
            Xr = Data.FR_right_border;
            
            if ~isempty(Data.xoffset)
                delete(Data.xoffset);
                xoffset = vline(mean(A_bl_range(:,1)), 'k--');
                Data.xoffset = xoffset;
            end
            
            if ~isempty(Data.yoffset)
                delete(Data.yoffset);
                yoffset = hline(mean(A_bl_range(:,2)), 'k--');
                Data.yoffset = yoffset;
            end
            
            if ~isempty(Data.fit_range_object)
                delete(Data.fit_range_object);
                fit_range_object = UtilityFunctions.plotFitRange(main_axes, orig_line, Xl, Xr);
                Data.fit_range_object = fit_range_object;
            end

            assignin('base', 'Gui_Elements', Gui_Elements);
            assignin('base', 'Data', Data);
        end % ResizeElements
        
    end
    
    methods (Static) % Menu Callbacks
        
        function LoadForceCurves(~, ~)
            % LOADFORCECURVES to load Force-Curves, the app "Kraftkurven"
            % will be openend. 
            
            current_directory = pwd;
            cd('Kraftkurven');
            Kraftkurven;
            cd(current_directory);
            
        end % LoadForceCurves
        
        function OpenHelpCallback(~, ~)
            web('Help\polymer_elasticity.html',...
                '-browser');
        end % OpenHelpCallback
        
    end
    
    methods(Static) % Context Menu Callbacks
        
        function SaveFigure(~, ~)
            Data = evalin('base', 'Data');
            try
                orig_line = Data.orig_line;
            catch
                orig_line = [];
            end
            try
                fit_line = Data.fit_line;
            catch
                fit_line = [];
            end
            try
                Xl = Data.FR_left_border;
            catch
                Xl = [];
            end
            try
                Xr = Data.FR_right_border;
            catch
                Xr = [];
            end
            try
                bl_range = Data.A_bl_range;
            catch
                bl_range = [];
            end
            
            % create figure elements
            fig = figure('NumberTitle', 'off', 'Name', 'Save Figure', 'Color', 'white');
            ax = axes(fig);
            grid on;
            grid minor;
            plottools;
            
            % sizes of axes elements
            ax.XLimMode = 'auto';
            ax.XAxis.Label.String = 'Vertical Tip Position / m';
            ax.XAxis.FontSize = 30;
            ax.XAxis.Label.FontSize = 30;
            ax.XAxis.LineWidth = 0.5;
            
            ax.YLimMode = 'auto';
            ax.YAxis.Label.String = 'Vertical Deflection / N';
            ax.YAxis.FontSize = 30;
            ax.YAxis.Label.FontSize = 30;
            ax.YAxis.LineWidth = 0.5;
            
            % plot data
            if ~isempty(orig_line) 
                hold(ax, 'on');
                scatter(ax, orig_line(:,1), orig_line(:,2), 'b.',...
                    'Marker', '.',...
                    'MarkerEdgeColor', 'blue',...
                    'MarkerFaceColor', 'blue',...
                    'SizeData', 50);
                hold(ax, 'off');
            end
            
            % plot fitted data
            if ~isempty(fit_line)
                hold(ax, 'on');
                plot(ax, fit_line(:,1), fit_line(:,2), 'r-',...
                    'LineWidth', 2);
                hold(ax, 'off');
            end
            
            % tight layout
            outerpos = ax.OuterPosition;
            ti = ax.TightInset; 
            left = outerpos(1) + ti(1);
            bottom = outerpos(2) + ti(2);
            ax_width = outerpos(3) - ti(1) - ti(3);
            ax_height = outerpos(4) - ti(2) - ti(4);
            ax.Position = [left bottom ax_width ax_height];
            
            % mark data offsets and fit range
            if ~isempty(orig_line) && ~isempty(bl_range) && ...
                    ~isempty(Xl) && ~isempty(Xr)
                ax.XLimMode = 'auto';
                ax.YLimMode = 'auto';
                hold(ax, 'on');
                xoffset = vline(mean(bl_range(:,1)), 'k--');
                yoffset = hline(mean(bl_range(:,2)), 'k--');
                UtilityFunctions.plotFitRange(ax, orig_line, Xl, Xr);
                delete(xoffset);
                xoffset2 = vline(mean(bl_range(:,1)), 'k--');
                xoffset2.LineWidth = 2;
                yoffset.LineWidth = 2;
                hold(ax, 'off');
            end
            
        end % SaveFigure
        
        function SaveCostFunctionFigure(~, ~)
            % SAVECOSTFUNCTIONFIGURE creates an new figure of one of the
            % costfunction plots in a printable form
            
            fig = gcf();
            save('temp');
%             ax = findobj(fig, 'type', 'axes');
%             surf = findobj(ax, 'type', 'surface');
%             coords = findobj(ax, 'type', 'scatter');
%             coords_annotation = findobj(ax, 'type', 'text');
%             
%             % create new figure 
%             new_fig = figure('NumberTitle', 'off', 'Name', 'Save Figure', 'Color', 'white');
%             new_ax = axes(new_fig);
%             new_ax.NextPlot = 'add';
%             
%             % fill new figure with elements of the original
%             if ~isempty(surf)
%                 surf2 = surf;
%                 surf2.Parent = new_ax;
%             end
%             if ~isempty(coords)
%                 coords.Parent = new_ax;
%             end
            
        end % SaveCostFunctionFigure
        
        function PlotMinimumCoordinates(~, ~)
            % PLOTMINIMUMCOORDINATES plots an marker at the coordinates of
            % the minimum into the actual surface plot
            
            % input
            Data = evalin('base', 'Data');
            plotnumber = Data.cf_plotnumber;
            Tag_scatter = ['global_minimum' plotnumber];
            fig = gcf();
            surf_object = findobj(fig, 'Type', 'surface');
            Tag_surface = surf_object.Tag;
            
            if ~isempty(surf_object)
                data.X = surf_object.XData;
                data.Y = surf_object.YData;
                data.Z = surf_object.ZData;

                % procedure
                if ~isfield(Data.cf_surf_data.(Tag_surface), 'minimum_coordinates_handle')
                    [GlobMin, GlobMin_handle] = UtilityFunctions.plotGlobMin(data,...
                        Tag_scatter);
                    GlobMin_handle.DeleteFcn = @Callbacks.DeleteMinimumCoordinates;
                else
                    assignin('base', 'Data', Data);
                    return
                end
            else
                assignin('base', 'Data', Data);
                return
            end
            
            %output
            Data.cf_surf_data.(Tag_surface).minimum_coordinates_handle = GlobMin_handle;
            Data.cf_surf_data.(Tag_surface).minimum_coordinates = GlobMin;
            assignin('base', 'Data', Data);
            
        end % PlotMinimumCoordinates
        
        function CostFunctionShowMinimumCoordinates(~, ~)
            % COSTFUNCTIONSHOWMINIMUMCOORDINATES plot the Coordinates of
            % the minimum of the costfunction in an textbox
            % next to the marker location
            
            % input from workspace
            Data = evalin('base', 'Data');
            
            fig = gcf();
            surf = findobj(fig, 'type', 'surface');
            
            if ~isempty(surf)
                tag = surf.Tag;
                if isfield(Data.cf_surf_data, tag)
                    if isfield(Data.cf_surf_data.(tag), 'minimum_coordinates')
                        coords = Data.cf_surf_data.costfunction1.minimum_coordinates;
                        t_x = coords(1);
                        t_y = coords(2);
                        t_z = coords(3);
                        label = sprintf('%s: \t %d \n%s: \t %d \n%s: \t %d',...
                            'X', t_x,...
                            'Y', t_y,...
                            'Z', t_z);
                        t = text(t_x, t_y, label);
                        t.Tag = tag;
                        t.EdgeColor = 'black';
                        t.BackgroundColor = 'yellow';
                        t.DeleteFcn = @Callbacks.DeleteMinimumCoordinatesAnnotation;
                        
                        % place the annotation to a nice position
                        pos = t.Extent;
                        new_x = t_x + pos(3)/4;
                        new_y = t_y + pos(4);
                        t.Position = [new_x new_y];
                        
                        % assign to Data-struct
                        Data.cf_surf_data.(tag).minimum_coordinates_annotation = t;
                    end
                end
            end
            
            % output to workspace
            assignin('base', 'Data', Data);
            
        end % CostFunctionShowMinimumCoordinates
        
    end
    
    methods(Static) % other Callbacks
        
        function SetStartPoint(src, evt)
            % callback für die Korrektur des Offsets und darstellung der
            % korrigierten Daten
            
            Gui_Elements = evalin('base', 'Gui_Elements');
            Data = evalin('base', 'Data');

            fig = Gui_Elements.fig;
            main_axes = Gui_Elements.main_axes;
            h = Gui_Elements.data_brush;
            
            Xl = Data.FR_left_border;
            Xr = Data.FR_right_border;
            
            z = zoom(fig);
            p = pan(fig);
            dc = datacursormode(fig);
            b = brush(fig);
            x_orig = src.XData';
            y_orig = src.YData';
            A_bl_range = evt.IntersectionPoint;

            if strcmp(z.Enable, 'off') && strcmp(p.Enable, 'off') && ...
                    strcmp(dc.Enable, 'off') && strcmp(b.Enable, 'off')

                % offset korrekturen in x- und y-dimensionen

                % für den Fall, dass keine Baselinedaten ausgewählt wurden
                s = size(A_bl_range);
                if ~isempty(A_bl_range) && s(2) > 1
                    % Baselinebereich auf dimensionen aufteilen
                    bl_x = A_bl_range(:,1);
                    bl_y = A_bl_range(:,2);
                else
                    bl_x = [];
                    bl_y = [];
                end

                % korrektur für x-offset
                if isempty(bl_x)
                    x = x_orig;
                else
                    x = x_orig-bl_x(1);
                end


                % korrigiere baseline verkippung
                if isempty(bl_y)
                    y = y_orig;
                else
                    y = y_orig-mean(bl_y);
                end

                % zeichne in dem subplot für Baselinekorrektur die ausgewählte
                % Stelle ein
                cla(main_axes);
                try
                    delete(Data.xoffset);
                catch
                end

                try
                    delete(Data.yoffset);
                catch
                end
                try
                    delete(Data.fit_range_object);
                catch
                end
                hold(main_axes, 'on')
                orig_line_object = plot(main_axes, x_orig, y_orig, 'b.',...
                    'ButtonDownFcn', @Callbacks.SetStartPoint);
                xoffset = vline(mean(A_bl_range(:,1)), 'k--');
                yoffset = hline(mean(A_bl_range(:,2)), 'k--');
                fit_range_object = UtilityFunctions.plotFitRange(main_axes, [x_orig y_orig], Xl, Xr);
                xoffset.Tag = 'xoffset';
                yoffset.Tag = 'yoffset';
                hold(main_axes, 'off');
            end

            % schreibe x,y und A_bl_range in den "base" Workspace als Output
            Data.A_bl_range = A_bl_range;
            Data.orig_line_object = orig_line_object;
            Data.corrected_line = [x y];
            Data.offsets_from_table = false;
            Data.xoffset = xoffset;
            Data.yoffset = yoffset;
            Data.fit_range_object = fit_range_object;
            Gui_Elements.data_brush = h;
            assignin('base', 'Data', Data);
            assignin('base', 'Gui_Elements', Gui_Elements);
        end % SetStartPoint
        
        function DoFit(~, ~)
            % callback zur Durchführung und darstellung des Fits
            Gui_Elements = evalin('base', 'Gui_Elements');
            Data = evalin('base', 'Data');

            results_table = Gui_Elements.results_table;
            results_table_2 = Gui_Elements.results_table_2;
            main_axes = Gui_Elements.main_axes;
            
            % test for original data
            try
                orig_line = Data.orig_line;
                orig_line_object = Data.orig_line_object;
            catch
                return
            end
            
            try
                brushed = find(get(orig_line_object, 'BrushData'));
            catch ME % if you can
                switch ME.identifier
                    case 'MATLAB:class:InvalidHandle'
                        % orig_line_object has been deleted
                        return
                end
            end
            if ~isempty(brushed)
                brushed_x = orig_line_object.XData(brushed)';
                brushed_y = orig_line_object.YData(brushed)';
                Data.brushed_data = [brushed_x brushed_y];
            end
            if isempty(brushed) && ~isempty(Data.brushed_data)
                brushed_x = Data.brushed_data(:,1);
                brushed_y = Data.brushed_data(:,2);
            elseif isempty(brushed) && isempty(Data.brushed_data)
                try
                    len = length(orig_line);
                    lb = round(len*Data.FR_left_border/100);
                    rb = round(len*Data.FR_right_border/100);
                    brushed_x = orig_line(lb:rb,1);
                    brushed_y = orig_line(lb:rb,2);
                    Data.brushed_data = [brushed_x brushed_y];
                catch
                    return
                end
            end
            
            try
                if ~Data.offsets_from_table
                    A_bl_range = Data.A_bl_range;
                else
                    xoff = Data.xoffset.XData(1);
                    yoff = Data.yoffset.YData(1);
                    A_bl_range = [xoff yoff];
                end
                bl_x = A_bl_range(:,1);
                bl_y = A_bl_range(:,2);
            catch
                bl_x = [];
                bl_y = [];
            end

            
            % korrektur für x-offset
            if isempty(bl_x)
                x = brushed_x;
            else
                x = brushed_x-bl_x(1);
            end


            % korrigiere baseline verkippung
            if isempty(bl_y)
                y = brushed_y;
            else
                y = brushed_y-mean(bl_y);
            end
            B_fit_range = [x y];

            % Versuche den in FR_relative angegebenen fitbereich umzusetzen
            if ~isempty(Data.brushed_data) && ~Data.borders_from_table
                [Xr, Xl, FR_relative, ~] = UtilityFunctions.CalculateRelativeFitRange([], orig_line(:,1), orig_line(:,2), Data.brushed_data);
            elseif ~isempty(Data.brushed_data) && Data.borders_from_table
                [Xr, Xl, FR_relative, ~] = UtilityFunctions.CalculateRelativeFitRange([], orig_line(:,1), orig_line(:,2), []);
            else
                return
            end

            % sollte FR_relative leer sein muss die variable B_fit_range per Databrush
            % gesetz werden
            if isempty(B_fit_range)
                return
            else
                Weg = B_fit_range(:,1);
                Kraft = -B_fit_range(:,2); 
            end

            % fit des Modells
            ReloadPythonModule('pyFit')

            % initial Values
            T = Data.parameter.constant_parameter.T;
            kb = Data.parameter.constant_parameter.kb;
            Ks_init = Data.parameter.variable_parameter.Ks;
            Lc_init = Data.parameter.variable_parameter.Lc;
            lk_init = Data.parameter.variable_parameter.lk;
            hold_params = UtilityFunctions.conversion([Data.parameter.hold_parameter.Ks,...
                Data.parameter.hold_parameter.Lc,...
                Data.parameter.hold_parameter.lk]);

            Lc_init = py.pyFit.InitialLc(Kraft, Weg, Ks_init, Lc_init, lk_init, kb, T);
            values = cell(py.pyFit.LmfitModel(Kraft, Weg, Ks_init, Lc_init, lk_init, kb, T, hold_params)); 

            Ks_fit = values{1,1};
            Lc_fit = values{1,2}; % kurve wurde vorher auf x=0 verschoben
            lk_fit = values{1,3};
            
            % plot of the fitrepresentation
            if isempty(bl_x)
                xoff = 0;
            else
                xoff = mean(bl_x);
            end
            if isempty(bl_y)
                yoff = 0;
            else
                yoff = mean(bl_y);
            end
            max_force = max(abs(orig_line(:,2)));
            bound = max_force + 1e-1*max_force + yoff;
            F = linspace(0, bound,1e3); 
            ex_fit = m_FJC(F, [Ks_fit Lc_fit lk_fit], [kb T]);
            
            cla(main_axes)
            hold(main_axes, 'on')
            orig_line_object = plot(main_axes, orig_line(:,1), orig_line(:,2), '.b',...
                'ButtonDownFcn', @Callbacks.SetStartPoint);
            fit_line_object = plot(main_axes, ex_fit + xoff, -F + yoff, 'r-');
            fit_range_object = UtilityFunctions.plotFitRange(main_axes,...
                orig_line, Xl, Xr);
            hold(main_axes, 'off')

            % korrektur der Konturlänge
            % der Abriss wurde aus Gründen des Fits in x-Richtung auf null gesetzt.
            % Dieser Wert wird im Nachhinein wieder auf den Fitwert von Lc addiert. Der
            % Fitwert nur für den Abriss wird als "Lc_fit" bezeichnet, der Wert für die
            % "echte" länge des Abrisses im Koordinatensystem wird als
            % "position" bezeichent
            if ~isempty(bl_x)
                rupture_length = Lc_fit + bl_x(1);
            else
                rupture_length = Lc_fit;
            end
            
            try
                xoffset = mean(bl_x);
                yoffset = mean(bl_y);
                fitValues = table(Ks_fit, Lc_fit, lk_fit, xoffset, yoffset, Xl, Xr, FR_relative, rupture_length);
            catch
                % something went wrong, do nothing
                xoffset = [];
                yoffset = [];
                fitValues = [];
            end
            results_table.ColumnFormat = {'numeric','numeric', 'numeric', 'numeric'};
            results_table_2.ColumnFormat = {'numeric', 'numeric', 'numeric', 'numeric', 'numeric'};
            results_table.Data = [Ks_fit Lc_fit lk_fit rupture_length];
            results_table_2.Data = [xoffset yoffset Xl Xr FR_relative];

            % Schreibe die Tabelle fitValues in den "base" Workspace als Output
            Data.fitValues = fitValues;
            Data.orig_line_object = orig_line_object;
            Data.fit_line_object = fit_line_object;
            Data.fit_line = [fit_line_object.XData' fit_line_object.YData']; 
            Data.fit_range_object = fit_range_object;
            Data.A_bl_range = A_bl_range;
            Data.FR_left_border = Xl;
            Data.FR_right_border = Xr;
            assignin('base', 'Data', Data);
            assignin('base', 'Gui_Elements', Gui_Elements);

        end % DoFit
        
        function UpdateVaryParameterCallback(~, evt)
            % CellEditCallback für die tabelle der variablen parameter des
            % modells
            
            % input
            Data = evalin('base', 'Data');
            
            row = evt.Indices(1);
            col = evt.Indices(2);
            switch row
                case 1
                    switch col
                        case 2
                            try
                                Data.parameter.variable_parameter.Ks = str2double(evt.EditData);
                            catch
                                return
                            end
                        case 4
                            Data.parameter.hold_parameter.Ks = evt.EditData;
                    end
                case 2
                    switch col
                        case 2
                            try
                                Data.parameter.variable_parameter.Lc = str2double(evt.EditData);
                            catch
                                return
                            end
                        case 4
                            Data.parameter.hold_parameter.Lc = evt.EditData;
                    end
                case 3
                    switch col
                        case 2
                            try
                                Data.parameter.variable_parameter.lk = str2double(evt.EditData);
                            catch
                                return
                            end
                        case 4
                            Data.parameter.hold_parameter.lk = evt.EditData;
                    end
            end
            
            % output
            assignin('base', 'Data', Data);
        end % UpdateParameterCallback
        
        function UpdateConstantParameterCallback(~, evt)
            % CellEditCallback für die tabelle der konstanten parameter des
            % modells
            
            % input
            Data = evalin('base', 'Data');
            
            row = evt.Indices(1);          
            switch row
                case 1
                    try
                        Data.parameter.constant_parameter.kb = str2double(evt.EditData);
                    catch
                        return
                    end
                case 2
                    try
                        Data.parameter.constant_parameter.T = str2double(evt.EditData);
                    catch
                        return
                    end
            end

            % output
            assignin('base', 'Data', Data);
        end % UpdateConstantParameterCallback
        
        function UpdateFitParameterCallback(~, evt)
            % UPDATEFITPARAMETERCALLBACK Update of Fit Parameter if the
            % user wants to have numerical input of fit parameter like fit
            % range, fit borders or offsets
            
            % input
            Data = evalin('base', 'Data');
            Gui_Elements = evalin('base', 'Gui_Elements');
            main_axes = Gui_Elements.main_axes;
            
            col = evt.Indices(2);
            switch col
                case 1 % xoffset
                    try
                        delete(Data.xoffset);
                        
                    catch
                    end
                    try
                        delete(Data.fit_range_object);
                    catch
                    end
                    hold(main_axes, 'on')
                    xoffset = vline(str2double(evt.EditData), 'k--');
                    xoffset.Tag = 'xoffset';
                    hold(main_axes, 'off');
                    Data.xoffset = xoffset;
                    Data.offsets_from_table = true;
                case 2 % yoffset
                    try
                        delete(Data.yoffset);
                    catch
                    end
                    try
                        delete(Data.fit_range_object);
                    catch
                    end
                    hold(main_axes, 'on')
                    yoffset = hline(str2double(evt.EditData), 'k--');
                    yoffset.Tag = 'xoffset';
                    hold(main_axes, 'off');
                    Data.yoffset = yoffset;
                    Data.offsets_from_table = true;
                case 3 % Xl
                    try
                        Data.FR_left_border = str2double(evt.EditData);
                    catch
                        return
                    end
                    Data.borders_from_table = true;
                case 4 % Xr
                    try
                        Data.FR_right_border = str2double(evt.EditData);
                    catch
                        return
                    end
                    Data.borders_from_table = true;
            end
            
            % output
            assignin('base', 'Data', Data);
        end % UpdateFitParameterCallback
        
        function CloseRequestCallback(src, evt)
            if isa(evt, 'struct')
                try
                    event_source = evt.EventSourceName;
                    if strcmp(event_source, 'Kraftkurven')
                        return
                    end
                catch
                    delete(src);
                end
            else
                delete(src);
            end
        end % CloseRequestCallback
        
        function EditPlotNumberCallback(src, ~)
            % EDITPLOTNUMBERCALLBACK This callback evaluates the input for
            % the cf_plotnumber_edit-object. 
            %
            %   If the userinput is not convertable to a double-type
            %   Variable, the userinput gets declined.
            
            % input
            Data = evalin('base', 'Data');
            
            % new value assignment
            old_value = num2str(Data.cf_plotnumber);
            new_value = str2double(src.String);
            if ~isnan(new_value)
                Data.cf_plotnumber = new_value;
            else
                src.String = old_value;
            end
            
            % output
            assignin('base', 'Data', Data);
        end % EditPlotNumberCallback
        
        function EditFitNumCallback(src, ~)
            % EIDTFITNUMCALLBACK writes valid parameter-values for
            % cf_fitnum-property to Data
            
            % input
            Data = evalin('base', 'Data');
            
            % new value assignment
            old_value = num2str(Data.cf_fitnum);
            new_value = str2double(src.String);
            if ~isnan(new_value)
                Data.cf_fitnum = new_value;
            else
                src.String = old_value;
            end
            
            % output
            assignin('base', 'Data', Data);
            
        end % EditFitNumCallback
        
        function CostFunctionHoldParameterCallback(src, evt)
            % COSTFUNCTIONHOLDPARAMETERCALLBACK Ensures, that only one
            % Checkbox for the Hold-Column in the Cost Function Parameter
            % Table can be checked. It also writes valid parmeter values to
            % the cf_Ks, cf_Lc and cf_lk properties of
            % Data.parameter.variable_parameter
            
            %input
            Data = evalin('base', 'Data');
            
            % procedure
            row = evt.Indices(1);
            col = evt.Indices(2);
            new_hold_data = false(3,1);
            choice = {'cf_Ks'; 'cf_Lc'; 'cf_lk'};
            
            % ensure that for all times only one hold-checkbox can be checked.
            % any other checkbox must be unchecked.
            switch col
                case 4 % hold-column
                    if (evt.EditData)
                        new_hold_data(row, 1) = true;
                        src.Data(:,4) = num2cell(new_hold_data);
                        hold_par = choice(new_hold_data);
                        var_par = choice(~new_hold_data);
                        var1 = var_par(1);
                        var2 = var_par(2);
                        Data.parameter.hold_parameter.(hold_par{1}) = true;
                        Data.parameter.hold_parameter.(var1{1}) = false;
                        Data.parameter.hold_parameter.(var2{1}) = false;
                    else
                        new_hold_data(row, 1) = evt.PreviousData;
                        src.Data(:,4) = num2cell(new_hold_data);
                    end
                case 2 % value-column
                    if isempty(evt.Error)
                        switch row
                            case 1 % cf_Ks
                                value = str2double(evt.EditData);
                                Data.parameter.variable_parameter.cf_Ks = value; 
                            case 2 % cf_Lc
                                value = str2double(evt.EditData);
                                Data.parameter.variable_parameter.cf_Lc = value; 
                            case 3 % cf_lk
                                value = str2double(evt.EditData);
                                Data.parameter.variable_parameter.cf_lk = value;
                        end
                    end
            end
            
            % output
            assignin('base', 'Data', Data);
            
        end % CostFunctionHOldParameterCallback
        
        function CostFunctionRangeEditCallback(~, evt)
            % COSTFUNCTIONRANGEEDITCALLBACK Writes valid range-values for
            % the Cost Function into the Data.cf_range-property 
            
            % input
            Data = evalin('base', 'Data');
            
            % procedure
            row = evt.Indices(1);
            col = evt.Indices(2);
            
            if isempty(evt.Error)
                value = str2double(evt.EditData);
                Data.cf_parameter_range(row, col-1) = value;
            end
            
            % output
            assignin('base', 'Data', Data);
            
        end % CostFunctionRangeEditCallback
        
        function CostFunctionROIProcessingCallback(src, ~)
            % COSTFUNCTIONROIPROCESSINGCALLBACK processing the
            % ActionsPostCallback of the data brush linked to the surface
            % plot of the cost function
            
            % input
            Data = evalin('base', 'Data');
            DS = evalin('base', 'DataSelection');
            
            % procedure
            plotNumber = Data.cf_plotnumber;
            fitNum = Data.cf_fitnum;
            cwave = [Data.parameter.variable_parameter.cf_Ks;...
                Data.parameter.variable_parameter.cf_Lc;...
                Data.parameter.variable_parameter.cf_lk;...
                Data.parameter.constant_parameter.kb;...
                Data.parameter.constant_parameter.T];
            kraft = -DS(:,2);
            weg = DS(:,1);
            Name1 = ['Costfunction' num2str(plotNumber) '_zoomed'];
            Tag_figure1 = ['costfunction' num2str(plotNumber) '_zoomed'];
            ax = src.Children;
            surf = findobj(ax, 'type', 'surface');
            
            try
                brushed = surf.BrushData;
            catch ME % if you can
                switch ME.identifier
                    case 'MATLAB:class:InvalidHandle'
                        % orig_line_object has been deleted
                        return
                end
            end
            
            % process the region of interest
            mask = logical(brushed);
            [X,Y] = meshgrid(surf.XData,surf.YData);
            roi_x = CropMatrix(X, mask);
            roi_y = CropMatrix(Y, mask);
            roi_z = CropMatrix(surf.ZData, mask);
            roi = cat(1,roi_x,roi_y,roi_z);
            roi = UtilityFunctions.updateSurf(roi, cwave, weg, kraft, fitNum);
            
            % calculate new z-data-ranges for the surface plot, in order to
            % adjust the colorbar
            CData = roi.Z;
            maxZ = max(max(roi.Z)) - 0.1*max(max(roi.Z));
            mask = (roi.Z >= maxZ);
            CData(mask) = maxZ;
            
            % recalculate surface plot
            [surf_object_zoomed, surf_figure_zoomed] = UtilityFunctions.DoSurf(roi.X, roi.Y, roi.Z, Name1, Tag_figure1, CData);
            surf_figure_zoomed.DeleteFcn = @Callbacks.DeleteCostFunctionFigure;
            
            % create a context menu for the cost function refinement
            if isempty(surf_object_zoomed.UIContextMenu)
                cm = uicontextmenu;
                surf_object_zoomed.UIContextMenu = cm;
                uimenu(cm, 'Label', 'Plot Minimum Coordinates', 'Callback', @Callbacks.PlotMinimumCoordinates);
            end
            
            % create a data brush-object for cost function
            h = brush(surf_figure_zoomed);
            h.Enable = 'off';
            h.ActionPostCallback = @Callbacks.CostFunctionROIProcessingCallback;
            
            % output
            Data.cf_surf_object.(Tag_figure1) = surf_object_zoomed;
            Data.cf_surf_data.(Tag_figure1).X = roi.X';
            Data.cf_surf_data.(Tag_figure1).Y = roi.Y';
            Data.cf_surf_data.(Tag_figure1).Z = roi.Z;
            assignin('base', 'Data', Data);
            
        end % CostFunctionRefinementCallback
        
        function DeleteMinimumCoordinates(src, ~)
            % DELETESMINIMUMCOORDINATES delets the minimum coordinates from
            % the Data-struct in the workspace, if they were deleted from
            % the axes
            
            % input
            Data = evalin('base', 'Data');
            
            % procedure
            ax = src.Parent;
            fig = ax.Parent;
            surf = findobj(fig, 'Type', 'surface');
            fields = {'minimum_coordinates',...
                'minimum_coordinates_handle'};
            
            try
                delete(Data.cf_surf_data.(surf.Tag).minimum_coordinates_handle)
            catch
            end
            try
                Data.cf_surf_data.(surf.Tag) = rmfield(Data.cf_surf_data.(surf.Tag), fields);
            catch
            end
            
            % try also to delete the coordinate annotation and remove it
            % form the data-sturct, if it exists
            try
                delete(Data.cf_surf_data.(surf.Tag).minimum_coordinates_annotation);
            catch
            end
            try
                Data.cf_surf_data.(surf.Tag) = rmfield(Data.cf_surf_data.(surf.Tag),...
                    'minimum_coordinates_annotation');
            catch
            end
            
            % output
            assignin('base', 'Data', Data);
            
        end % DeleteMinimumCoordinates
        
        function DeleteMinimumCoordinatesAnnotation(src, ~)
            % DELETEMINIMUMCOORDIANTESANNOTATION if the minimum coordinates
            % annotation had been deleted, the handle has to be deleted
            % from the Data.cf_surf_data.(obj_tag) structure
            
            % input from workspace
            Data = evalin('base', 'Data');
            
            try
                Data.cf_surf_data.(src.Tag) = rmfield(Data.cf_surf_data.(src.Tag), 'minimum_coordinates_annotation');
            catch
            end
            
            % output to workspace
            assignin('base', 'Data', Data);
            
        end % DeleteMinimumCoordinatesAnnotation
        
        function DeleteCostFunctionFigure(src, ~)
            % DELETECOSTFUNCTIONFIGURE Callback for the correct deletion
            % of the cost function properties out of the data-object if the
            % cost function figure has been closed

            % input
            Data = evalin('base', 'Data');
            
            % procedure
            ax = src.Children;
            surf = findobj(ax, 'Type', 'surface');
            try
                Data.cf_surf_data = rmfield(Data.cf_surf_data, surf.Tag);
            catch
            end
            try
                Data.cf_surf_object = rmfield(Data.cf_surf_object, surf.Tag);
            catch
            end
            
            % output
            assignin('base', 'Data', Data);
            
        end % DeleteCostFunctionFigure
        
    end
    
end

