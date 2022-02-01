% iMet_table = parsedVars{3,2};
% 
% timer - iMEt_table time in seconds
% cAnim1 - iMet Temp column
% cAnim2 - Imet Humidity column
% cAnim3 - Barometric Pressure
% 
% xAnim - LAT (GPS)
% yAnim - LON (GPS)
% zAnim - ALT (GPS)


%% Animation Setup
animVid = VideoWriter('Kessler 8-4-2020, TriplePlot','MPEG-4'); %open video file
animVid.FrameRate = 20;  %can adjust this, 5 - 10 works well for me
animVid.Quality = 100;

interval = 20;

% Convert labels for here
timer = table2array(BARO_table(1:2:8597-3,3));
cAnim1 = [nan;table2array(TPH_table(1:2:end,6))];
cAnim2 = [nan;table2array(TPH_table(1:2:end,9))];
cAnim3 = [nan;table2array(BARO_table(1:2:8597-3,4))];
xAnim=[nan;table2array(GPS_table(1:4297,6))];
yAnim=[nan;table2array(GPS_table(1:4297,7))];
zAnim=[nan;table2array(GPS_table(1:4297,9))];
lx = length(xAnim);
ly = length(yAnim);
lz = length(zAnim);
% Stop Changing after

fig10 = figure(10);
fig10.Position = [360 380 1180 400];
%% Temperature Plot %%%%%%%%%%%%%
subplot(1,3,1);
ax1 = gca;
title('Temperature (°C)');
xlim(ax1, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
ylim(ax1, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
zlim(ax1, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
view(ax1, 3)
grid on
zl = zlabel('Altitude (m, AGL)');
xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
xtickformat('%.3f')
ytickformat('%.3f')
ztickformat('%.0f')
set(ax1,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

data_range1 = ceil(max(max(cAnim1(2:end)))) - floor(min(min(cAnim1(2:end)))) + 1;
colormap(jet(data_range1*10));
caxis([min(min(cAnim1(2:end))) max(max(cAnim1(2:end)))])
cbh1 = colorbar();
cbh1.Ticks = round(min(min(cAnim1(2:end))):((max(max(cAnim1(2:end)))-min(min(cAnim1(2:end))))/5):max(max(cAnim1(2:end))),0);
ticks1 = strsplit(num2str(cbh1.Ticks));
ax01 = axes('Position', cbh1.Position);
edges1 = linspace(0,1,numel(ticks1)+1);
centers1 = edges1(2:end)-((edges1(2)-edges1(1))/2);
text(ones(size(centers1))*0.5, centers1, ticks1, 'FontSize', cbh1.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
ax01.Visible = 'off';   %turn off new axes
cbh1.Ticks = [];
%% Humidity Plot %%%%%%%%%%%%%
subplot(1,3,2);
ax2 = gca;
title('Relative Humidity (%)');
xlim(ax2, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
ylim(ax2, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
zlim(ax2, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
view(ax2, 3)
grid on
xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
xtickformat('%.3f')
ytickformat('%.3f')
ztickformat('%.0f')
set(ax2,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

data_range2 = ceil(max(max(cAnim2(2:end)))) - floor(min(min(cAnim2(2:end)))) + 1;
colormap(jet(data_range2*10));
caxis([min(min(cAnim2(2:end))) max(max(cAnim2(2:end)))])
cbh2 = colorbar();
cbh2.Ticks = round(min(min(cAnim2(2:end))):((max(max(cAnim2(2:end)))-min(min(cAnim2(2:end))))/5):max(max(cAnim2(2:end))),1);
ticks2 = strsplit(num2str(cbh2.Ticks));
ax02 = axes('Position', cbh2.Position);
edges2 = linspace(0,1,numel(ticks2)+1);
centers2 = edges2(2:end)-((edges2(2)-edges2(1))/2);
text(ones(size(centers2))*0.5, centers2, ticks2, 'FontSize', cbh2.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
ax02.Visible = 'off';   %turn off new axes
cbh2.Ticks = [];
%% Pressure Plot %%%%%%%%%%%%%
subplot(1,3,3);
ax3 = gca;
title('Pressure (mbar)');
xlim(ax3, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
ylim(ax3, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
zlim(ax3, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
view(ax3, 3)
grid on
xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
xtickformat('%.3f')
ytickformat('%.3f')
ztickformat('%.0f')
set(ax3,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

data_range3 = ceil(max(max(cAnim3(2:end)))) - floor(min(min(cAnim3(2:end)))) + 1;
colormap(jet(data_range3*10));
caxis([min(min(cAnim3(2:end))) max(max(cAnim3(2:end)))])
cbh3 = colorbar();
cbh3.Ticks = round(min(cAnim3(2:end)):((max(cAnim3(2:end))-min(cAnim3(2:end)))/5):max(cAnim3(2:end)),1);
ticks3 = strsplit(num2str(cbh3.Ticks));
ax03 = axes('Position', cbh3.Position);
edges3 = linspace(0,1,numel(ticks3)+1);
centers3 = edges3(2:end)-((edges3(2)-edges3(1))/2);
text(ones(size(centers3))*0.5, centers3, ticks3, 'FontSize', cbh3.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
ax03.Visible = 'off';   %turn off new axes
cbh3.Ticks = [];
%% Position Control
subfig = get(gcf,'children');
set(subfig(1),'position',[.98 -.115 0 2.1]);  % Pressure color bar labels
%set(subfig(1),'position',[0.98 0.19 0 .62]);
set(subfig(2),'position',[.97 .2125 .02 .58]);     % Pressure color bar
set(subfig(3),'position',[.7025 .06 .265 .88]);    % Pressure mian plotting area
set(subfig(4),'position',[.6545 0.19 0 .62]);   % Humidity color bar labels
set(subfig(5),'position',[.645 .2125 .02 .58]);      % Humidity color bar
set(subfig(6),'position',[.3775 .06 .265 .88]);   % Humidity main plotting area
set(subfig(7),'position',[.33 0.19 0 .62]);   % Temperature color bar labels
set(subfig(8),'position',[.32 .2125 .02 .58]);      % Temperature color bar
set(subfig(9),'position',[.053 .06 .265 .88]);    % Temperature main plotting area

view(subfig(3),-45,20);
view(subfig(6),-45,20);
view(subfig(9),-45,20);

AnimPos = [.025 .88 .09 .1];
zl.Position = [34.9796 -97.51672 744.2306];
%% Set Axis Colors
ax1.ZTickLabel(1) = {'0'};
ax2.ZTickLabel(1) = {'0'};
ax3.ZTickLabel(1) = {'0'};

for i=1:length(ax1.XTickLabel)
    ax1.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax1.XTickLabel{i}];
    ax2.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax2.XTickLabel{i}];
    ax3.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax3.XTickLabel{i}];
end
for j=1:length(ax1.YTickLabel)
    ax1.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax1.YTickLabel{j}];
    ax2.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax2.YTickLabel{j}];
    ax3.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax3.YTickLabel{j}];
end
for k=1:length(ax1.ZTickLabel)
    ax1.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax1.ZTickLabel{k}];
    ax2.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax2.ZTickLabel{k}];
    ax3.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax3.ZTickLabel{k}];
end

ax1.XTickLabel(i) = {' '};
ax2.XTickLabel(i) = {' '};
ax3.XTickLabel(i) = {' '};
ax1.YTickLabel(j) = {' '};
ax2.YTickLabel(j) = {' '};
ax3.YTickLabel(j) = {' '};

zl.Color = 'k';
%% Animation Function
open(animVid);
for jj=1:interval:length(xAnim);
    try
        p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim1(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
        p2 = patch(ax2,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim2(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
        p3 = patch(ax3,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim3(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
        
        delete(findall(fig10,'type','annotation'));
        Seconds = floor(mod(timer(jj,1),60));
        Minutes = fix(timer(jj,1)/60);
        
        if(Seconds<10)
            String = {sprintf('Time (min:sec)\n%.0f:0%.0f',Minutes,Seconds)};
        else
            String = {sprintf('Time (min:sec)\n%.0f:%.0f',Minutes,Seconds)};
        end
        annotation(fig10,'textbox',AnimPos,'String',String,'HorizontalAlignment','center','VerticalAlignment','middle');
        
        
        pause(1/50); %Pause and grab frame
        frame = getframe(gcf); %get frame
        writeVideo(animVid, frame);
        cla(ax1);
        cla(ax2);
        cla(ax3);
    catch
        pause(1/50); %Pause and grab frame
        frame = getframe(gcf); %get frame
        writeVideo(animVid, frame);
        close(animVid);
        break
        
    end
end
close(animVid);
