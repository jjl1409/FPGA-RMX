// Square sum module
module square_sum #(
    parameter INPUT_BITS = 16,
    parameter PRODUCT_BITS = INPUT_BITS * 2,
    parameter OUTPUT_BITS = PRODUCT_BITS + 1
)(
    input logic clk,
    input logic input_ready,
    input logic [INPUT_BITS - 1:0] input_1,
    input logic [INPUT_BITS - 1:0] input_2,
    output logic output_ready,
    output logic [OUTPUT_BITS - 1:0] output_1
);
    logic [PRODUCT_BITS - 1:0] product_1;
    logic [PRODUCT_BITS - 1:0] product_2;
    logic product_ready;

    always_ff @(posedge clk) begin
        // Stage 1
        product_ready <= input_ready;
        product_1 <= input_1 * input_1;
        product_2 <= input_2 * input_2;
        // Stage 2
        output_1 <= product_1 + product_2;
        output_ready <= product_ready;
    end
endmodule

// Square root module
module square_root #(
    parameter INPUT_BITS = 33,
    parameter SQUARE_ROOT_BITS = 13,
    parameter SQUARE_ROOT_OUTPUT_BITS = SQUARE_ROOT_BITS / 2 + 1,
    parameter SQUARE_ROOT_SHIFT_BITS = (INPUT_BITS - SQUARE_ROOT_BITS) / 2,
    parameter OUTPUT_BITS = SQUARE_ROOT_OUTPUT_BITS + SQUARE_ROOT_SHIFT_BITS,
    parameter SQUARE_ROOT_DEPTH = 2 ** SQUARE_ROOT_BITS
)(
    input logic clk,
    input logic rst,
    input logic input_ready,
    input logic [INPUT_BITS - 1:0] input_1,
    output logic [OUTPUT_BITS - 1:0] output_1,
    output logic output_ready
);
    logic square_root_input_ready;
    logic [SQUARE_ROOT_BITS - 1:0] square_root_input;
    logic [SQUARE_ROOT_BITS - 1:0] square_root_ram [SQUARE_ROOT_DEPTH - 1:0];
    logic square_root_output_ready;
    logic [SQUARE_ROOT_OUTPUT_BITS - 1:0] square_root_output;
    
    initial begin
        for (integer i = 0; i < SQUARE_ROOT_DEPTH; i++) begin
            square_root_ram[i] <= ($floor($sqrt(i)));
        end
    end
    
    always_ff @(posedge clk) begin
            // Stage 1
        square_root_input_ready <= input_ready;
        square_root_input <= input_1[INPUT_BITS - 1:INPUT_BITS - SQUARE_ROOT_BITS];
        // Stage 2
        square_root_output_ready <= square_root_input_ready;
        square_root_output <= square_root_ram[square_root_input];
        // Stage 3
        output_ready <= square_root_output_ready;
        output_1 <= square_root_output << SQUARE_ROOT_SHIFT_BITS;
    end
endmodule

// Magnitude module containing square sum and square_root
module magnitude #(
    parameter SQUARE_ROOT_BITS = 13,
    parameter INPUT_BITS = 16,
    parameter SQUARE_SUM_OUTPUT_BITS = INPUT_BITS * 2 + 1,
    parameter OUTPUT_BITS = INPUT_BITS + 1
)(
    input logic clk,
    input logic rst,
    input logic [INPUT_BITS - 1:0] input_1,
    input logic [INPUT_BITS - 1:0] input_2,
    input logic input_ready,
    output logic [OUTPUT_BITS - 1:0] output_1,
    output logic output_ready
);
    logic [SQUARE_SUM_OUTPUT_BITS - 1:0] square_sum_output;
    logic square_sum_output_ready;

    square_sum #(
        .INPUT_BITS (INPUT_BITS)
    ) square_sum_1 (
        .clk (clk),
        .input_ready (input_ready),
        .input_1 (input_1),
        .input_2 (input_2),
        .output_ready (square_sum_output_ready),
        .output_1 (square_sum_output)
    );
    
    square_root #(
        .INPUT_BITS (SQUARE_SUM_OUTPUT_BITS),
        .SQUARE_ROOT_BITS (SQUARE_ROOT_BITS)
    ) square_root_1 (
        .clk (clk),
        .rst (rst),
        .input_ready (square_sum_output_ready),
        .input_1 (square_sum_output),
        .output_ready (output_ready),
        .output_1 (output_1)
    );
    
endmodule