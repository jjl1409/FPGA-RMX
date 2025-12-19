module moving_average #(
    parameter DATA_IN_BITS = 12,
    parameter DATA_OUT_BITS = 12,
    parameter AVERAGE_NUM = 16,
    parameter AVERAGE_BITS = 4
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out
);
    // Count logic
    logic [AVERAGE_BITS - 1:0] count = '0;
    always_ff @(posedge clk) begin
        data_out_ready <= 1'b0;
        if (data_in_ready) begin
            count <= count + 1;
            if (count == 0) begin
                data_out_ready <= 1'b1;
            end
        end
    end

    // Moving average logic
    logic [DATA_IN_BITS - 1:0] data_in_shift [AVERAGE_NUM - 1:0] = '{default: 0};
    logic data_in_ready_extended;
    logic signed [DATA_OUT_BITS:0] average_subtract;
    logic signed [DATA_OUT_BITS:0] average = '0;
    logic signed [DATA_OUT_BITS:0] average_sum;
    logic signed [DATA_OUT_BITS:0] average_add;
    assign average_subtract = data_in_shift[AVERAGE_NUM - 1] >>> AVERAGE_BITS;
    assign average_add = data_in >>> AVERAGE_BITS;
    
    always_ff @(posedge clk) begin
        data_in_ready_extended <= data_in_ready;
        if (data_in_ready) begin
            data_in_shift[0] <= data_in;
            for (int i = 1; i < AVERAGE_NUM; i++) begin
                data_in_shift[i] <= data_in_shift[i - 1];
            end
            average_sum <= average_add - average_subtract;
        end
        if (data_in_ready_extended) begin
            average <= average_sum + average;
        end
    end

    assign data_out = average[DATA_OUT_BITS - 1:0];

endmodule