%% poymere_elasticity
% Es muss die Variable "DataSelection" im Workspace vorhanden sein, bevor
% das Skirpt gestartet wird. "DataSelection" kann am einfachsten über die
% App "Kraftkurven" erstellt werden.
% DataSeletion: nx2 Vektor mit x, y koordinaten von Datenpunkten 
%   - DataSelection(:,1): x-koordinaten
%   - DataSelection(:,2): y-koordinaten
%
% Für eine Detailierte Anleitung siehe den Hilfe Tab im Slide-Menü von
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
hold_parameter.Ks = true;
hold_parameter.Lc = true;
hold_parameter.lk = false;

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
    g = groot;
    fig = figure();
    fig.NumberTitle = 'off';
    fig.Name = 'Polymer Elasticity';
    fig.Tag = 'polymer_elasticity';
    
    % calculate figure size depending on screen size of the primary screen
    s = g.ScreenSize;
    fig.Position = [s(3)/5 s(4)/4 s(3)/1.5 s(4)/1.5];
else
    g = groot;
    set(g, 'CurrentFigure', fig);
    clf;
end

fig.SizeChangedFcn = @Callbacks.TableResizeCallback;

% avoid closing polymer_elasticity by Kraftkurven
fig.UserData.EditRequest = false;

%% create menu
load_curves_menu = uimenu('Text', '&Load Force-Curves');
open_kraftkurven_submenu = uimenu(load_curves_menu);
open_kraftkurven_submenu.Text = 'Open &Kraftkurven';
open_kraftkurven_submenu.Accelerator = 'K';
open_kraftkurven_submenu.MenuSelectedFcn = @Callbacks.LoadForceCurves;

%% erstelle gui
base = uix.VBox('Parent', fig);
axes_box = uix.HBox('Parent', base);
control_box = uix.VBox('Parent', base);
btn_box = uix.HBox('Parent', control_box, 'Spacing', 10);
results_table = uitable(control_box);
results_table_2 = uitable(control_box);

reimport_data_btn = uicontrol('Parent', btn_box, 'Style', 'pushbutton',...
    'String', 'Reimport DataSelection',...
    'Callback', @Callbacks.reimport_data_btn_callback);
data_brush_btn = uicontrol('Parent', btn_box, 'Style', 'togglebutton',...
    'String', 'New Fitrange',...
    'Callback', @Callbacks.data_brush_btn_callback);
new_fitrange_btn = uicontrol(btn_box, 'Style', 'pushbutton',...
    'String', 'Delete Fitrange',...
    'Callback', @Callbacks.new_fitrange_btn_callback);

%% gui einstellungen
base.Heights = [-3.5 -1];
base.Padding = 5;
control_box.Heights = [20 -1 -1];
control_box.Spacing = 10;
axes_box.Padding = 0;
axes_box.Spacing = 0;

%% columnnames for results_table
results_table.ColumnName = {'Ks Fit', 'Lc Fit', 'lk Fit', 'Rupture Length'};
results_table.RowName = {};
resutls_tabel.Data = {0, 0, 0, 0};

% calculate ColumnWidth
g = groot;
table_width = g.ScreenSize(3)/4;
col_num = length(results_table.ColumnName);
col_width = floor(table_width/col_num);
results_table.ColumnWidth = {col_width};

%% columnnames for results_table_2
results_table_2.ColumnName = {'xoffset', 'yoffset', 'Xl', 'Xr', 'Distance'};
results_table_2.RowName = {};
results_table_2.Data = {nan, nan, nan, nan};

results_table_2.ColumnEditable = [true true true true, false]; 
results_table_2.CellEditCallback = @Callbacks.UpdateFitParameterCallback;

% calculate ColumnWidth
g = groot;
table_width = g.ScreenSize(3)/4;
col_num = length(results_table_2.ColumnName);
col_width = floor(table_width/col_num);
results_table_2.ColumnWidth = {col_width};

%% create slide-panel 
% das slide_panel ist eine die erste spalte der axes_box. Diese wird belegt
% mit einer neuen HBox, dessen breite über den Slide-btn varriert werden
% kann. so wird das "Slide" verhalten erzeugt
slide_panel_container = uix.HBox('Parent', axes_box);
slide_panel = uix.TabPanel('Parent', slide_panel_container);
slide_btn = uicontrol('Parent', slide_panel_container, 'Style', 'togglebutton',...
    'String', '>>',...
    'Callback', @Callbacks.SlidePanelResizeCallback);

%% slide-panel: modelparameter-tab
dialog_container = uix.VBox('Parent', slide_panel);
vary_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Variable Parameters');
button_container = uix.HButtonBox('Parent', dialog_container);
vary_parameter_container = uix.VBox('Parent', vary_parameter_panel);
constant_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Constant Parameters');
constant_parameter_container = uix.VBox('Parent', constant_parameter_panel);

% content of vary_parameter_container

vary_data = {'Ks', vary_parameter.Ks, 'N/m', hold_parameter.Ks;...
            'Lc', vary_parameter.Lc, 'm', hold_parameter.Lc;...
            'lk', vary_parameter.lk, 'm', hold_parameter.lk};

vary_parameter_table = uitable(vary_parameter_container);
vary_parameter_table.ColumnName = {'Parameter', 'Value', 'Unit', 'hold?'};
vary_parameter_table.RowName = {};
vary_parameter_table.Data = vary_data;
vary_parameter_table.ColumnEditable = [false true false true];
vary_parameter_table.CellEditCallback = @Callbacks.UpdateVaryParameterCallback;

