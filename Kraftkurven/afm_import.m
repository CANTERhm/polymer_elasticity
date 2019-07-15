%file = 'C:\Users\Julian\Documents\MATLAB\Projekte\AFM_Daten_Beispiel\test-clamp-daten\processed_curves-2017.09.20-16.45.49\force-clamp-0000.txt';
[name,path,~] = uigetfile();
file = [path name];
a = afm(file, 0);  
% x = a.CurveData{1,1};
% y = a.CurveData{1,2};
% fig = figure('Name', 'test');
% plot(x,y);
