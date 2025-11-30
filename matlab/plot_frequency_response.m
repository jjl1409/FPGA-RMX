% Plot frequency response of signal Y versus signal X
function plot_frequency_response(signalX, signalY, Fs, plot_title, xlabels, cutoff)
    arguments
        signalX (1, :) double 
        signalY (1, :) double
        Fs (1, 1) double {mustBeGreaterThan(Fs, 0)}
        plot_title (1, 1) string = "Frequency Response of Filter H (Y / X)"
        xlabels (1, :) double = [0, 50, 100, 500, 1000, 5000, 10000]
        cutoff (1, 1) double = 2800
    end

    L = length(signalX);
    x = Fs / L * (0:(L / 2));
    freqsX = abs(fft(signalX) / L);
    freqsX = freqsX(1:(L / 2 + 1));
    freqsX(2:end - 1) = 2 * freqsX(2:end - 1);
    freqsY = abs(fft(signalY) / L);
    freqsY = freqsY(1:(L / 2 + 1));
    freqsY(2:end - 1) = 2 * freqsY(2:end - 1);

    freqsH = freqsY ./ freqsX;
    freqsY(1:10)
    freqsX(1:10)
    freqsH(1:10)

    subplot(2, 2, 1);
    plot_fft(signalX, Fs);
    subplot(2, 2, 2);
    plot_fft(signalY, Fs);
    subplot(2, 2, 3);
    semilogx(x(cutoff:end), freqsH(cutoff:end));
    xticks(xlabels);
    xticklabels(string(xlabels))
    title(plot_title)
    xlabel ("f (Hz)")
    ylabel("|Signal(f)|")  
end