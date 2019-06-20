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

fig.SizeChangedFcn = @Callbacks.TableResizeCallback;

% Erstelle Gui
base = uix.VBox('Parent', fig);
axes_box = uix.HBox('Parent', base);
control_box = uix.VBox('Parent', base);
btn_box = uix.HBox('Parent', control_box, 'Spacing', 10);
results_table = uitable(control_box);

reimport_data_btn = uicontrol('Parent', btn_box, 'Style', 'pushbutton',...
    'String', 'Importiere neue DataSelection',...
    'Callback', @Callbacks.reimport_data_btn_callback);
data_brush_btn = uicontrol('Parent', btn_box, 'Style', 'togglebutton',...
    'String', 'Markiere Datenbereich',...
    'Callback', @Callbacks.data_brush_btn_callback);
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
    'Callback', @Callbacks.SlidePanelResizeCallback);

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
    'ButtonDownFcn', @Callbacks.SetStartPoint);
ax1.Tag = 'np_data';
title('Wähle Nullpunkt des Abrisses');
xlabel('vertical tip position / m');
ylabel('vertical deflection / N')
grid on
grid minor

% erstelle data brush-object
h = brush(fig);
h.Enable = 'off';
h.ActionPostCallback = @Callbacks.DoFit;

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
