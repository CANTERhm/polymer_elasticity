%% poymere_elasticity
% Es muss die Variable "DataSelection" im Workspace vorhanden sein, bevor
% das Skirpt gestartet wird. "DataSelection" kann am einfachsten �ber die
% App "Kraftkurven" erstellt werden.
% DataSeletion: nx2 Vektor mit x, y koordinaten von Datenpunkten 
%   - DataSelection(:,1): x-koordinaten
%   - DataSelection(:,2): y-koordinaten
%
% F�r eine Detailierte Anleitung siehe den Hilfe Tab im Slide-Men� von
% polymere_elasticity
% clearvars -except ForceCurves DataSelection savepath
%
% siehe auch: Hilfe.docx oder Hilfe.pdf

%% erstelle parameter
vary_parameter = Results();
constant_parameter = Results();
hold_parameter = Results();

vary_parameter.addproperty('Ks');
vary_parameter.addproperty('Lc');
vary_parameter.addproperty('lk');
vary_parameter.Ks = 28;
vary_parameter.Lc = 0.5e-6;
vary_parameter.lk = 5.4e-10;

constant_parameter.addproperty('T');
constant_parameter.addproperty('kb');
constant_parameter.T = 300;
constant_parameter.kb = 1.38e-23;

hold_parameter.addproperty('Ks');
hold_parameter.addproperty('Lc');
hold_parameter.addproperty('lk');
hold_parameter.Ks = false;
hold_parameter.Lc = true;
hold_parameter.lk = true;

%% daten einlesen

x_orig = DataSelection(:,1);
y_orig = DataSelection(:,2);
fig = findobj('Tag', 'polymer_elasticity');
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
    fig.Name = 'Polymer Elasticity';
    fig.Tag = 'polymer_elasticity';
else
    g = groot;
    set(g, 'CurrentFigure', fig);
    clf;
end

fig.SizeChangedFcn = @Callbacks.TableResizeCallback;

%% erstelle gui
base = uix.VBox('Parent', fig);
axes_box = uix.HBox('Parent', base);
control_box = uix.VBox('Parent', base);
btn_box = uix.HBox('Parent', control_box, 'Spacing', 10);
results_table = uitable(control_box);

reimport_data_btn = uicontrol('Parent', btn_box, 'Style', 'pushbutton',...
    'String', 'Reimportiere DataSelection',...
    'Callback', @Callbacks.reimport_data_btn_callback);
data_brush_btn = uicontrol('Parent', btn_box, 'Style', 'togglebutton',...
    'String', 'Markiere Datenbereich',...
    'Callback', @Callbacks.data_brush_btn_callback);
new_fitrange_btn = uicontrol(btn_box, 'Style', 'pushbutton',...
    'String', 'Neuer Fitbereich',...
    'Callback', @Callbacks.new_fitrange_btn_callback);

%% gui einstellungen
base.Heights = [-4 -1];
base.Padding = 5;
control_box.Heights = [30 -1];
control_box.Spacing = 10;
axes_box.Padding = 0;
axes_box.Spacing = 0;

%% spaltennamen f�r results_table
results_table.ColumnName = {'Ks Fit', 'Abriss L�nge', 'lk Fit', 'Xl', 'Xr', 'Distanz', 'Lc Fit'};
results_table.RowName = {};

% calculate ColumnWidth
table_width = results_table.Position(3);
col_num = length(results_table.ColumnName);
col_width = floor(table_width/col_num);
results_table.ColumnWidth = {col_width};

%% erstelle slide-panel 
% das slide_panel ist eine die erste spalte der axes_box. Diese wird belegt
% mit einer neuen HBox, dessen breite �ber den Slide-btn varriert werden
% kann. so wird das "Slide" verhalten erzeugt
slide_panel_container = uix.HBox('Parent', axes_box);
slide_panel = uix.TabPanel('Parent', slide_panel_container);
slide_btn = uicontrol('Parent', slide_panel_container, 'Style', 'togglebutton',...
    'String', '>>',...
    'Callback', @Callbacks.SlidePanelResizeCallback);

%% slide-panel: modellparameter-tab
dialog_container = uix.VBox('Parent', slide_panel);
vary_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Variable Parameter');
button_container = uix.HButtonBox('Parent', dialog_container);
vary_parameter_container = uix.VBox('Parent', vary_parameter_panel);
constant_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Konstante Parameter');
constant_parameter_container = uix.VBox('Parent', constant_parameter_panel);

% content of vary_parameter_container

