clear all 
close all

fig1 = figure(1);
fig1.Position = [100 100 200 150];

subplot(3,2,1)
plot([1:10],[1:10]);
subplot(3,2,2);
plot([2:5],[2:5]);
subplot(3,2,3);
plot([3:7],[3:7]);
subplot(3,2,4);
plot([4:12],[4:12]);
subplot(3,2,5);
plot([5:13],[5:13]);
subplot(3,2,6);
plot([6:17],[6:17]);

plot2pdf(fig1);

function plot2pdf(fig)
clear figure_property;
figure_property.units = 'points';
figure_property.format = 'pdf';
figure_property.Preview= 'none';
figure_property.Width= fig.Position(3); % Figure width on canvas
figure_property.Height= fig.Position(4); % Figure height on canvas
figure_property.Units= 'points';
figure_property.Color= 'rgb';
figure_property.Background= 'w';
figure_property.FixedfontSize= '12';
figure_property.ScaledfontSize= 'auto';
figure_property.FontMode= 'scaled';
figure_property.FontSizeMin= '12';
figure_property.FixedLineWidth= '1';
figure_property.ScaledLineWidth= 'auto';
figure_property.LineMode= 'none';
figure_property.LineWidthMin= '0.1';
figure_property.FontName= 'Times New Roman';
figure_property.FontWeight= 'auto';
figure_property.FontAngle= 'auto';
figure_property.FontEncoding= 'latin1';
figure_property.PSLevel= '3';
figure_property.Renderer= 'painters';
figure_property.Resolution= '600';
figure_property.LineStyleMap= 'none';
figure_property.ApplyStyle= '0';
figure_property.Bounds= 'tight';
figure_property.LockAxes= 'on';
figure_property.LockAxesTicks= 'on';
figure_property.ShowUI= 'off';
figure_property.SeparateText= 'off';
chosen_figure=fig;
set(chosen_figure,'PaperUnits','points');
set(chosen_figure,'PaperPosition',[0 0 figure_property.Width*96/72+10 figure_property.Height*96/72+10]);
set(chosen_figure,'PaperSize',[figure_property.Width figure_property.Height]); % Canvas Size
set(chosen_figure,'Units','points');

filename = input('<strong>Enter filename: </strong>','s');
outputFilename = sprintf('%s.pdf',filename);

hgexport(gcf,outputFilename,figure_property); %Set desired file name
end