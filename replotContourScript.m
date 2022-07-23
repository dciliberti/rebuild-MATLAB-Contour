% replotContourScript
% This MATLAB script reads a .dat file, which may be the output of the
% native MATLAB contour function. The input .dat file is loaded by a
% selection dialog box. The file content has to be a numerical array of
% (2 x n), that is 2 rows by n columns, containing the coordinates of the
% iso-lines. If the array is transposed (n x 2), this script will
% automatically transpose it to the correct form (2 x n).
%
% Please, define your axes limits and labels before running this script.
%
% The script will attempt to rebuild the contour plot coordinates by
% interpolating between the available iso-lines. As output, it will provide
% a table (not a MATLAB Table, something more closer to what you may find
% in a spreadsheet table) with the interpolated X and Y coordinates as
% first column and first row respectively, and Z values. Also, it will
% replot the contour in three different modes:
%
%   Figure 1: only black iso-lines
%   Figure 2: the native MATLAB contourf function
%   Figure 3: a top-view of the native MATLAB surf function with
%   smooth colors and overlapped black iso-lines
%
% All the contours plot are labeled with the original values of the source
% iso-lines. However, during the execution the script will ask you for a
% new baseline value, if any. This is useful if you just want to translate
% your Z values, for instance if you need to edit the original contour
% chart and provide a new contour in terms of delta values instead of
% absolute values. The iso-lines distribution will not change, but the
% labels will be updated. You can ignore this feature (leaving the field 
% empty will not generate an error and will assume your baseline is zero, 
% i.e. no alteration of the Z values will be provided) or you may comment 
% that part of the code, if it is annoying.
%
% I've also added additional commands to rewrite negative numbers with the
% correct minus sign, instead of the default hyphen. This is very useful if
% you have to publish your charts and the editor asks you to replace hyphens
% with minus. This feature will save you a lot of time. Unfortunately I am
% not able to update the minus sign on the native contour plot labels, as
% numbers seem to be stored in a numeric array, not in a string, being written
% on the plot at the generation of the contour (and there is no property
% available to edit them). Nonetheless, the hyphen-minus replacement works
% well in Figure 1 and Figure 3.
%
% This script makes also use of the third part function C2xyz, which should
% be retrived from the official link:
% https://it.mathworks.com/matlabcentral/fileexchange/43162-c2xyz-contour-matrix-to-coordinates
%
% Known issues: to get a high-quality figure, the plot renderer is forced
% to be painters, that is vectorial. However, in doing so, the labels in 
% Figure 3 will be overlapped by the iso-lines, no matter when the renderer
% is called. To fix this, the statement
%
%   set(gcf,'Renderer','painters');
%
% should be commented, or the figure should be saved as .svg and manually
% edited later.
%
%
%    Copyright (C) 2022  Danilo Ciliberti danilo.ciliberti@unina.it
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <https://www.gnu.org/licenses/>.

close all; clearvars; clc;