vary_data = {'Ks', vary_parameter.Ks, 'N/m', hold_parameter.Ks;...
            'Lc', vary_parameter.Lc, 'm', hold_parameter.Lc;...
            'lk', vary_parameter.lk, 'm', hold_parameter.lk};

vary_parameter_table = uitable(vary_parameter_container);
vary_parameter_table.ColumnName = {'Parameter', 'Wert', 'Einheit', 'fixieren?'};
vary_parameter_table.RowName = {};
vary_parameter_table.Data = vary_data;
vary_parameter_table.ColumnEditable = [false true false true];
vary_parameter_table.CellEditCallback = @Callbacks.UpdateVaryParameterCallback;

% content of constant_parameter_container

constant_data = {'kb', constant_parameter.kb, 'J/K';...
                'T', constant_parameter.T, 'K'};

constant_parameter_table = uitable(constant_parameter_container);
constant_parameter_table.ColumnName = {'Parameter', 'Wert', 'Einheit'};
constant_parameter_table.RowName = {};
constant_parameter_table.Data = constant_data;
constant_parameter_table.ColumnEditable = [false true false]; 
constant_parameter_table.CellEditCallback = @Callbacks.UpdateConstantParameterCallback;

% configure the DoFit button
button_container.HorizontalAlignment = 'right';
button_container.VerticalAlignment = 'middle';
do_fit_btn = uicontrol('Parent', button_container, 'Style', 'pushbutton',...
    'String', 'Do Fit',...
    'Callback', @Callbacks.DoFit);

% configure the dialog_container
dialog_container.Heights = [-1 20 -1];

%% slide-panel: hilfe-tab
help_panel = uix.ScrollingPanel('Parent', slide_panel);
help_container = uix.VBox('parent', help_panel);

general_panel = uix.BoxPanel('Parent', help_container, 'Title', 'Allgemein');
general_container = uix.VBox('Parent', general_panel);
userguide_panel = uix.BoxPanel('Parent', help_container, 'Title', 'Anleitung');
userguide_container = uix.VBox('Parent', userguide_panel);
other_panel = uix.BoxPanel('Parent', help_container, 'Title', 'Sonstiges');
other_container = uix.VBox('Parent', other_panel);

% inhalt general_container
str = {['Dieses Programm dient der Auswertung von Abrissen (Kraft vs. Weg) ' ...
    'aus Force-Clamp-Experimenten, oder �hnlichen Kurven. Die Abrisse werden ' ...
    'mit dem Modell der erweiterten, freiverbundenen Kette Ausgewertet: '],...
    'Lc*[coth(x)-1/s]*(1+F/(Ks*lk)) mit x = F*lk/(kb*T)',...
    ''};
UtilityFunctions.textLine(general_panel, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% inhalt userguide_container
str = '1. Auswahl des Abrisses';
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['Der Startpunkt des Abrisses wird mit der linken Maustaste auf der linken' ...
    'Abbildung (Titel: W�hle Startpunkt des Abrisses) gew�hlt. Wenn kein Fehler aufgetreten ist,' ...
    'wird in dieser Abbildung der gew�hlte Startpunkt durch ein gestrichteltes Fadenkreuz' ...
    'mit der Beschriftung "x/y Offset" markiert. In der rechten Abbdilung (Titel zun�chst: ---) ' ...
    'erscheint der um den Offset korrigierten Abriss. Der Abbildungstitel' ...
    'der rechten Abbdildung �ndert sich zu "W�hle Fitbereich".'],...
    ''};
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = '2. Auswahl des Fitbereichs';
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['Um Den Datenbereich f�r den Fit des Modells auszuw�hlen muss der Button ' ...
    '"Markiere Datenbereich" aktiviert werden. Danach �ndert sich der Cursor ' ...
    'im Bereich beider Abbildungen zu einem schwarzen, durchgehenden Fadenkreuz. ' ... 
    'Nur in der rechten Abbdilung (Titel: W�hle Fitbereich) darf der Fitbereich ausgew�lt werden. ' ...
    'Zum Ausw�hlen des Fitbereichs, linke Maustaste gedr�ckt halten und mit dem Rechteck ' ...
    'die zu merkierenden Daten �berstreichen. Nachdem die linke Maustaste losgelassen wurde, ' ...
    'wird das Modell an die Daten angepasst und in der rechten Abbildung angezeigt. '],...
    ''};
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% inhalt other_container
str = 'Laden neuer Daten';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['Ver�nderte Daten in "DataSelection" k�nnen neu importiert werden. Dazu ' ...
    'muss der Button "Reimportiere DataSelection" bet�tigt werden. Danach ' ...
    'wird der neue Datensatz in der linken Abbildung angezeigt. Alle Offsets, ' ...
    'die Markierung des Fitbereichs, der Fit sowie der Graph des Abrisses werden gel�scht'],...
    ''};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Neuer Fitbereich';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['Um einen neuen Fitbereich zu w�hlen ohne dabei den aktuellen Offset ' ...
    'des Abrisses zu �ndern, muss der Button "Neuer Fitbereich" bet�tigt werden. ' ...
    'Es wird der aktuelle Fitbereich, sowie der Fit selbst gel�scht.']};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Abspeichern eines Fits';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['Es ist m�glich den Fit des Abrisses als .png-Bild zu speichern. Dazu ' ...
    'muss mit der rechten Maustaste auf die rechte Abbildung geklickt werden. Es ' ...
    'erscheint ein Kontextmen�, indem der Men�punkt "Grafik speicher" auswew�hlt werden muss. ' ...
    'Danach kann in einem Dialog der Speicherort festgelegt werden (noch nicht implementiert).']};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');



