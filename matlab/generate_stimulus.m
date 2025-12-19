% Generates the stimulus files in the folder 
% Call it with generate_stimulus("audioname") from command line and repo root dir
% Note that audioname does not include path and extension. E.g. generate_stimulus("blowyourmind")
% Can specify path and extension if necessary e.g. generate_stimulus("blowyourmind", "../music/", ".wav")
% All stimulus files are in .csv format. They are single valued per row, with the number of rows being the length.
function generate_stimulus(file, path, extension)
    arguments
        file (1, 1) string
        path (1, 1) string = "../music/"
        extension (1, 1) string = ".wav"
    end
    samps = audioread(path + file + extension, "native");
    output_1 = zeros(length(samps), 1);
    output_2 = zeros(length(samps), 1);
    for i = 1:length(samps)
        output_1(i, 1) = typecast(samps(i, 1), 'uint16');
        output_2(i, 1) = typecast(samps(i, 1), 'uint16');
    end
    % writematrix(output_1, "../stimulus/" + file + "_input_1.csv");
    % writematrix(output_2, "../stimulus/" + file + "_input_2.csv");
    % generate_magnitude(file)
    % generate_moving_average(file)
    % generate_fir_filter(file)
    % generate_bpm_detection(file)
    generate_transient("snare")
end

% Generates magnitude files from magnitude module
% Outputs are files with suffix _square_sum and _magnitude
function generate_magnitude(file)
    arguments
        file (1, 1) string
    end
    input_1 = readmatrix("../stimulus/" + file + "_input_1.csv");
    input_2 = readmatrix("../stimulus/" + file + "_input_2.csv");
    square_sum = zeros(length(input_1), 1);
    outputs = zeros(length(input_1), 1);
    for i = 1:length(input_1)
        [square_sum(i), outputs(i)] = magnitude(uint16(input_1(i)), uint16(input_2(i)));
    end
    writematrix(square_sum, "../stimulus/" + file + "_square_sum.csv");
    writematrix(outputs, "../stimulus/" + file + "_magnitude.csv");
end

function generate_moving_average(file)
    arguments
        file (1, 1) string
    end
    inputs = readmatrix("../stimulus/" + file + "_magnitude.csv");
    outputs = moving_average(inputs, 16);
    writematrix(outputs, "../stimulus/" + file + "_moving_average.csv");
end

function generate_fir_filter(file)
    arguments
        file (1, 1) string
    end
    inputs = readmatrix("../stimulus/" + file + "_moving_average.csv");
    [coefficients, outputs] = fir_filter(inputs);
    filename = "../stimulus/" + "fir_filter_coefficients.mem";
    fd = fopen(filename, 'w');
    for i = 1:length(coefficients)
        fwrite(fd, dec2bin(coefficients(i), 12));
        fwrite(fd, newline);
    end
    fclose(fd);
    writematrix(outputs, "../stimulus/" + file + "_fir_filter.csv")
end

function generate_bpm_detection(file)
    arguments
        file (1, 1) string
    end
    inputs = readmatrix("../stimulus/" + file + "_fir_filter.csv");
    [transient, bpm, average] = bpm_detection(inputs);
    writematrix(transient, "../stimulus/" + file + "_transient.csv");
    writematrix(bpm, "../stimulus/" + file + "_bpm.csv");
end

function generate_transient(file)
    arguments
        file (1, 1) string
    end
    outputs = audioread("../music/" + file + ".wav", "native");
    outputs = outputs(:);

    filename = "../stimulus/" + file + ".mem";
    fd = fopen(filename, 'w');
    for i = 1:length(outputs)
        outputs(i) = typecast(outputs(i), 'uint32');
        % dec2bin(outputs(i), 24)
        fwrite(fd, dec2bin(outputs(i), 24));
        fwrite(fd, newline);
    end
    fclose(fd);
end    

