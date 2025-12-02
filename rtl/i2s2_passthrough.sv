// Based on https://github.com/Digilent/Pmod-I2S2/blob/master/shared/src/hdl/axis_i2s2.v
// Passthrough for i2s2 PMOD module
module i2s2_passthrough #(
    parameter COUNT_BITS = 9
)(
    input wire clk,
    input wire rst,

    output wire tx_mclk, // JA[0]
    output wire tx_lrck, // JA[1]
    output wire tx_sclk, // JA[2]
    output reg  tx_data, // JA[3]
    output wire rx_mclk, // JA[4]
    output wire rx_lrck, // JA[5]
    output wire rx_sclk, // JA[6]
    input  wire rx_data // JA[7]
);
    wire lrck;
    wire sclk;

    logic [COUNT_BITS - 1:0] count = 0;    
    // Assignments
    assign lrck = count[8];
    assign sclk = count[2];
    assign tx_lrck = lrck;
    assign tx_sclk = sclk;
    assign tx_mclk = clk;
    assign rx_lrck = lrck;
    assign rx_sclk = sclk;
    assign rx_mclk = clk;

    always_ff @(posedge clk) begin
        count <= count + 1;
    end

    assign tx_data = rx_data;   
endmodule