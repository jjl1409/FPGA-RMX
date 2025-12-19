// Module to convert beats between samples to bpm reading
// Instantiates a RAM that contains the results of beats between samples to BPM between MIN_PERIOD and MAX_PERIOD
// BPM can be calculated by SAMPLING_RATE / DECIMATION_FACTOR * SECONDS PER MINUTE / SAMPLES BETWEEN BEATS
module samples_to_bpm #(
    parameter DATA_IN_BITS = 11,
    parameter DATA_OUT_BITS = 16,
    parameter MIN_PERIOD = 1181,
    parameter MAX_PERIOD = 1378,
    parameter SAMPLING_RATE = 44100,
    parameter DECIMATION_FACTOR = 16

) (
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic [DATA_OUT_BITS - 1:0] data_out
);
    localparam DECIMAL = 10;
    localparam SECONDS_PER_MINUTE = 60;
    localparam RAM_DEPTH = MAX_PERIOD - MIN_PERIOD + 1;
    localparam RAM_BITS = $clog2(RAM_DEPTH);
    logic [DATA_OUT_BITS - 1:0] ram [RAM_DEPTH - 1:0];

    // RAM instantiation logic
    initial begin
        for (integer i = 0; i < RAM_DEPTH; i++) begin
            ram[i] =  SAMPLING_RATE * SECONDS_PER_MINUTE * DECIMAL / DECIMATION_FACTOR / (MIN_PERIOD + i);
            $display("ram[%d]: %d = %d\n", i, i + MIN_PERIOD, ram[i]);
        end
    end

    // Ram access logic
    logic [RAM_BITS - 1:0] address_shift;
    always_ff @(posedge clk) begin
        address_shift <= data_in - MIN_PERIOD;
        data_out <= ram[address_shift];
    end
endmodule


