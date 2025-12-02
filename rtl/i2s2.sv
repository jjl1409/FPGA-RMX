// Based on https://github.com/Digilent/Pmod-I2S2/blob/master/shared/src/hdl/axis_i2s2.v
// Converts i2s2 PMOD line in from serial to parallel, and vice versa for line out
module i2s2 #(
    parameter COUNT_BITS = 9,
    parameter DATA_BITS = 24
)(
    input logic clk,
    input logic rst,

    output logic tx_mclk, // JA[0]
    output logic tx_lrck, // JA[1]
    output logic tx_sclk, // JA[2]
    output logic tx_data, // JA[3]
    output logic rx_mclk, // JA[4]
    output logic rx_lrck, // JA[5]
    output logic rx_sclk, // JA[6]
    input  logic rx_data, // JA[7]
    output logic out_ready,
    output logic [DATA_BITS - 1:0] out_data_l,
    output logic [DATA_BITS - 1:0] out_data_r,
    input logic [DATA_BITS - 1:0] in_data_l,
    input logic [DATA_BITS - 1:0] in_data_r
);
    // Extra clocks
    // lrck which has 1/512 clk freq
    // sclk which has 1/8 clk freq
    logic lrck;
    logic sclk;

    logic [COUNT_BITS - 1:0] count = '0;    
    // Assignments
    assign lrck = count[8];
    assign sclk = count[2];
    assign tx_lrck = lrck;
    assign tx_sclk = sclk;
    assign tx_mclk = clk;
    assign rx_lrck = lrck;
    assign rx_sclk = sclk;
    assign rx_mclk = clk;

    // Count logic
    always_ff @(posedge clk) begin
        count <= count + 1;
    end

    localparam COUNT_DATA_SHIFT = 3'd7;
    localparam COUNT_DATA_SHIFT_START = 5'd1;
    localparam COUNT_DATA_SHIFT_END = 5'd24;
    localparam COUNT_DATA_SHIFT_RIGHT = 1'b1;
    localparam COUNT_DATA_END = 9'd511;

    // Tx logic 
    logic [DATA_BITS - 1:0] tx_data_l_shift = '0;
    logic [DATA_BITS - 1:0] tx_data_r_shift = '0;

    always_ff @(posedge clk) begin
        if (count == COUNT_DATA_SHIFT) begin
            tx_data_l_shift <= in_data_l;
            tx_data_r_shift <= in_data_r;
        end else if (count[2:0] == COUNT_DATA_SHIFT && count[7:3] >= COUNT_DATA_SHIFT_START && count[7:3] <= COUNT_DATA_SHIFT_END) begin
            if (count[8] == COUNT_DATA_SHIFT_RIGHT) begin
                tx_data_r_shift <= {tx_data_r_shift[DATA_BITS - 2:0], 1'b0};
            end else
                tx_data_l_shift <= {tx_data_l_shift[DATA_BITS - 2:0], 1'b0}; 
        end
    end

    always_comb begin
        if (count[7:3] >= COUNT_DATA_SHIFT_START && count[7:3] <= COUNT_DATA_SHIFT_END) begin
            if (count[8] == COUNT_DATA_SHIFT_RIGHT) begin
                tx_data = tx_data_r_shift[DATA_BITS - 1];
            end else begin
                tx_data = tx_data_l_shift[DATA_BITS - 1];
            end
        end else begin
            tx_data = 1'b0;
        end
    end

    // Rx logic
    logic [DATA_BITS - 1:0] rx_data_l_shift = '0;
    logic [DATA_BITS - 1:0] rx_data_r_shift = '0;

    always_ff @(posedge clk) begin
        if (count[2:0] == COUNT_DATA_SHIFT && count[7:3] >= COUNT_DATA_SHIFT_START && count[7:3] <= COUNT_DATA_SHIFT_END) begin
            if (count[8] == COUNT_DATA_SHIFT_RIGHT) begin
                rx_data_r_shift <= {rx_data_r_shift[DATA_BITS - 2:0], rx_data};
            end else
                rx_data_l_shift <= {rx_data_l_shift[DATA_BITS - 2:0], rx_data}; 
        end
    end

    // Module input/output logic
    always_ff @(posedge clk) begin
        if (count == COUNT_DATA_END) begin
            out_data_l <= rx_data_l_shift;
            out_data_r <= rx_data_r_shift;
            out_ready <= 1'b1;
        end else begin
            out_ready <= 1'b0;
        end
    end
    
endmodule