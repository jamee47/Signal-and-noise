%% clearing the workspace
clc, clearvars, close all;

%% checking for dependencies

try 
    ver('signal');
    ver('image');
catch
    error("The script requires signal and image processign toolbox");
end

%% configuring the parameters

