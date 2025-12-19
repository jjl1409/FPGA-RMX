% Performs FIR filter on a given set of integer inputs
% Output is the resulting filter applied on input with specified bit size
% Also generates binary coefficients from filter_coefficients
function [bitwise_coefficients, outputs] = fir_filter(inputs, fs, bp_low, bp_high, bp_order, coefficient_bits)
    arguments
        inputs (1, :) uint32;
        fs (1, 1) uint16 = 44100 / 16
        bp_low (1, 1) uint16 = 30
        bp_high (1, 1) uint16 = 250
        bp_order (1, 1) double = 63
        coefficient_bits (1, 1) double = 12
    end
    % csvpath = "../stimulus/blowyourmind_magnitude.csv";
    % inputs = transpose(uint32(readmatrix(csvpath)));
    % inputs = inputs(1 : 10);
    coefficients = transpose(filter_coefficients(fs, bp_low, bp_high, bp_order));
    bitwise_coefficients = uint32(round(coefficients * 2 ^ coefficient_bits));
    inputs = transpose(inputs);
    padded_inputs = [zeros(bp_order, 1); inputs];
    outputs = zeros(length(inputs), 1);
    for i = bp_order + 1:length(padded_inputs)
        for j = 1:bp_order + 1
            outputs(i - bp_order) = outputs(i - bp_order) + floor((padded_inputs(i - j + 1)) * bitwise_coefficients(j));
        end
    end
    % floor(outputs ./ 2 ^ coefficient_bits)
    outputs = floor(outputs ./ (2 ^ coefficient_bits));
    % Testing
    % plot_time(outputs, 44100, 1)
    % plot_time(inputs, 44100, 100)
    % outputs = 0;
    % freqz(coefficients, 1, 44100 / 2)
end
    
% Generates double filter_coefficients with the specified bandpass
% Uses a Hanning window with n + 1 coefficients (filter order n)
function coefficients = filter_coefficients(fs, bp_low, bp_high, bp_order)
    arguments
        fs (1, 1) uint16 = 44100 / 16
        bp_low (1, 1) uint16 = 80
        bp_high (1, 1) uint16 = 200
        bp_order (1, 1) uint16 = 63
    end
    Wn = [double(bp_low) * 2.0 / double(fs), double(bp_high) * 2.0 / double(fs)];
    coefficients = fir1(bp_order, Wn, "bandpass", hann(bp_order + 1));
end
