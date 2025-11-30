% Plot FFT of a signal given sampling frequency
function plot_fft(signal, Fs, plot_title, xlabels, cutoff)
    arguments
        signal (1,:) double
        Fs (1, 1) double {mustBeGreaterThan(Fs, 0)}
        plot_title (1, 1) string = "FFT of Signal"
        xlabels (1, :) double = [0, 50, 100, 500, 1000, 5000, 10000]
        cutoff (1, 1) double = 2800
    end

    L = length(signal);
    x = Fs / L * (0:(L / 2));   
    freqs = abs(fft(signal) / L);
    freqs = freqs(1:(L / 2 + 1));
    freqs(2:end - 1) = 2 * freqs(2:end - 1);

    semilogx(x(cutoff:end), freqs(cutoff:end))
    xticks(xlabels);
    xticklabels(string(xlabels))
    title(plot_title)
    xlabel ("f (Hz)")
    ylabel("|Signal(f)|")

end
