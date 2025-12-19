% Given an input signal, detects BPM using a combination of thresholds and target BPM
% Transients output is 1 when a transient is detected (and 0 otherwise)
% A transient is detected when the counter is greater than the minimum period and the input is larger than the threshold
% The counter will reset to max_period - bpm if we do not have a detection
% Bpms represent the BPM, except that it is represented in terms of samples between beats (e.g. 589 corresponds to 140 bpm based on beat calculations)
% Average represents the final BPM calculation in beats per minute over the entire signal
% Threshold is 70000, which is ~75% of the maximum input value sqrt(2) * 2 ** 12; this value was found experimentally, but makes
% sense based on analyzing the wav file & kick transients
% Min period is 1181; max period is 1378
function [transient, bpm, average] = bpm_detection(inputs, threshold, min_period, max_period, fs)
    arguments
        inputs (1, :) uint32
        threshold (1, 1) uint32 = 70000
        min_period (1, 1) uint32 = 1181
        max_period (1, 1) uint32 = 1378
        fs (1, 1) double = 44100 / 64
    end
        inputs = transpose(inputs);
        transient = zeros(length(inputs), 1);
        bpm = zeros(length(inputs), 1);
        counter = 0;
        bpm_counter = min_period;
        for i = 1:length(inputs)
            if (counter >= min_period && inputs(i) > threshold)
                bpm_counter = counter;
                counter = 1;
                transient(i) = 1;
            elseif (counter >= max_period)
                counter = max_period - bpm_counter + 1;
            else
                counter = counter + 1;
            end
            bpm(i) = bpm_counter;
        end
        average = fs * 60 / mean(bpm);
end