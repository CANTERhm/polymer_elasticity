%% Daten einlesen und Auswahl Abriss
% Auswahl Abriss bedeutet den Punkt zu wählen, an dem der Abriss beginnt.
% Dieser Startpunkt wird dann markiert und die Daten auf die x und y
% offsets korrigiert, um besser zu fitten.

clearvars -except ForceCurves DataSelection savepath

x_orig = DataSelection(:,1);
y_orig = DataSelection(:,2);
FR_relative_border = [0.95 1];
fig = findobj('Tag', 'korrekturen');
Gui_Elements = struct();
Data = struct();

if ~isempty(fig)
    g = groot;
    set(g, 'CurrentFigure', fig);
    clf;
end

if isempty(fig)
    fig = figure();
    fig.NumberTitle = 'off';
    fig.Name = 'Korrekturen';
    fig.Tag = 'korrekturen';
else
    g = groot;
    set(g, 'CurrentFigure', fig);
    clf;
end

fig.SizeChangedFcn = @TableResizeCallback;

% Erstelle Gui
base = uix.VBox('Parent', fig);
axes_box = uix.HBox('Parent', base);
control_box = uix.VBox('Parent', base);
btn_box = uix.HBox('Parent', control_box, 'Spacing', 10);
results_table = uitable(control_box);

reimport_data_btn = uicontrol('Parent', btn_box, 'Style', 'pushbutton',...
    'String', 'Importiere neue DataSelection',...
    'Callback', @reimport_data_btn_callback);
data_brush_btn = uicontrol('Parent', btn_box, 'Style', 'togglebutton',...
    'String', 'Markiere Datenbereich',...
    'Callback', @data_brush_btn_callback);
new_fitrange_btn = uicontrol(btn_box, 'Style', 'pushbutton',...
    'String', 'Neuer Fitbereich',...
    'Callback', @Callbacks.new_fitrange_btn_callback);

% Gui Einstellungen
base.Heights = [-4 -1];
base.Padding = 5;
control_box.Heights = [30 -1];
control_box.Spacing = 10;
axes_box.Padding = 0;
axes_box.Spacing = 0;

% spaltennamen für results_table
results_table.ColumnName = {'Ks Fit', 'Abriss Länge', 'lk Fit', 'Xl', 'Xr', 'Distanz', 'Lc Fit'};
results_table.ColumnWidth = num2cell(75.*ones(1,length(results_table.ColumnWidth)));

% initiale breite der Spalten 
column_num = length(results_table.ColumnName); % Anzahl der spalten
overall_content_width = results_table.Extent(3); % gesamtbreite der tabelle
column_width = results_table.ColumnWidth{1}; % breite der spalten für parameter (insgesamt 7 parameter)
row_name_width = overall_content_width-column_num*column_width; % breite der spalte mit Zeilennamen

% erstelle slide-panel und füge es der axes_box hinzu
% das slide_panel ist eine die erste spalte der axes_box. Diese wird belegt
% mit einer neuen HBox, dessen breite über den Slide-btn varriert werden
% kann. so wird das "Slide" verhalten erzeugt
slide_panel_container = uix.HBox('Parent', axes_box);
slide_panel = uix.TabPanel('Parent', slide_panel_container);
slide_btn = uicontrol('Parent', slide_panel_container, 'Style', 'togglebutton',...
    'String', '>>',...
    'Callback', @SlidePanelResizeCallback);

% einstellungen des Slide-panle
extended_width = 400;
shrinked_width = 20;

axes_box.Widths(1) = shrinked_width;
slide_panel_container.Widths = [-1 20];

% füge dem slide-panel einen modellparemeter dialog hinzu
dialog_container = uix.VBox('Parent', slide_panel);
vary_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Variable Parameter');
constant_paramter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Konstante Parameter');
slide_panel.TabTitles = {'Modellparameter'};
slide_panel.TabWidth = 100;


