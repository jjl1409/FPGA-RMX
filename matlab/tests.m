clear;
clc;
clf;

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
% Result is <10% of maximum magnitude (which is sufficient for our purposes)
function test_magnitude
    file = "../music/easemymind.wav";
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
    magnitudes(1:10)
    normalized(1:10)
    plot_time(abs(magnitudes - normalized) ./ max(magnitudes), Fs)
end

% This prints out all plots from all tests into their own figures. Note that these tests are not pass/fail, and instead serve to check basic functionality of our Matlab implementations before verifying with RTL.

% Sandbox area for testing

test_magnitude
% plotFFT(leftsamps(:, 2), Fs)
% plot_frequency_response(leftSamps, filter1(leftSamps), Fs)
% filter1(leftSamps)
% size(samps)

% max(samps(:, 1))