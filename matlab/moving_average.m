% Generates a moving average from n taps (average_taps)
% This also performs a decimation by n (thus for every n inputs, we get 1 output)
% Inputs are 17-bit numbers; output is also a 17-bit binary number
% Note that to perform division, we divide by n (aka a bitshift by log2 n)
% Average taps should equal 2 ** average_bits
function outputs = moving_average(inputs, average_taps)
    arguments
        inputs (1, :) uint32
        average_taps (1, 1) double = 32
    end
    % inputs = repmat(319, 1, 320); 
    inputs = floor(double(transpose(inputs)) ./ average_taps);
    outputs = zeros(floor(length(inputs) / average_taps), 1);
    for i = 1:length(outputs)
        outputs(i) = sum(inputs((i - 1) * average_taps + 1:i * (average_taps)));
    end
    
end
    