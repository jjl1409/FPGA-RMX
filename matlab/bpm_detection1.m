function bpm_detection (file)

%   Detects transients from magnitude CSV
%
%   bpm_detection("easemymind")
%
% Reads ../stimulus/<file>_magnitude.csv, runs an FIR filter (band-
% limiting + moving average combined), uses adaptive thresholding and
% refractory period, then writes:
%   ../stimulus/<file>_beats.csv        -> 0/1 vector (length = downsampled frames)
%   ../stimulus/<file>_beat_times.csv   -> beat times (seconds)
%
% Edit parameters constants to fine-tune the detector.

% PARAMETERS
stimdir = "../stimulus/";   % where the magnitude CSV lives and outputs will be written

% Magnitude sampling assumptions
Fs_mag = 44100;             % sampling rate at which magnitude was computed (Hz)
Fs_ds  = 2000;               % downsampled processing rate (Hz) - cant be too small or corrupt transient data

% Band-limited filter on the downsampled magnitude (to isolate beat-rate bands)
bp_low = 30;               % low cutoff (Hz) 
bp_high = 250;              % high cutoff (Hz) THIRD HARMONIC CAN GO UP TO 250HZ
bp_order = 400;             % FIR order for bandpass (even number)

% MA implemented at downsampled rate, converted to samples below
MA_ms = 100;                % window length in ms (50-200ms good), but 100 seems to work best

% Detection
ThreshFactor = 1.0;         % threshold = median + ThreshFactor * std
Saturation = 0.95;          % clamp fraction of max magnitude before processing (0..1) or Inf to disable
Refractory_s = 0.3;         % minimum time between beats (seconds) (0.5 suits 120-140 BPM)

% Output filenames
beats_out_suffix = "_beats.csv";
beat_times_out_suffix = "_beat_times.csv";

% PROCESSING

thisdir = fileparts(mfilename('fullpath'));
stimdir_full = fullfile(thisdir, "..", "stimulus"); 
if isfolder(stimdir)
    stimdir_full = stimdir;
end

csvpath = fullfile(stimdir_full, file + "_magnitude.csv");
if ~isfile(csvpath)
    error("Magnitude CSV not found: %s", csvpath);
end

% Load magnitude (single column expected)
mag = readmatrix(csvpath);
mag = double(mag(:));  % ensure column double

% Optional saturation (clamp large outliers)
if isfinite(Saturation) && (Saturation > 0)
    clamp_val = Saturation * max(mag);
    mag(mag > clamp_val) = clamp_val;
end

% Normalize to 0..1
mag = mag / (max(mag) + eps);

% Downsample the magnitude to a low-rate stream for envelope/bpm detection

% We need integer decimation factor for decimate(). Compute nearest integer factor.
ds_factor = max(1, round(Fs_mag / Fs_ds));
Fs_proc = Fs_mag / ds_factor;        % processing sampling rate
if ds_factor ~= 1
    % includes an anti-aliasing filter
    mag_ds = decimate(mag, ds_factor);
else
    mag_ds = mag;
end
N = length(mag_ds);

% Design bandpass FIR on the downsampled rate
% (We design a bandpass around the beat-rate: e.g., 1.2 - 3.0 Hz)
% Normalize band edges for fir1
Wn = [bp_low, bp_high] / (Fs_proc/2);
if any(Wn <= 0) || any(Wn >= 1)
    error("Band edges invalid for Fs_proc=%.2f. Choose bp_low/bp_high such that 0 < f < Fs/2.", Fs_proc);
end
b_bp = fir1(bp_order, Wn, 'bandpass', hann(bp_order+1));  % windowed design (Hann)

% Design moving-average FIR (at the downsampled rate)
ma_samples = max(1, round(MA_ms * 1e-3 * Fs_proc));
b_ma = ones(1, ma_samples) / ma_samples;

% Combine the bandpass and MA into a single FIR via convolution
b_combined = conv(b_bp, b_ma);

if length(mag_ds) < 3*length(b_combined)
    % if the signal is too short for filtfilt, fall back to simple filter
    filtered = filter(b_combined, 1, mag_ds);
else
    filtered = filtfilt(b_combined, 1, mag_ds);  % zero-phase to avoid group delay
end

% Normalize envelope
env = abs(filtered);
env = env / (max(env) + eps);

% Adaptive threshold: median + k*std
T = median(env) + ThreshFactor * std(env);
disp(T);
% figure; plot(env); hold on; yline(T, 'r'); title("Envelope + Threshold");

% Peak detection with refractory period
minDistSamples = round(Refractory_s * Fs_proc);
[peaks, locs] = findpeaks(env, 'MinPeakHeight', T, 'MinPeakDistance', minDistSamples);

% Build beat vector (downsampled-rate 0/1 vector)
beats_ds = zeros(N,1);
beats_ds(locs) = 1;

% Convert locs to times (seconds)
beat_times = (locs - 1) ./ Fs_proc;

% Save outputs
if ~isfolder(stimdir_full)
    mkdir(stimdir_full);
end
writematrix(beats_ds, fullfile(stimdir_full, file + beats_out_suffix));
writematrix(beat_times, fullfile(stimdir_full, file + beat_times_out_suffix));

% Print summary
fprintf("bpm_detection_from_magnitude: detected %d transients (beats).\n", length(locs));
fprintf("Downsampled processing rate = %.2f Hz (decimation factor = %d).\n", Fs_proc, ds_factor);
fprintf("Saved 0/1 beat vector to: %s\n", fullfile(stimdir_full, file + beats_out_suffix));
fprintf("Saved beat times to: %s\n", fullfile(stimdir_full, file + beat_times_out_suffix));

end