% füge axes für den fit hinzu
ax2 = axes(axes_box);
ax2.Tag = 'np_correction';
title('---');
xlabel('vertical tip position / m');
grid on
grid minor

ax1 = axes(axes_box);
plot(ax1, x_orig, y_orig, 'b.',...
    'ButtonDownFcn', @SetStartPoint);
ax1.Tag = 'np_data';
title('Wähle Nullpunkt des Abrisses');
xlabel('vertical tip position / m');
ylabel('vertical deflection / N')
grid on
grid minor

% erstelle data brush-object
h = brush(fig);
h.Enable = 'off';
h.ActionPostCallback = @DoFit;

% füge elemente zu Gui_Elements hinzu
Gui_Elements.fig = fig;
Gui_Elements.ax1 = ax1;
Gui_Elements.ax2 = ax2;
Gui_Elements.base = base;
Gui_Elements.axes_box = axes_box;
Gui_Elements.control_box = control_box;
Gui_Elements.btn_box = btn_box;
Gui_Elements.results_table = results_table;
Gui_Elements.new_fitrange_btn = new_fitrange_btn;
Gui_Elements.data_brush_btn = data_brush_btn;
Gui_Elements.reimport_data_btn = reimport_data_btn;
Gui_Elements.data_brush = h;
Gui_Elements.results_table_column_width = column_width;
Gui_Elements.results_table_column_num = column_num;
Gui_Elements.results_table_row_name_width = row_name_width;
Gui_Elements.results_table_overall_content_width = overall_content_width;
Gui_Elements.slide_panel_container = slide_panel_container;
Gui_Elements.slide_panel = slide_panel;
Gui_Elements.slide_btn = slide_btn;
Gui_Elements.slide_panel_extended_width = extended_width;
Gui_Elements.slide_panel_shrinked_width = shrinked_width;

% füge elemene Data hinzu
Data.orig_line = [x_orig y_orig];
Data.FR_relative_border = FR_relative_border;

clearvars -except ForceCurves DataSelection savepath Data Gui_Elements

%% helper funktionen

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
end

%% Callbacks

function SetStartPoint(src, evt)
    Gui_Elements = evalin('base', 'Gui_Elements');
    Data = evalin('base', 'Data');
    
    fig = Gui_Elements.fig;
    h = Gui_Elements.data_brush;
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

        % für den Fall, dass keine Baselinedaten ausgewählt wurden, werden 0 - 30%
        % der Kraftkurve für die Baselinekorrekturen genutzt
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
        
        % plot der korrigierten daten
        ax2 = Gui_Elements.ax2;
        cla(ax2);
        hold(ax2, 'on');
        corrected_line = plot(ax2, x, y, 'b.');
        hold(ax2, 'off');
        title(ax2, 'Wähle Fitbereich');
        
        % zeichne in dem subplot für Baselinekorrektur die ausgewählte
        % Stelle ein
        ax1 = Gui_Elements.ax1;
        cla(ax1);
        try
            delete(Gui_Elements.xoffset);
        catch
        end
        
        try
            delete(Gui_Elements.yoffset);
        catch
        end
        hold(ax1, 'on')
        plot(ax1, x_orig, y_orig, 'b.',...
            'ButtonDownFcn', @SetStartPoint);
        yoffset = vline(mean(A_bl_range(:,1)), 'k--');
        xoffset = hline(mean(A_bl_range(:,2)), 'k--', 'x/y Offset');
        hold(ax1, 'off');
    end
    
    % schreibe x,y und A_bl_range in den "base" Workspace als Output
    Data.x = x;
    Data.y = y;
    Data.bl_x = bl_x;
    Data.bl_y = bl_y;
    Data.A_bl_range = A_bl_range;
    Data.corrected_line = corrected_line;
    Gui_Elements.xoffset = xoffset;
    Gui_Elements.yoffset = yoffset;
    Gui_Elements.data_brush = h;
    assignin('base', 'Data', Data);
    assignin('base', 'Gui_Elements', Gui_Elements);
end

