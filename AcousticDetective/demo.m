% This is the main script to demonstrate the audio fingerprinting process.
% Run this file to see the three functions in action.

clc;
clear;
close all;

disp('Starting audio fingerprinting demo...');

% --- 1. Create a Test Audio Signal ---
% Instead of loading a file, we'll generate a simple sine wave.
fs = 44100; % Sample rate (Hz)
t = 0:1/fs:2; % 2 seconds of audio
f1 = 440; % Frequency of first note (A4)
f2 = 880; % Frequency of second note (A5)
% Create a signal that changes frequency halfway through
audioSignal = [sin(2*pi*f1*t(1:length(t)/2)), sin(2*pi*f2*t(length(t)/2+1:end))];
% Add a bit of noise
audioSignal = audioSignal + 0.1 * randn(size(audioSignal));
% Ensure it's a column vector
audioSignal = audioSignal(:);

disp(['Generated 2-second test signal at ' num2str(fs) ' Hz.']);

% --- 2. Define Spectrogram Parameters ---
windowSize = 2048; % Size of the FFT window
overlapSize = 1024; % Overlap between windows (50%)

% --- 3. Call the Fingerprinting Functions ---

% Function 1: Create the Spectrogram
disp('Calling Function 1: createSpectrogram...');
[S, F, T] = spectrogram(audioSignal, fs, windowSize, overlapSize);
disp('Spectrogram created.');

% Function 2: Find Spectrogram Peaks
disp('Calling Function 2: findSpectrogramPeaks...');
% We'll use a percentile threshold to find prominent peaks
peakThresholdPercent = 95; 
peakIndices = findSpectrogramPeaks(S, peakThresholdPercent);
disp(['Found ' num2str(size(peakIndices, 1)) ' peaks.']);

% Function 3: Generate Fingerprint Hashes
disp('Calling Function 3: generateFingerprintHashes...');
% These parameters define the "target zone" for pairing peaks
targetTimeStart = 1;  % Start 1 time step after anchor
targetTimeEnd = 10;   % End 10 time steps after anchor
targetFreqRange = 20; % +/- 20 frequency bins
hashmap = generateFingerprintHashes(peakIndices, targetTimeStart, targetTimeEnd, targetFreqRange);
disp(['Generated ' num2str(hashmap.Count) ' unique hashes.']);

% --- 4. Visualization ---
disp('Plotting results...');
figure('Name', 'Audio Fingerprinting Demo');

% Plot the spectrogram
surf(T, F, 10 * log10(S), 'EdgeColor', 'none');
axis tight;
view(0, 90);
colormap(jet);
set(gca, 'YScale', 'linear'); % Use linear scale for this demo
ylim([0 1000]); % Limit to 0-1000 Hz to see our notes
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Spectrogram with Peaks');
colorbar;
hold on;

% Plot the peaks on top of the spectrogram
% We need to convert peak indices (row, col) back to (Time, Frequency)
peakTimes = T(peakIndices(:, 1));
peakFreqs = F(peakIndices(:, 2));

plot3(peakTimes, peakFreqs, ones(size(peakTimes)) * 100, 'k.', 'MarkerSize', 10);
legend('Spectrogram', 'Found Peaks');
hold off;

disp('Demo finished.');
