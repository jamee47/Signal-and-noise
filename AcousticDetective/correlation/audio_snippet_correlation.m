%% clearing the workspace
clc, clearvars, close all;
%% setting the parameters
n_overlap = 512;
n_fft = 1024;
window = hanning(n_fft); % Window length is based on n_fft
data_dir = "../data";
snippet_dur = 30; %sec

%% Find all songs
disp("Looking for songs in the database...");
song_files = dir(fullfile(data_dir,"*.mp3"));
if isempty(song_files)
    error("No songs found in '%s' folder!", data_dir);
end
num_songs = length(song_files);
fprintf("Found %d songs in the database\n", num_songs);

%% Create a snippet from a RANDOM song
% Pick a random song to create the snippet from
rand_song_idx = randi(num_songs);
snippet_song_file = song_files(rand_song_idx);
snippet_song_path = fullfile(snippet_song_file.folder, snippet_song_file.name);

fprintf("\n--- Creating a 30s snippet from: %s ---\n", snippet_song_file.name);

% Read the random song
[song_orig, fs_orig] = audioread(snippet_song_path);
fs = fs_orig; % Use this file's native sample rate for everything
song_mono = mean(song_orig, 2);

% Get snippet from this song
snippet_len = snippet_dur * fs;
start_pos = randi(length(song_mono) / 2);
end_pos = start_pos + snippet_len;
if end_pos > length(song_mono)
    end_pos = length(song_mono);
end
snippet = song_mono(start_pos:end_pos);

start_time_audio = round(start_pos/fs);
fprintf("Snippet's true audio start time: %d s\n", start_time_audio);
sound(snippet,fs);

%% Calculate the snippet's spectrogram (the "template")
[s_snippet, f_snippet, t_snippet] = spectrogram(snippet, window, n_overlap, n_fft, fs);
s_snippet_mag = abs(s_snippet);

% Plot the snippet in Figure 1
figure(1);
imagesc(t_snippet, f_snippet, 20*log10(s_snippet_mag));
axis xy;
xlabel('Time (s)');
ylabel('Frequency (Hz)');
colormap('gray'); colorbar;
title(['Snippet from: ', snippet_song_file.name], 'Interpreter', 'none');
drawnow; % Ensure plot updates

%% Loop, Plot, and Correlate all songs
fprintf("\n--- Analyzing all songs in database ---\n");

% We need to store info about the best match
best_match_idx = 0;
max_peak_val = -Inf; % Start with negative infinity
best_peak_loc = [0, 0]; % Will store [ypeak, xpeak]
best_match_f = []; % Will store F vector for the match
best_match_t = []; % Will store T vector for the match
tic
for i = 1:num_songs
 
    current_song_file = song_files(i);
    current_song_path = fullfile(current_song_file.folder, current_song_file.name);
    fprintf("Analyzing (%d/%d): %s\n", i, num_songs, current_song_file.name);
    
    % --- Read and process the song ---
    [song_orig, fs_orig_current] = audioread(current_song_path);
    
    % --- Sanity Check ---
    if fs_orig_current ~= fs
        warning('Sample rate mismatch! %s (%.0f Hz) vs snippet (%.0f Hz). Skipping.', ...
                current_song_file.name, fs_orig_current, fs);
        continue; % Skip this song
    end
    
    song_mono = mean(song_orig, 2);
    
    % --- Calculate full spectrogram ---
    [s, f, t] = spectrogram(song_mono, window, n_overlap, n_fft, fs);
    s_mag = abs(s);
    
    % --- Plot this song's spectrogram ---
    figure(i + 1); % We use figure 'i+1' because '1' is the snippet

    % --- NEW: Create subplot 1 for the spectrogram ---
    subplot(2, 1, 1);
    imagesc(t, f, 20*log10(s_mag));
    axis xy;
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    colormap('gray'); colorbar;
    title(current_song_file.name, 'Interpreter', 'none'); 

    % --- Run 2D cross-correlation ---
    c = normxcorr2(s_snippet_mag, s_mag);

    % --- NEW: Create subplot 2 for the correlation plot ---
    subplot(2, 1, 2);
    imagesc(c); % Plot the correlation surface
    axis equal off; % Use equal axes and turn them off for a cleaner look
    colormap('gray'); colorbar; % 'hot' colormap shows the peak well
    title(sprintf('Normalized Cross-Correlation (Peak: %.4f)', max(c(:))));
 

    drawnow; % Update the plot window
    
    % Find peak
    [peak_val, imax] = max(c(:));
    fprintf("  Peak correlation: %.4f\n", peak_val);
    
    % --- Check if this is the new best match ---
    if peak_val > max_peak_val
        max_peak_val = peak_val;
        best_match_idx = i;
        [ypeak, xpeak] = ind2sub(size(c), imax);
        best_peak_loc = [ypeak, xpeak];
        best_match_f = f;
        best_match_t = t;
    end
    
end
time_taken = toc;
fprintf("The whole operation took %d secs",round(time_taken));

%% Announce the winner
fprintf("\n--- RESULTS ---\n");

if best_match_idx == 0
    error("No match could be found. Check sample rates or audio files.");
end

matched_song_file = song_files(best_match_idx);
fprintf("Best match found: %s\n", matched_song_file.name);
fprintf("Original snippet was from: %s\n", snippet_song_file.name);

if best_match_idx == rand_song_idx
    fprintf("The match is correct!!! \n");
else
    fprintf("The match is incorrect. \n");
end

%% Mark the match on the correct plot
ypeak = best_peak_loc(1);
xpeak = best_peak_loc(2);

y_idx = ypeak - size(s_snippet_mag, 1) + 1;
x_idx = xpeak - size(s_snippet_mag, 2) + 1;

x_start_time = best_match_t(x_idx);
y_start_freq = best_match_f(y_idx);

time_width = best_match_t(x_idx + size(s_snippet_mag, 2) - 1) - x_start_time;
freq_height = best_match_f(y_idx + size(s_snippet_mag, 1) - 1) - y_start_freq;

fprintf("Match found in '%s' at spectrogram time: %.2f s\n", matched_song_file.name, x_start_time);

% --- Mark the matching zone on the winner's figure ---
figure(best_match_idx + 1); 

% --- NEW: Activate the correct subplot (the first one) ---
subplot(2, 1, 1);
% --- End New ---

hold on;
rect_pos = [x_start_time, y_start_freq, time_width, freq_height];
rectangle('Position', rect_pos, ...
          'EdgeColor', 'g', ...
          'LineWidth', 4);
          
text_label = sprintf('  Match (%.2f s)', x_start_time);
text(x_start_time, y_start_freq + freq_height, text_label, ...
     'Color', 'red', 'FontSize', 12, 'FontWeight', 'bold');
hold off;

% Update the title to show it's the match
title(['MATCH: ', matched_song_file.name], 'Interpreter', 'none');
        
disp("Done. All song figures now have a correlation subplot.");