%% poymere_elasticity
% POLYMER_ELASTICITY This Program fits the freely jointed chain Model to a
% Dataset aquired from Force-Clamp-Events.
%   
%   For more inoformation see
%       - help entry in the "Polymer Elasticity" menu of polymer_elasticity
%       - Help.docx in polymer_elasticity/Help
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

%% create parameter
vary_parameter = Results();
constant_parameter = Results();
hold_parameter = Results();

vary_parameter.addproperty('Ks');
vary_parameter.addproperty('Lc');
vary_parameter.addproperty('lk');
vary_parameter.Ks = 28;
vary_parameter.Lc = 0.5e-6;
vary_parameter.lk = 5.4e-10;
vary_parameter.addproperty('cf_Ks');
vary_parameter.addproperty('cf_Lc');
vary_parameter.addproperty('cf_lk');
vary_parameter.cf_Ks = 28;
vary_parameter.cf_Lc = 0.5e-6;
vary_parameter.cf_lk = 5.4e-10;

constant_parameter.addproperty('T');
constant_parameter.addproperty('kb');
constant_parameter.T = 300;
constant_parameter.kb = 1.38e-23;

hold_parameter.addproperty('Ks');
hold_parameter.addproperty('Lc');
hold_parameter.addproperty('lk');
hold_parameter.Ks = true;
hold_parameter.Lc = false;
hold_parameter.lk = false;
hold_parameter.addproperty('cf_Ks');
hold_parameter.addproperty('cf_Lc');
hold_parameter.addproperty('cf_lk');
hold_parameter.cf_Ks = false;
hold_parameter.cf_Lc = true;
hold_parameter.cf_lk = false;


%% read data

if exist('DataSelection', 'var')
    x_orig = DataSelection(:,1);
    y_orig = DataSelection(:,2);
else
    x_orig = [];
    y_orig = [];
end
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
polymer_elasticity_menu = uimenu('Text', '&Polymer Elasticity');

% open Kraftkurven
open_kraftkurven_submenu = uimenu(polymer_elasticity_menu);
open_kraftkurven_submenu.Text = 'Open &Kraftkurven';
open_kraftkurven_submenu.Accelerator = 'K';
open_kraftkurven_submenu.MenuSelectedFcn = @Callbacks.LoadForceCurves;

% help
help_submenu = uimenu(polymer_elasticity_menu);
help_submenu.Text = '&Help';
help_submenu.Separator = 'on';
help_submenu.MenuSelectedFcn = @Callbacks.OpenHelpCallback;

%% create gui
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

%% gui settings
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
% button_container = uix.HButtonBox('Parent', dialog_container);
vary_parameter_container = uix.VBox('Parent', vary_parameter_panel);
constant_parameter_panel = uix.BoxPanel('Parent', dialog_container,...
    'Title', 'Constant Parameters');
constant_parameter_container = uix.VBox('Parent', constant_parameter_panel);
button_container = uix.HButtonBox('Parent', dialog_container);

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
button_container.ButtonSize = [150, 20];
do_fit_btn = uicontrol('Parent', button_container, 'Style', 'pushbutton',...
    'String', 'Do Fit',...
    'Callback', @Callbacks.DoFit);

% configure the dialog_container
dialog_container.Heights = [-1 -1 25];

%% slide-panel: cost function tab
cf_container = uix.VBox('Parent', slide_panel);
cf_panel = uix.BoxPanel('Parent', cf_container, 'Title', 'Cost Function Parameter');
cf_range_panel = uix.BoxPanel('Parent', cf_container, 'Title', 'Cost Function Parameter Ranges');
cf_parameter_container = uix.VBox('Parent',cf_panel);
cf_parameter_range_container = uix.VBox('Parent', cf_range_panel);
cf_edit_field_container = uix.HButtonBox('Parent', cf_container);
cf_button_container = uix.HButtonBox('Parent', cf_container);

% content of cost function parameter table

cost_function_data = {'Ks', vary_parameter.cf_Ks, 'N/m', hold_parameter.cf_Ks;...
    'Lc', vary_parameter.cf_Lc, 'm', hold_parameter.cf_Lc;...
    'lk', vary_parameter.cf_lk, 'm', hold_parameter.cf_lk};

