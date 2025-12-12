function bpm_detection2(file)
    
    % PARAMETERS
    stimdir = "../stimulus/";
    
    Fs_mag = 44100;          % sampling rate of magnitude input
    
    % FIR Bandpass Filter
    bp_low  = 30;            % Hz
    bp_high = 250;           % Hz
    bp_order = 32;           % must be <= 32 for FPGA
    
    quant_bits = 8;          % 1/(2^8) quantization for FPGA
    
    % Moving Averages
    MA1_len = 32;            % sliding window: samples (1–32, 2–33,...)
    MA2_len = 32;            % block window: (1–32), (33–64), ...
    
    % Hard threshold
    thresh = 0.9;      % tune for non-normalized magnitudes
    
    % Refractory period
    Refractory_s = 0.36;      % seconds between beat detections
    minDistSamples = round(Refractory_s * Fs_mag);
    
    % Output filenames
    beats_out = "_beats.csv";
    beat_times_out = "_beat_times.csv";
    coeffs = "_filter_coefficients.csv";
    
    %  LOAD INPUT MAGNITUDE
    
    thisdir = fileparts(mfilename('fullpath'));
    stimdir_full = fullfile(thisdir, "..", "stimulus");
    if isfolder(stimdir)
        stimdir_full = stimdir;
    end
    
    csvpath = fullfile(stimdir_full, file + "_magnitude_1.csv");
    if ~isfile(csvpath)
        error("Magnitude CSV not found: %s", csvpath);
    end
    
    mag = double(readmatrix(csvpath));
    mag = mag(:);    % ensure column vector
    N = length(mag);
    
    % 1. BANDPASS FIR (ORDER = 32)
    
    Wn = [bp_low/(Fs_mag/2), bp_high/(Fs_mag/2)];
    
    b_fir = fir1(bp_order, Wn, "bandpass", hann(bp_order+1));
    
    % Quantize coefficients to nearest 1/(2^8)
    b_quant = round(b_fir * 2^quant_bits) / 2^quant_bits;
    
    % save coefficients as binary strings for FPGA
    coeff_bin = strings(length(b_quant),1);
    for k = 1:length(b_quant)
        val = b_quant(k);
        fixed_int = round(val * 2^quant_bits);    % signed integer
        coeff_bin(k) = dec2bin(mod(fixed_int,2^(quant_bits+1)), quant_bits+1);
    end
    
    writematrix(coeff_bin, fullfile(stimdir_full, file + coeffs));
    
    % ---- Filter input signal using quantized coefficients
    filtered = filter(b_quant, 1, mag);
    
    % 2. MOVING AVERAGE 1 (SLIDING: 1234,2345,...)
    
    MA1 = zeros(N,1);
    for i = MA1_len:N
        MA1(i) = mean(filtered(i-MA1_len+1 : i));
    end
    
    % 3. MOVING AVERAGE 2 (BLOCK: 1234, 5678, ...)
    
    MA2 = zeros(N,1);
    for i = 1:MA2_len:N
        idx_end = min(i+MA2_len-1, N);
        block_mean = mean(MA1(i:idx_end));
        MA2(i:idx_end) = block_mean;
    end
    
    env = MA2;   % final amplitude envelope
    
    % 4. THRESHOLD

    T = thresh * max(mag);
    display(T);

    % 5. PEAK DETECTION WITH REFRACTORY
    
    [~, locs] = findpeaks(env, ...
        'MinPeakHeight', T, ...
        'MinPeakDistance', minDistSamples);
    
    beats = zeros(N,1);
    beats(locs) = 1;
    
    beat_times = (locs - 1) / Fs_mag;
    
    %  SAVE OUTPUTS
    
    writematrix(beats, fullfile(stimdir_full, file + beats_out));
    writematrix(beat_times, fullfile(stimdir_full, file + beat_times_out));
    
    fprintf("\n=== BPM DETECTOR ===\n");
    fprintf("Detected %d beats\n", length(locs));
    fprintf("Saved beat vector: %s\n", fullfile(stimdir_full, file + beats_out));
    fprintf("Saved beat times: %s\n", fullfile(stimdir_full, file + beat_times_out));
    fprintf("Saved FIR coefficients: %s\n", fullfile(stimdir_full, file + coeffs));
    
    end
    