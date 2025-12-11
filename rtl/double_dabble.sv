// Double dabble module for converting binary input into an array of decimal outputs
// Adapted from https://github.com/AmeerAbdelhadi/Binary-to-BCD-Converter to make it clocked + pipelined
module double_dabble #(
    parameter DATA_IN_BITS = 12,
    parameter DATA_OUT_BITS = 4,
    parameter DATA_OUT_WIDTH = 4
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out [DATA_OUT_WIDTH - 1:0]
);
    // Algo explanation:
    // Shift and add 3 involves shifting into an array of decimal places from our binary representation
    // Each time we shift, we check each place if it is at least 5 (has carry). We then add 3.
    // This is equivalent to doubling + adding 6 after a shift. 5->16, and so on, thus correctly "carrying" over a decimal place.
    // Each operation doubles the BCD value and adds 1 or 0 to properly carry.
    // Instead of shifting, we can simply look at the number of shift/add 3 operation in total and apply them to each decimal digit as needed.
    // An initial pass would be DATA_IN_BITS stages deep and DATA_OUT_WIDTH shift/add 3s wide (since we check each digit * the number of shifts)
    // We can then remove the first three stages (since this will never shift + add 3 until we shift at least three numbers in)
    // We can also remove any shift/add 3 that does not have bits "shifted in", which can be tracked by current index / 3
    // Essentially we perform the shift/add 3 by generating instead of actually shifting, and removing unneeded calcs.
    // We pipeline each intermediate stage with memory of DATA_IN_BITS - 3 (number of stages) size.
    // The width is slightly larger; we need extra space for the decimal representation which we can simplify to DATA_OUT_WIDTH * DATA_OUT_BITS
    // Note that it is not always DATA_OUT_WIDTH * DATA_BITS; the actual calc is DATA_IN_BITS / 3 + DATA_IN_BITS - 1, but for ease of assignment we choose the former

    localparam BCD_DEPTH = (DATA_IN_BITS - 3);
    localparam BCD_BITS = DATA_OUT_WIDTH * DATA_OUT_BITS;
    localparam DATA_OUT_DELAY = BCD_DEPTH;

    integer i, j;
    logic [BCD_BITS - 1:0] bcd [BCD_DEPTH - 1:0] =  '{default:0};

    always_ff @(posedge clk) begin
        // First stage (since we cannot access i - 1)
        // Same logic as below, but with data_in as input
            bcd[0] <= data_in;
            if (data_in[DATA_IN_BITS - 1 -: 3] > 4) begin
                bcd[0][DATA_IN_BITS -: 4] <= data_in[DATA_IN_BITS - 1 -: 3] + 4'd3; // add 3
            end
        // Iterate over BCD depth (number of stages)
        for(i = 1; i < BCD_DEPTH; i = i + 1) begin       
            bcd[i] <= bcd[i - 1];
            // Iterate over current width (number of BCD comparisons/additions per stage)
            // We look at 0 to i, dividing by 3 and then adding 1 (for a minimum of one BCD calc per stage)
            // Every 3 stages, we require an additional calc thus the division by 3. We need to handle carry every 3 bits despite
            // looking at 4 at a time. 
            for(j = 0; j < i / 3 + 1; j = j + 1)  begin                   
                if (bcd[i - 1][DATA_IN_BITS - i + 4 * j -: 4] > 4) begin
                    bcd[i][DATA_IN_BITS - i + 4 * j -: 4] <= bcd[i - 1][DATA_IN_BITS - i + 4 * j -: 4] + 4'd3; // add 3
                end
            end
        end
        for (i = 0; i < DATA_OUT_WIDTH; i = i + 1) begin
            // Assign outputs
            data_out[i] <= bcd[BCD_DEPTH - 1][(i + 1) * DATA_OUT_BITS - 1 -: DATA_OUT_BITS];
        end
    end

    // Modeling delay (can be calculated as DATA_OUT_DELAY + 1)
    logic data_out_ready_delay [DATA_OUT_DELAY - 1:0];
    always_ff @(posedge clk) begin
        data_out_ready_delay <= {data_out_ready_delay[DATA_OUT_DELAY - 2:0], data_in_ready};
        data_out_ready <= data_out_ready_delay[DATA_OUT_DELAY - 1];
    end
endmodule