% Read contour data from .dat file
[fileName, filePath] = uigetfile('.dat','Select data file to plot contour...');
data = load([filePath,'\',fileName]);

% Please specify a grid for your plot and your labels
myx = -0.1:0.1:0.1;
myy = -0.1:0.05:0.05;
myxLabel = '\DeltaX/c';
myyLabel = '\DeltaZ/c';

% Transpose contour matrix if necessary (it has to be 2 x n)
if size(data,1) > 2
    C = data';
else
    C = data;
end

% Use third part function C2xyz to transform contour matrix into [x,y,z]
% https://it.mathworks.com/matlabcentral/fileexchange/43162-c2xyz-contour-matrix-to-coordinates
[x,y,z] = C2xyz(C);

%% Plot section

% Edit Z data (I want relative values with respect to a baseline)
temp = inputdlg('Enter baseline value (if any):');
baselineVal = str2double(temp{:});
if isnan(baselineVal)
    baselineVal = 0;
end
oldZ = z;
z = z - baselineVal;

% Interpolate data to rebuild contour plot
X = cell2mat(x);
Y = cell2mat(y);
% Xlin = linspace(min(X),max(X),1000);
% Ylin = linspace(min(Y),max(Y),1000);
Xlin = linspace(min(myx),max(myx),100);
Ylin = linspace(min(myy),max(myy),100);
Z = [];
for n = 1:length(z)
    temp = repmat(z(n),1,length(x{n}));
    Z = [Z, temp];
end
[XX, YY] = meshgrid(Xlin,Ylin);
% ZZ = griddata(X,Y,Z,XX,YY);
F = scatteredInterpolant(X(:),Y(:),Z(:)); % scatteredInterpolant provides extrapolation, while griddata does not
ZZ = F(XX,YY);

% Tabular data (you may want to interpolate at specific points)
[myX,myY] = meshgrid(myx,myy);
myZ = F(myX,myY);
disp('Interpolated data at specific coordinates')
disp([NaN, myx; myy', myZ])

% Plot 'fake' contour as lines plot
figure, hold on
for n = 1:length(z)
    plot(x{n},y{n},'k','LineWidth',2)
end
hold off, grid on
xlim([min(myx),max(myx)]), ylim([min(myy),max(myy)])%, yticks(-0.1:0.01:0.05)
clabel(C,oldZ)
xlabel(myxLabel), ylabel(myyLabel), title(fileName,'Interpreter','none')
% set(gca,'xdir','reverse');
% Update contour labels
temp = findobj(gca,'Type','Text');
for i = 1:length(temp)
    temp(i).String = num2str(z(i),3);
    temp(i).String = strrep(temp(i).String,'-','−');
end
set(temp,'BackgroundColor','white')


% Plot rebuilt contour
figure
[CCnew,h] = contourf(XX,YY,ZZ);
xlim([min(myx),max(myx)]), ylim([min(myy),max(myy)])%, yticks(-0.1:0.01:0.05)
clabel(CCnew,h)
xlabel(myxLabel), ylabel(myyLabel), title(fileName,'Interpreter','none')
% set(gca,'xdir','reverse');
% Sorry I do not know how to change the hyphen signs to minus signs in contour labels


% Plot interpolated color surface from top view
figure
p = surf(XX,YY,ZZ);
set(p, 'edgecolor','none');
xlim([min(myx),max(myx)]), ylim([min(myy),max(myy)])%, yticks(-0.1:0.01:0.05)
view([0,90]), colorbar
xlabel(myxLabel), ylabel(myyLabel), title(fileName,'Interpreter','none')
% set(gca,'xdir','reverse');
set(gcf,'Renderer','painters'); % force rendering to be in vector format (https://it.mathworks.com/matlabcentral/answers/363832-some-figures-not-saving-as-vector-graphics-svg)
% Add labels and move them on top plane
hold on
zmax = max(max(ZZ));
for n = 1:length(z)
    plot3(x{n},y{n},ones(1,length(x{n}))*zmax,'k','LineWidth',2)
end
hold off
tag = clabel(C,oldZ);
temp = findobj(tag,'Type','Line');
set(temp,'ZData',zmax)
temp = findobj(tag,'Type','Text');
for i = 1:length(temp)
    temp(i).Position(3) = zmax;
    temp(i).String = num2str(z(i),3);
    temp(i).String = strrep(temp(i).String,'-','−');
end
set(temp,'BackgroundColor','white')

%% Change hyphen signs to minus signs in all figures

figs = findobj('Type','Figure');
for j = 1:length(figs)
    ax = figs(j).CurrentAxes;
    ax.TickLabelInterpreter = 'tex';
    xticklabels(ax,strrep(xticklabels(ax),'-','−')) % the second is a minus sign from Windows Characters Map
    yticklabels(ax,strrep(yticklabels(ax),'-','−')) % the second is a minus sign from Windows Characters Map
end
% Colorbar only on final plot
cb = colorbar();
cb.TickLabels = strrep(cb.TickLabels, '-', '−');
