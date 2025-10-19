%% clearing the workspace
clc, clearvars, close all;

%% getting all the song files

data_dir = "data";
database = containers.Map("KeyType","char", "ValueType", "any");

%find all .mp3 files
disp("Looking for the songs in the folder...");
song_files = dir(fullfile(data_dir,"*.mp3"));
if isempty(song_files)
    error("No songs found!");
end

num_songs = length(song_files);
fprintf("Found %d songs in the database\n", num_songs);

% Get the struct for the first song
first_song = song_files(1); 
% Combine its folder and name to get the full path
full_path = fullfile(first_song.folder, first_song.name);

fprintf("Now playing: %s\n", full_path);

% Read the audio file
[song, fs] = audioread(full_path);

% --- Fix 2 & 3: Use correct variable (fs) and add play() ---
% Create the player
player = audioplayer(song, fs); 

% Play the song
play(player);
