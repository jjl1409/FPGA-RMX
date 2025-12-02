// Square sum module
module square_sum #(
    parameter DATA_IN_BITS = 16,
    parameter PRODUCT_BITS = DATA_IN_BITS * 2,
    parameter DATA_OUT_BITS = PRODUCT_BITS + 1
)(
    input logic clk,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in_1,
    input logic [DATA_IN_BITS - 1:0] data_in_2,
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out
);
    logic [PRODUCT_BITS - 1:0] product_1;
    logic [PRODUCT_BITS - 1:0] product_2;
    logic product_ready;

    always_ff @(posedge clk) begin
        // Stage 1
        product_ready <= data_in_ready;
        product_1 <= data_in_1 * data_in_1;
        product_2 <= data_in_2 * data_in_2;
        // Stage 2
        data_out <= product_1 + product_2;
        data_out_ready <= product_ready;
    end
endmodule

// Square root module
module square_root #(
    parameter DATA_IN_BITS = 33,
    parameter SQUARE_ROOT_BITS = 13,
    parameter SQUARE_ROOT_OUT_BITS = SQUARE_ROOT_BITS / 2 + 1,
    parameter SQUARE_ROOT_SHIFT_BITS = (DATA_IN_BITS - SQUARE_ROOT_BITS) / 2,
    parameter DATA_OUT_BITS = SQUARE_ROOT_OUT_BITS + SQUARE_ROOT_SHIFT_BITS,
    parameter SQUARE_ROOT_DEPTH = 2 ** SQUARE_ROOT_BITS
)(
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in_1,
    output logic [DATA_OUT_BITS - 1:0] data_out,
    output logic data_out_ready
);
    logic square_root_in_ready;
    logic [SQUARE_ROOT_BITS - 1:0] square_root_in;
    logic [SQUARE_ROOT_BITS - 1:0] square_root_ram [SQUARE_ROOT_DEPTH - 1:0];
    logic square_root_out_ready;
    logic [SQUARE_ROOT_OUT_BITS - 1:0] square_root_out;
    
    initial begin
        for (integer i = 0; i < SQUARE_ROOT_DEPTH; i++) begin
            square_root_ram[i] <= ($floor($sqrt(i)));
        end
    end
    
    always_ff @(posedge clk) begin
            // Stage 1
        square_root_in_ready <= data_in_ready;
        square_root_in <= data_in_1[DATA_IN_BITS - 1:DATA_IN_BITS - SQUARE_ROOT_BITS];
        // Stage 2
        square_root_out_ready <= square_root_in_ready;
        square_root_out <= square_root_ram[square_root_in];
        // Stage 3
        data_out_ready <= square_root_out_ready;
        data_out <= square_root_out << SQUARE_ROOT_SHIFT_BITS;
    end
endmodule

// Magnitude module containing square sum and square_root
module magnitude #(
    parameter SQUARE_ROOT_BITS = 13,
    parameter DATA_IN_BITS = 16,
    parameter SQUARE_SUM_OUT_BITS = DATA_IN_BITS * 2 + 1,
    parameter DATA_OUT_BITS = DATA_IN_BITS + 1
)(
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in_1,
    input logic [DATA_IN_BITS - 1:0] data_in_2,
    input logic data_in_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out,
    output logic data_out_ready
);
    logic [SQUARE_SUM_OUT_BITS - 1:0] square_sum_out;
    logic square_sum_out_ready;

    square_sum #(
        .DATA_IN_BITS (DATA_IN_BITS)
    ) square_sum_1 (
        .clk (clk),
        .data_in_ready (data_in_ready),
        .data_in_1 (data_in_1),
        .data_in_2 (data_in_2),
        .data_out_ready (square_sum_out_ready),
        .data_out (square_sum_out)
    );
    
    square_root #(
        .DATA_IN_BITS (SQUARE_SUM_OUT_BITS),
        .SQUARE_ROOT_BITS (SQUARE_ROOT_BITS)
    ) square_root_1 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (square_sum_out_ready),
        .data_in_1 (square_sum_out),
        .data_out_ready (data_out_ready),
        .data_out (data_out)
    );
    
endmodule