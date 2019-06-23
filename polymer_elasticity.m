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

%% daten einlesen
clearvars -except ForceCurves DataSelection savepath

x_orig = DataSelection(:,1);
y_orig = DataSelection(:,2);
FR_relative_border = [0.95 1];
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
results_table.ColumnWidth = num2cell(75.*ones(1,length(results_table.ColumnWidth)));

% %initiale breite der Spalten 
column_num = length(results_table.ColumnName); % Anzahl der spalten
overall_content_width = results_table.Extent(3); % gesamtbreite der tabelle
column_width = results_table.ColumnWidth{1}; % breite der spalten f�r parameter (insgesamt 7 parameter)
row_name_width = overall_content_width-column_num*column_width; % breite der spalte mit Zeilennamen

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
vary_parameter_container = uix.VBox('Parent', vary_parameter_panel);
constant_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Konstante Parameter');
constant_parameter_container = uix.VBox('Parent', constant_parameter_panel);

% inhalt vary_parameter_container

vary_data = {28, 'N/m', true; 0.5e-6, 'm', false; 5.4e-10, 'm', true};

vary_parameter_table = uitable(vary_parameter_container);
vary_parameter_table.ColumnName = {'Wert', 'Einheit', 'fixieren?'};
vary_parameter_table.RowName = {'Ks', 'Lc', 'lk'};
vary_parameter_table.Data = vary_data;
vary_parameter_table.ColumnEditable = [true false true];

% inhalt constant_parameter_container

constant_data = {1.38e-23, 'J/K'; 300, 'K'};

constant_parameter_table = uitable(constant_parameter_container);
constant_parameter_table.ColumnName = {'Wert', 'Einheit'};
constant_parameter_table.RowName = {'kb', 'T'};
constant_parameter_table.Data = constant_data;
constant_parameter_table.ColumnEditable = [true false];

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

%% erstelle axes f�r den Fit
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
title('W�hle Nullpunkt des Abrisses');
xlabel('vertical tip position / m');
ylabel('vertical deflection / N')
grid on
grid minor

%% erstelle data brush-object
h = brush(fig);
h.Enable = 'off';
h.ActionPostCallback = @Callbacks.DoFit;

%% erstelle Gui_Elements 
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

%% erstelle Data 
Data.orig_line = [x_orig y_orig];
Data.FR_relative_border = FR_relative_border;
Data.parameter.variable_data = vary_data;
Data.parameter.constant_data = constant_data;

%% l�schen unn�tiger Variablen
clearvars -except ForceCurves DataSelection savepath Data Gui_Elements