% hilfe-tab einstellungen
help_panel.MinimumHeights = 700;
help_panel.MinimumWidths = 300;

help_container.Heights = [100 -1 -1];
userguide_container.Heights = [15 -1 15 -1];
other_container.Heights = [15 -1 15 -1 15 -1];

%% einstellungen slide-panle
extended_width = 400;
shrinked_width = 20;

axes_box.Widths(1) = shrinked_width;
slide_panel_container.Widths = [-1 20];
slide_panel.TabTitles = {'Modellparameter', 'Hilfe'};
slide_panel.TabWidth = 100;

%% erstelle main_axes f�r den Fit
main_axes = axes(axes_box);
main_axes.Tag = 'main_axes';
orig_line_object = plot(main_axes, x_orig, y_orig, 'b.',...
    'ButtonDownFcn', @Callbacks.SetStartPoint);
xlabel('vertical tip position / m');
ylabel('vertical deflection / N')
grid on
grid minor

% add listener for axis-limits
z = zoom(fig);
p = pan(fig);
lh = PropListener();
z.ActionPostCallback = @Callbacks.ResizeElements;
p.ActionPostCallback = @Callbacks.ResizeElements;
lh.addListener(main_axes, 'XLim', 'PostSet', @Callbacks.ResizeElements);
lh.addListener(main_axes, 'YLim', 'PostSet', @Callbacks.ResizeElements);

% add contextmenu to save the fit results
cm = uicontextmenu;
main_axes.UIContextMenu = cm;
uimenu(cm, 'Label', 'save Figure', 'Callback', @Callbacks.SaveFigure);

%% erstelle data brush-object
h = brush(fig);
h.Enable = 'off';
h.ActionPostCallback = @Callbacks.DoFit;

%% erstelle Gui_Elements 
Gui_Elements.fig = fig;
Gui_Elements.main_axes = main_axes;

Gui_Elements.base = base;
Gui_Elements.axes_box = axes_box;
Gui_Elements.control_box = control_box;
Gui_Elements.btn_box = btn_box;

Gui_Elements.results_table = results_table;
Gui_Elements.new_fitrange_btn = new_fitrange_btn;
Gui_Elements.data_brush_btn = data_brush_btn;
Gui_Elements.reimport_data_btn = reimport_data_btn;
Gui_Elements.data_brush = h;

Gui_Elements.slide_panel_container = slide_panel_container;
Gui_Elements.slide_panel = slide_panel;
Gui_Elements.slide_btn = slide_btn;
Gui_Elements.slide_panel_vary_parameter_table = vary_parameter_table;
Gui_Elements.slide_panel_constant_parameter_table = constant_parameter_table;
Gui_Elements.slide_panel_extended_width = extended_width;
Gui_Elements.slide_panel_shrinked_width = shrinked_width;

%% erstelle Data 
Data.orig_line_object = orig_line_object;
Data.orig_line = [x_orig y_orig];
Data.fit_line_object = [];
Data.fit_line = [];
Data.fit_range_object = [];
Data.xoffset = [];
Data.yoffset = [];
Data.brushed_data = [];
Data.FR_left_border = [];
Data.FR_right_border = [];
Data.parameter.variable_parameter = vary_parameter;
Data.parameter.constant_parameter = constant_parameter;
Data.parameter.hold_parameter = hold_parameter;

%% l�schen unn�tiger Variablen
clearvars -except ForceCurves DataSelection savepath Data Gui_Elements