cf_parameter_table = uitable(cf_parameter_container);
cf_parameter_table.RowName = {};
cf_parameter_table.ColumnName = {'Parameter', 'Value', 'Unit', 'hold?'};
cf_parameter_table.Data = cost_function_data;
cf_parameter_table.ColumnEditable = [false true false true];
cf_parameter_table.CellEditCallback = @Callbacks.CostFunctionHoldParameterCallback;

% content of cost function parameter range table
cost_function_range_data = {'Ks', 0, 2;...
    'Lc', 0, 2;...
    'lk', 0, 2};

cf_parameter_range_table = uitable(cf_parameter_range_container);
cf_parameter_range_table.RowName = {};
cf_parameter_range_table.ColumnName = {'Parameter', 'Lower Bound [%]', 'Upper Bound [%]'};
cf_parameter_range_table.Data = cost_function_range_data;
cf_parameter_range_table.ColumnEditable = [false true true];
cf_parameter_range_table.CellEditCallback = @Callbacks.CostFunctionRangeEditCallback;

% plot number edit field
cf_edit_field_container.HorizontalAlignment = 'right';
cf_edit_field_container.VerticalAlignment = 'middle';
cf_edit_field_container.ButtonSize = [150 20];

cf_plotnumber_text = uicontrol('Parent', cf_edit_field_container, 'Style', 'text',...
    'String', 'Plot Number:');
cf_plotnumber_edit = uicontrol('Parent', cf_edit_field_container, 'Style', 'edit',...
    'String', '1',...
    'Callback', @Callbacks.EditPlotNumberCallback);

% configuration of calculata cost function button
cf_button_container.HorizontalAlignment = 'right';
cf_button_container.VerticalAlignment = 'middle';
cf_button_container.ButtonSize = [150 20];
calc_cost_func_btn = uicontrol('Parent', cf_button_container, 'Style', 'pushbutton',...
    'String', 'Calculate Cost Function',...
    'Callback', @Callbacks.calculate_costfunction_btn_callback);

% configuration of cf_container
cf_container.Heights = [-1 -1 25 25];

%% settings of slide-panel
extended_width = 400;
shrinked_width = 20;

axes_box.Widths(1) = shrinked_width;
slide_panel_container.Widths = [-1 20];
slide_panel.TabTitles = {'Model', 'Cost Function'};
slide_panel.TabWidth = 100;

%% create main_axes 
main_axes = axes(axes_box);
main_axes.Tag = 'main_axes';
xlabel('vertical tip position / m');
ylabel('vertical deflection / N')
if ~isempty(x_orig) || ~isempty(y_orig)
    orig_line_object = plot(main_axes, x_orig, y_orig, 'b.',...
        'ButtonDownFcn', @Callbacks.SetStartPoint);
else
    orig_line_object = [];
end
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

%% create data brush-object
h = brush(fig);
h.Enable = 'off';
h.ActionPostCallback = @Callbacks.DoFit;

%% create Gui_Elements 
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
Gui_Elements.slide_panel_do_fit_btn = do_fit_btn;
Gui_Elements.slide_panel_cf_parameter_table = cf_parameter_table;
Gui_Elements.slide_panel_cf_parameter_range_table = cf_parameter_range_table;
Gui_Elements.slide_panel_cf_plotnumber_edit = cf_plotnumber_edit;
Gui_Elements.slide_panel_cf_calc_cost_func_btn = calc_cost_func_btn;
Gui_Elements.slide_panel_extended_width = extended_width;
Gui_Elements.slide_panel_shrinked_width = shrinked_width;

%% create Data 
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
Data.cf_plotnumber = 1;
Data.cf_parameter_range = [0 2; 0 2; 0 2];
Data.cf_surf_object = [];
Data.cf_surf_data = [];
Data.cf_refined_surf_object = [];
Data.cf_refined_surf_data = [];
Data.parameter.variable_parameter = vary_parameter;
Data.parameter.constant_parameter = constant_parameter;
Data.parameter.hold_parameter = hold_parameter;

%% delete unnecessary variables
clearvars -except ForceCurves DataSelection savepath Data Gui_Elements