function DoFit(~, ~)
    Gui_Elements = evalin('base', 'Gui_Elements');
    Data = evalin('base', 'Data');
    
    results_table = Gui_Elements.results_table;
    ax2 = Gui_Elements.ax2;
    corrected_line = Data.corrected_line;
    orig_line = Data.orig_line;
    
    A_bl_range = Data.A_bl_range;
    
    brushed = find(get(corrected_line, 'BrushData'));
    brushed_x = corrected_line.XData(brushed)';
    brushed_y = corrected_line.YData(brushed)';
    B_fit_range = [brushed_x brushed_y];
    bl_x = A_bl_range(:,1);
    bl_y = A_bl_range(:,2);
    
    % fit des Modells
    ReloadPythonModule('pyFit')

    % Versuche den in FR_relative angegebenen fitbereich umzusetzen
    if isempty(B_fit_range)
        [Xr, Xl, FR_relative, new_fit_range] = CalculateRelativeFitRange(FR_relative_border, corrected_line.XData, corrected_line.YData, B_fit_range);
        if ~isempty(new_fit_range) 
            B_fit_range = new_fit_range;
        end

        if ~isempty(new_fit_range)
            ax = findobj('Tag', 'fit_data');
            if ~isempty(ax)
                hold(ax, 'on');
                plot(B_fit_range(:,1), B_fit_range(:,2), 'rx');
                hold(ax, 'off');
            end
        end
    elseif ~isempty(B_fit_range)
        % wenn FR_relative_border leer sind, müssen die Grenzen des
        % ausgewählten fitbereichs berechnet werden
        [Xr, Xl, FR_relative, ~] = CalculateRelativeFitRange([], corrected_line.XData, corrected_line.YData, B_fit_range);
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

    % initial Values
    T = 300;
    kb = 1.38e-23;
    Ks_init = 28;
    Lc_init = 0.5e-6;
    lk_init = 5.4e-10;

    Lc_init = py.pyFit.InitialLc(Kraft, Weg, Ks_init, Lc_init, lk_init, kb, T);
    values = cell(py.pyFit.LmfitModel(Kraft, Weg, Ks_init, Lc_init, lk_init, kb, T, [1, 0, 1])); 

    Ks_fit = values{1,1};
    Lc_fit = values{1,2}; % kurve wurde vorher auf x=0 verschoben
    lk_fit = values{1,3};

    F = linspace(mean(bl_y), 1e-9,1e3); 
    ex_fit = m_FJC(F + mean(bl_y), [Ks_fit Lc_fit lk_fit], [kb T]) + mean(bl_x); % um den Fit an den Orginaldaten zu zeigen, müssen Offsets wieder drauf gerechnet werden
    
    cla(ax2)
    hold(ax2, 'on')
    plot(orig_line(:,1), orig_line(:,2), '.b');
    plot(ex_fit, -F, 'r-');
    hold(ax2, 'off')
    title(ax2, 'Fit Ergebnis');

    % korrektur der Konturlänge
    % der Abriss wurde aus Gründen des Fits in x-Richtung auf null gesetzt.
    % Dieser Wert wird im Nachhinein wieder auf den Fitwert von Lc addiert. Der
    % Fitwert nur für den Abriss wird als "Lc_fit" bezeichnet, der Wert für die
    % "echte" länge des Abrisses im Koordinatensystem wird als Position
    % bezeichent
    position = Lc_fit + bl_x(1);
    
    fitValues = table(Ks_fit, position, lk_fit, Xl, Xr, FR_relative, Lc_fit);
    results_table.ColumnFormat = {'numeric','numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric'};
    results_table.Data = [Ks_fit position lk_fit Xl Xr FR_relative Lc_fit];
    
    % Schreibe die Tabelle fitValues in den "base" Workspace als Output
    Data.fitValues = fitValues;
    Data.B_fit_range = B_fit_range;
    Gui_Elements.results_table = results_table;
    Gui_Elements.ax2 = ax2;
    assignin('base', 'Gui_Elements', Gui_Elements);
    assignin('base', 'Data', Data);