% content of constant_parameter_container

constant_data = {'kb', constant_parameter.kb, 'J/K';...
                'T', constant_parameter.T, 'K'};

constant_parameter_table = uitable(constant_parameter_container);
constant_parameter_table.ColumnName = {'Parameter', 'Value', 'Unit'};
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

general_panel = uix.BoxPanel('Parent', help_container, 'Title', 'General');
general_container = uix.VBox('Parent', general_panel);
userguide_panel = uix.BoxPanel('Parent', help_container, 'Title', 'User Guide');
userguide_container = uix.VBox('Parent', userguide_panel);
other_panel = uix.BoxPanel('Parent', help_container, 'Title', 'Miscellaneous');
other_container = uix.VBox('Parent', other_panel);
terminology_panel = uix.BoxPanel('Parent', help_container, 'Title', 'Terminology');
terminology_container = uix.VBox('Parent', terminology_panel);

% content general_container
str = {['The purpose of polymer_elasticity is the evaluation of Clamp-Events ' ...
    'of Force-Curves (Force vs. Distance) recorded in Force-Clamp-Experiments.' ...
    'Those Clamp-Events were fitted via the "extended freely jointed Chain" Model:'],...
    'Lc*[coth(x)-1/s]*(1+F/(Ks*lk)) were x = F*lk/(kb*T)'};
UtilityFunctions.textLine(general_panel, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% content userguide_container
str = '1. Selection of a Clamp-Event';
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['To determine the beginning of a Clamp-Event left-click the Graph at the ' ...
    'Startpoint of the Event. If the Selection was succesful, a dashed black ' ...
    'Crosshair would appear.']};
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = '2. Selection of a Fitrange';
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');

str = {['To choose the Fitrange, left-click the Button called "New Fitrange" ' ...
    'and the Cursor changes to a small, black Crosshair. Drag a red rectangle ' ...
    'around the region of interest with the pressed, left Mousbutton. If the selection ' ...
    'was successful, the Fit would start automatically and appear on the Figure as a red Line. The ' ...
    'chosen Fitrange will also apear as a grey Area.']};
UtilityFunctions.textLine(userguide_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% content of other_container
str = 'Load New Data';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['If the Data in the Variable "DataSelection" changed, it would be possible to ' ...
    'reimport the Data to polymer_elasticity, by pressing the Button called "Reimport DataSelection". ' ...
    'Thereafter the new Graph will apear in the Figure. All Offsets, Fitranges and Fitrepresentations will be deleted']};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Delete Fitrange';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['To delete the actual Fitrange press the Button "Delete Fitrange". This will only ' ...
    'delete the Fitrange and the Fitrepresentation. All Offsets remain unchanged.']};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Save Figure Elements';
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['To get a "good loking" version of the Elements in the Figure, right-click on the white ' ...
    'Background of the Figure. In the Contextmenu choose "Save Figure" and the plottools will ' ...
    'open.']};
UtilityFunctions.textLine(other_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% content of terminology container
str = 'Ks Fit';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['Means the fitted Segment Elasticity of the investigated ' ...
    'Molecule.']};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Lc Fit';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['Means the fitted Contourlength of the investigated ' ...
    'Molecule.']};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'lk Fit';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['Means the fitted Kuhnlength of the investigated ' ...
    'Molecule.']};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Rupture Length';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {['"Lc Fit" + x-offset; means the Position of the ' ...
    'Rupture Event in the Coordinate System.']};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Xl';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {'Left Border of the Fitrange in %.'};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Xr';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {'Right Border of the Fitrange in %.'};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

str = 'Distance';
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'bold',...
    'horizontalAlignment', 'left');
str = {'Distance between Xl and Xr (Xr-Xl) in %.'};
UtilityFunctions.textLine(terminology_container, str,...
    'fontAngle', 'normal',...
    'fontWeight', 'normal',...
    'horizontalAlignment', 'left');

% hilfe-tab einstellungen
help_panel.MinimumHeights = 1045;
help_panel.MinimumWidths = 300;

help_container.Heights = [115 260 270 400];
userguide_container.Heights = [15 -1 15 -1];
other_container.Heights = [15 -1 15 -1 15 -1];
terminology_container.Heights = [15 -1 15 -1 15 -1 15 -1 15 -1 15 -1 15 -1];

%% settings of slide-panel
extended_width = 400;
shrinked_width = 20;

axes_box.Widths(1) = shrinked_width;
slide_panel_container.Widths = [-1 20];
slide_panel.TabTitles = {'Modelparameter', 'Help'};
slide_panel.TabWidth = 100;

%% erstelle main_axes für den Fit
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
uimenu(cm, 'Label', 'Save Figure', 'Callback', @Callbacks.SaveFigure);

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
Gui_Elements.results_table_2 = results_table_2;
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
Data.A_bl_range = [];
Data.orig_line_object = orig_line_object;
Data.orig_line = [x_orig y_orig];
Data.fit_line_object = [];
Data.fit_line = [];
Data.fit_range_object = [];
Data.offsets_from_table = false;
Data.xoffset = [];
Data.yoffset = [];
Data.brushed_data = [];
Data.borders_from_table = false;
Data.FR_left_border = [];
Data.FR_right_border = [];
Data.parameter.variable_parameter = vary_parameter;
Data.parameter.constant_parameter = constant_parameter;
Data.parameter.hold_parameter = hold_parameter;

%% löschen unnötiger Variablen
clearvars -except ForceCurves DataSelection savepath Data Gui_Elements
