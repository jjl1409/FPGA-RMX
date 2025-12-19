function plot_time(signal, Fs, stride, plot_title, xlabels)
    arguments
        signal (1,:) double
        Fs (1, 1) double = 44100
        stride (1, 1) double = 1000
        plot_title (1, 1) string = "Discrete Time Domain of Signal"
        xlabels (1, :) double = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    end

    signal = signal(1:stride:length(signal) - 1);
    L = length(signal);
    x = 1 / Fs * stride * (0:L - 1);
    stem(x, signal, 'Marker', 'none')
    xticks(xlabels);
    xticklabels(string(xlabels))
    title(plot_title)
    xlabel ("t(s)")
    ylabel("|Signal(f)|")

end
