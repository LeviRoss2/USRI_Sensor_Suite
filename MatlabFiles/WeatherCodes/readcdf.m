clear all
close all

[baseFileName, folder] = uigetfile({'*.xlsx;*.xlsm;*.csv'}, 'Select a Flight Data file');
if baseFileName == 0
    % User clicked the Cancel button.
    return;
end
% Get the name of the input .mat file.
fullInputMatFileName = fullfile(folder, baseFileName);
    
    ncid=netcdf.open(file)
    ncdisp(file)
    data.alt=ncread(file,'alt');
    data.pres=ncread(file,'pres');
    data.time=ncread(file,'time');
    data.u=ncread(file,'u');
    data.v=ncread(file,'v');
    data.mag=ncread(file,'speed');
    data.mag=ncread(file,'dir');
    
    netcdf.close(ncid)
    
    figure(1)
    plot(data.mag,data.alt,'o')
    hold on
    plot(data.u,data.alt,'x')
    plot(data.v,data.alt,'d')
    hold off
    
    %size(thdata)
   
    