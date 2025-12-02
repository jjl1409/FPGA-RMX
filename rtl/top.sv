// Top level module for FPGA-RMX
module top #(
    parameter I2S2_CLK_DIV_BITS = 2,
    parameter I2S2_COUNT_BITS = 9,
    parameter AUDIO_DATA_BITS = 24,
    parameter LED_BITS = 14,
    parameter LED_COUNT_BITS = 20,
    parameter LED_COUNT_PERIOD = 2 ** LED_COUNT_BITS
)(
    input logic  sys_clk,
    output logic tx_mclk,
    output logic tx_lrck,
    output logic tx_sclk,
    output logic tx_data,
    output logic rx_mclk,
    output logic rx_lrck,
    output logic rx_sclk,
    input  logic rx_data,
    
    output logic [LED_BITS - 1:0] leds
);
    // Clocking logic
    logic clk;
    logic rst = 0;
    logic i2s2_clk;
    logic [I2S2_CLK_DIV_BITS - 1:0] i2s2_clk_count = 0;

    clk_wiz_0 clk_gen(
    // Clock out ports
    .clk_out (clk),     // output clk_out
   // Clock in ports
    .clk_in (sys_clk)      // input clk_in
    );

    always_ff @(posedge clk) begin
        i2s2_clk_count <= i2s2_clk_count + 1;
    end
    assign i2s2_clk = i2s2_clk_count[I2S2_CLK_DIV_BITS - 1];

    // I2S2 module
    logic [AUDIO_DATA_BITS - 1:0] out_data_l;
    logic [AUDIO_DATA_BITS - 1:0] out_data_r;
    logic [AUDIO_DATA_BITS - 1:0] in_data_l;
    logic [AUDIO_DATA_BITS - 1:0] in_data_r;
    logic out_ready;
    i2s2 #(
        .DATA_BITS (AUDIO_DATA_BITS),
        .COUNT_BITS (I2S2_COUNT_BITS)
    ) i2s2_1 (
        .clk (i2s2_clk),
        .rst (rst),
        .tx_mclk (tx_mclk),
        .tx_lrck (tx_lrck),
        .tx_sclk (tx_sclk),
        .tx_data (tx_data),
        .rx_mclk (rx_mclk),
        .rx_lrck (rx_lrck),
        .rx_sclk (rx_sclk),
        .rx_data (rx_data),
        .out_data_l (out_data_l),
        .out_data_r (out_data_r),
        .in_data_l (in_data_l),
        .in_data_r (in_data_r),
        .out_ready (out_ready)
    );
    assign in_data_l = out_data_l;
    assign in_data_r = out_data_r;

    // Volume module

    logic [AUDIO_DATA_BITS - 1:0] volume_data;
    always_ff @(posedge clk) begin
        volume_data <= out_data_l;
    end
    
    volume #(
        .LED_BITS (LED_BITS),
        .LED_COUNT_BITS (LED_COUNT_BITS),
        .LED_COUNT_PERIOD (LED_COUNT_PERIOD),
        .DATA_BITS (AUDIO_DATA_BITS)
    ) volume_1 (
        .clk (clk),
        .rst (rst),
        .data_in (volume_data),
        .leds (leds)
    );

endmodule
