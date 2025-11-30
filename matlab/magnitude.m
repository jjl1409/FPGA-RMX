
% Given a "complex" number, calculate the magnitude in bits
% Note that we substitute L/R channels for real and imaginary parts in practical use
function [sum, root] = magnitude(x1, x2)
    arguments
        x1 (1, 1) uint16
        x2 (1, 1) uint16
    end
    sum = square_sum(x1, x2);
    root = square_root(sum);
end

% Calculate the square sum of two numbers (each number is squared and then added)
% Note the restriction to 16 bit unsigned ints
% Result should be a 33 bit int
function sum = square_sum(x1, x2)
    arguments
        x1 (1, 1) uint16
        x2 (1, 1) uint16
    end
    x1 = uint64(x1);
    x2 = uint64(x2);
    sum = x1 * x1 + x2 * x2;
end

% Calculate the square root of a number
% We only take the square root of the top square_root_bits to save on RAM
% Result should be a 17 bit integer
function root = square_root(x, square_root_bits)
    arguments
        x (1, 1) uint64
        square_root_bits(1, 1) int8 = 13
    end
    x = bitshift(x, -33 + square_root_bits);
    root = uint32(floor(sqrt(double(x))));
    root = bitshift(root, 17 - square_root_bits / 2);
end