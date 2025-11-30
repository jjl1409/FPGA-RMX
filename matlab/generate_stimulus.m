% Generates the stimulus files in the folder 
% Call it with generate_stimulus("audioname") from command line and repo root dir
% Note that audioname does not include path and extension. E.g. generate_stimulus("easemymind")
% Can specify path and extension if necessary e.g. generate_stimulus("easemymind", "../music/", ".wav")
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
    writematrix(output_1, "../stimulus/" + file + "_input_1.csv");
    writematrix(output_2, "../stimulus/" + file + "_input_2.csv");
    generate_magnitude(file)
end

% Generates magnitude files from magnitude module
% Outputs are files with suffix _square_sum_1 and _magnitude_1
function generate_magnitude(file)
    arguments
        file (1, 1) string
    end
    input_1 = readmatrix("../stimulus/" + file + "_input_1.csv");
    input_2 = readmatrix("../stimulus/" + file + "_input_2.csv");
    square_sum_1 = zeros(length(input_1), 1);
    magnitude_1 = zeros(length(input_1), 1);
    for i = 1:length(input_1)
        [square_sum_1(i), magnitude_1(i)] = magnitude(uint16(input_1(i)), uint16(input_2(i)));
    end
    writematrix(square_sum_1, "../stimulus/" + file + "_square_sum_1.csv");
    writematrix(magnitude_1, "../stimulus/" + file + "_magnitude_1.csv");
end