end

function reimport_data_btn_callback(~, ~)
    try
        DataSelection = evalin('base', 'DataSelection');
        Gui_Elements = evalin('base', 'Gui_Elements');
        Data = evalin('base', 'Data');
    catch
        return
    end
    
    ax1 = Gui_Elements.ax1;
    ax2 = Gui_Elements.ax2;
    x_orig = DataSelection(:,1);
    y_orig = DataSelection(:,2);
    
    try
        xoffset = Gui_Elements.xoffset;
        yoffset = Gui_Elements.yoffset;
        delete(xoffset);
        delete(yoffset);
    catch
    end
    
    % setzte alle axes neu auf
    cla(ax1);
    hold(ax1, 'on');
    plot(ax1, x_orig, y_orig, 'b.',...
        'ButtonDownFcn', @SetStartPoint);
    hold(ax1, 'off');
    
    cla(ax2);
    
    % weise orig_line neue Daten zu
    Data.orig_line = [x_orig y_orig];
    
    
    
    % output in den "base workspace"
    assignin('base', 'Data', Data);
end

% function new_fitrange_btn_callback(~, ~)
%         Gui_Elements = evalin('base', 'Gui_Elements');
%         Data = evalin('base', 'Data');
%         x = Data.x;
%         y = Data.y;
%         ax2 = Gui_Elements.ax2;
%         
%         
%         cla(ax2);
%         hold(ax2, 'on');
%         corrected_line = plot(ax2, x, y, 'b.');
%         hold(ax2, 'off');
%         title(ax2, 'Wähle Fitbereich');
% 
%         Gui_Elements.ax2 = ax2;
%         Data.corrected_line = corrected_line;
%         assignin('base', 'Gui_Elements', Gui_Elements);
%         assignin('base', 'Data', Data);
% end

function data_brush_btn_callback(src, ~)
    Gui_Elements = evalin('base', 'Gui_Elements');
    h = Gui_Elements.data_brush;
    reimport_data_btn = Gui_Elements.reimport_data_btn;
    new_fitrange_btn = Gui_Elements.new_fitrange_btn;
    ax1 = Gui_Elements.ax1;
    
    try
        xoffset = Gui_Elements.xoffset;
        yoffset = Gui_Elements.yoffset;
    catch
    end
    
    switch src.Value
        case src.Min % Raised
            h.Enable = 'off';
            reimport_data_btn.Enable = 'on';
            new_fitrange_btn.Enable = 'on';
            ax1.PickableParts = 'visible';
            for i = 1:length(ax1.Children)
                ax1.Children(i).PickableParts = 'visible';
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
            ax1.PickableParts = 'none';
            for i = 1:length(ax1.Children)
                ax1.Children(i).PickableParts = 'none';
            end
            try
                xoffset.PickableParts = 'none';
                yoffset.PickableParts = 'none';
            catch
            end
    end
end

function TableResizeCallback(~, ~)
    Gui_Elements = evalin('base', 'Gui_Elements');
    table = Gui_Elements.results_table;
    table_width = table.Position(3);
    row_name_width = Gui_Elements.results_table_row_name_width;
    
    % berechne die neue spaltenbreite
    new_col_width = (table_width - row_name_width)/7;
    
    % passe spaltenbreite an
    table.ColumnWidth = num2cell(ones(1,7).*new_col_width);
end

function SlidePanelResizeCallback(src, ~)
    Gui_Elements = evalin('base', 'Gui_Elements');
    axes_box = Gui_Elements.axes_box;
    long = Gui_Elements.slide_panel_extended_width;
    short = Gui_Elements.slide_panel_shrinked_width;
    
    switch src.Value
        case src.Min % Raised
            src.String = '>>';
            axes_box.Widths(1) = short;
        case src.Max % Depressed
            src.String = '<<';
            axes_box.Widths(1) = long;
    end
end