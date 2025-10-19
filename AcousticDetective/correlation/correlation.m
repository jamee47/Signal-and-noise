%% clearing the workspace
clc, clearvars, close all;

%% 
% loading the audio file 
disp("Loading Audio....");
try
    [full_audio, fs] = audioread('data\oh_lord.mp3');
    full_audio = single(full_audio); %for memory efficiency
    disp("Audio Loaded Successfully");
catch
    disp("The audio file is not found");
end

%% preprocessing the audio

% checking if the audio is mono or stereo
if size(full_audio, 2)>1
    disp("The audio is stereo converting it to mono");
    mono_audio = mean(full_audio,2);
else
    disp("The audio is mono");
end

%% ploting the audio

figure('Name','Audio Waveform');
plot(mono_audio); grid on;
xlabel("Number of Samples"); ylabel("Amplitude");
audio_pl = audioplayer(mono_audio,fs);
%disp("Playing the audio");
%play(audio_pl);

%% define a random snipet

snippet_duration_sec = 20;
snippet_length_samples = round(snippet_duration_sec * fs);


total_song_samples = length(mono_audio);

% Make sure the snippet isn't longer than the song
if snippet_length_samples >= total_song_samples
    error('The snippet duration is longer than the actual song. Please choose a shorter duration.');
end

%maximum possible snipet
max_possible_snippet = total_song_samples- snippet_length_samples;

start_sample = randi(max_possible_snippet);
end_sample = start_sample + (snippet_length_samples-1);

snippet = mono_audio(start_sample:end_sample);


% saving the start time
actual_start_time = (start_sample-1)/ fs;

% plotting the snippet
figure('Name', 'Snippet Waveform');
plot(snippet);
title('The Snippet We Need To Find');
xlabel('Sample Number (within snippet)');
ylabel('Amplitude');
grid on;

disp("Playing the snippet");
sound(snippet,fs); % listenig the snippet

%% performing the correlation

[correlation, lags] = xcorr(mono_audio, snippet);

[~, max_idx] = max(abs(correlation));

found_sample_lag = lags(max_idx);
found_start_sample = found_sample_lag;

found_time = (found_start_sample - 1) / fs;

disp('Correlation complete!');
disp('--- Sleuth Report ---');
disp(['Secret Snippet Start Time: ', num2str(actual_start_time, '%.2f'), 's']);
disp(['Time Found by Correlation:  ', num2str(found_time, '%.2f'), 's']);

% Visualizing the Correlation
figure('Name', 'Correlation Result', 'NumberTitle', 'off');
plot(lags, correlation);
title('Cross-Correlation of Snippet against Full Song');
xlabel('Lag (Sample Offset)'); ylabel('Correlation Magnitude');
grid on; hold on;

plot(found_sample_lag, correlation(max_idx), 'r*', 'MarkerSize', 10);
legend('Correlation', 'Peak Match');
hold off;