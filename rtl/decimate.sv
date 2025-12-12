module decimate #(
    parameter DATA_IN_BITS = 17,
    parameter DATA_OUT_BITS = 17,
    parameter DECIMATION_NUM = 32,
    parameter DECIMATION_BITS = 5
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out
)
    // Count logic
    logic [DECIMATION_BITS - 1:0] count = '0;
    always_ff @(posedge clk) begin
        data_out <= data_in;
        data_out_ready <= 1'b0;
        if (data_in_ready) begin
            count = count + 1;
            if (count == 0) begin
                data_out_ready <= 1'b1;
            end
        end
    end
endmodule
    

