
module adder_tree #(
    parameter DATA_IN_BITS = 29,
    parameter DATA_IN_WIDTH = 64,
    parameter DATA_OUT_BITS = 17,
    parameter SUM_BITS = DATA_IN_BITS + $clog2(DATA_IN_BITS),
    parameter STAGES = 6
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in [DATA_IN_WIDTH - 1:0],
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out
);
    logic [STAGES - 1:0] data_out_ready_shift;
    // Data out shift
    always_ff @(posedge clk) begin
        data_out_ready_shift <= {data_out_ready_shift[STAGES - 2:0], data_in_ready};
    end
    assign data_out_ready = data_out_ready_shift[STAGES - 1];
    // Adder tree
    logic [SUM_BITS - 1:0] adder [DATA_IN_WIDTH - 1:0];
    always_ff @(posedge clk) begin
        for (int i = 1; i < DATA_IN_WIDTH; i = i + 1) begin
            if (i >= DATA_IN_WIDTH / 2) begin
                adder[i] <= data_in[i] + data_in[i - DATA_IN_WIDTH / 2];
            end else begin
                adder[i] <= adder[i * 2] + adder[i * 2 + 1];
            end
        end
        adder[0] <= adder[1];
    end
    assign data_out = adder[0][DATA_IN_BITS - 1 -: DATA_OUT_BITS];

endmodule

module fir_filter #(
    parameter DATA_IN_BITS = 17,
    parameter DATA_OUT_BITS = 17,
    parameter FILTER_BITS = 12,
    parameter FILTER_TAPS = 64,
    parameter PRODUCT_BITS = DATA_IN_BITS + FILTER_BITS,
    parameter ADDER_BITS = PRODUCT_BITS + $clog2(DATA_IN_BITS + FILTER_BITS),
    parameter ADDER_STAGES = $clog2(FILTER_TAPS),
    parameter string COEFFICIENTS_FILE
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic data_out_ready,
    output logic [DATA_OUT_BITS - 1:0] data_out
);
    // Load coefficients
    logic [FILTER_BITS - 1:0] filter_coefficients [0:FILTER_TAPS - 1];
    initial begin
        $readmemb(COEFFICIENTS_FILE, filter_coefficients);
    end
    // Stage 0: Shift register
    logic products_in_ready;
    logic products_out_ready;

    logic [DATA_IN_BITS - 1:0] data_in_shift [FILTER_TAPS - 1:0] = '{default: '0};

    always_ff @(posedge clk) begin
        if (data_in_ready) begin
            data_in_shift[0] <= data_in;
            for (int i = 1; i < FILTER_TAPS; i = i + 1) begin
                data_in_shift[i] <= data_in_shift[i - 1];
            end
        end
        products_in_ready <= data_in_ready;
    end

    // Stage 1: Filter coefficient * data_in = products
    logic [PRODUCT_BITS - 1:0] products [FILTER_TAPS - 1:0];

    always_ff @(posedge clk) begin
        for (int i = 0; i < FILTER_TAPS; i = i + 1) begin
            products[i] <= filter_coefficients[i] * data_in_shift[i];
        end
        products_out_ready <= products_in_ready;
    end

    // Stage 2: Sum products with adder
    adder_tree #(
        .DATA_IN_BITS (PRODUCT_BITS),
        .DATA_OUT_BITS (DATA_OUT_BITS),
        .DATA_IN_WIDTH (FILTER_TAPS),
        .STAGES (ADDER_STAGES)
    ) adder_0 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (products_out_ready),
        .data_in (products),
        .data_out_ready (data_out_ready),
        .data_out (data_out)
    );

endmodule

