clear;
clf;
% Tests function/script. Used as a scratchpad/simple tests for our MATLAB models
% Run by calling tests from command line from ./matlab dir

% Simple FIR filter
% This is a basic moving average filter
function output = filter1(input, size)
    arguments
        input (1,:) double
        size (1, :) = 16
    end
    output = zeros(1, length(input));
    output(1) = input(1);
    output(2) = input(2);
    for i = size:length(input)
        output(i) = sum(input(i:-1:i - size + 1)) / size;
        % output
    end
    % output
end

% Simple test for magnitude calculation. Compares magnitude function with actual magnitude (error is expected due to truncation/limited square root resolution)
% Result is a consistent ~10% of maximum magnitude (which is sufficient for our purposes)
function test_magnitude
    file = "../music/blowyourmind.wav";
    samps = audioread(file, "native");
    Fs = 44100;

    sums = zeros(1, length(samps));
    magnitudes = zeros(1, length(samps));
    normalized = zeros(1, length(samps));
    for i = 1:length(samps)
        x1 = typecast(samps(i, 1), 'uint16');
        x2 = typecast(samps(i, 2), 'uint16');
        [sums(i), magnitudes(i)] = magnitude(x1, x2);
        normalized(i) = round(sqrt(double(x1) ^2 + double(x2)^2));
    end
    plot_time(abs(magnitudes(1:100000) - normalized(1:100000)) ./ max(magnitudes), Fs, 5, "Magnitude Function Error (Time Domain)")
end

% Test for BPM detection. Calculates transients for a given audio signal, along with the number of samples
% between transients and the overall average BPM.
% This graphs the audio signal along with transients and the transient threshold.
% The second graph calculates the BPM over time (this is not averaged)
% Result: blowyourmind.wav has an expected BPM of 128. We calculate an average bpm of 128.5
% We also have a very clear settling of the BPM at around ~30 seconds in
% Transients are very clearly marked with a few exceptions; the beat detection algorithm ignores this and continues on with the previously detected bpm
function test_bpm_detection
    file = "../stimulus/blowyourmind_fir_filter.csv";
    inputs = readmatrix(file);
    fs = 44100 / 16;
    threshold = 7e4;
    min_period = 1181;
    max_period = 1378;
    [transient, bpm, average] = bpm_detection(inputs, threshold, min_period, max_period, fs);
    % Draw plot 1 for beat detection transients
    plot_title = "Beat Detection Transients";
    xlabels = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
    x = 1 / fs  * (0:length(inputs) - 1);
    tiledlayout(2,1)
    nexttile
    stem(x, inputs, 'Marker', 'none')
    for i = 1:length(transient)
        if transient(i) == 1
            xline(i / fs, 'red')
        end
    end
    xlabel ("t(s)")
    ylabel("|Signal(f)|")
    xticks(xlabels);
    xticklabels(string(xlabels))
    title(plot_title)
    yline(threshold, 'green')
    % Draw plot 2 for bpm over time
    nexttile
    x = [0];
    y = [fs * 60 / bpm(1)];
    % Only graph point when we have change in BPM
    for (i = 2:length(bpm))
        if bpm(i) ~= bpm(i - 1)
            x = [x, i / fs];
            y = [y, fs * 60 / bpm(i)];
        end
    end
    plot_title = "Expected BPM: 128, Average BPM: " + average;
    plot(x, y)
    xlabel ("t(s)")
    ylabel("Beats per minute")
    xticks(xlabels);
    xticklabels(string(xlabels))
    title(plot_title)

    % x = 1 / fs * stride * (0:length(averaged_inputs) - 1);
    % stem(x, averaged_inputs, 'Marker', 'none')

end

% This prints out all plots from all tests into their own figures. Note that these tests are not pass/fail, and instead serve to check basic functionality of our Matlab implementations before verifying with RTL.

% figure
% test_magnitude
clf
figure
test_bpm_detection
% Sandbox area for testing

% file = "../music/blowyourmind.wav";
% samps = audioread(file, "native");
% Fs = 44100;
% plot_time(samps(1:100000, 1), Fs, 5)
% plotFFT(leftsamps(:, 2), Fs)
% plot_frequency_response(leftSamps, filter1(leftSamps), Fs)
% filter1(leftSamps)
% size(samps)

% max(samps(:, 1))