clear;
clc;
clf;
file = "../music/easemymind.wav";

samps = audioread(file);

function output = filter1(input)
    end
% samps
% freqs = fft(samps(:, 1))

Fs = 44100;

function plotFFT(signal, Fs, xlabels, cutoff)
    arguments
        signal (1,:) double
        Fs (1,1) double {mustBeGreaterThan(Fs, 0)}
        xlabels (1,:) double = [50, 100, 500, 1000, 5000, 10000]
        cutoff (1, 1) double = 2800
    end
    L = length(signal);
    freqs = abs(fft(signal) / L);
    % freqs
    freqs = freqs(1:(L / 2 + 1));
    freqs(2:end - 1) = 2 * freqs(2:end - 1);
    % Fs / L
    x = Fs / L * (0:(L / 2));
    x(1:10)
    semilogx(x(cutoff:end), freqs(cutoff:end))
    xticks(xlabels);
    xticklabels(string(xlabels))
    title("FFT of Signal")
    xlabel ("f (Hz)")
    ylabel("|Signal(f)|")

end

plotFFT(samps(:, 2), Fs)