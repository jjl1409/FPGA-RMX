// Top level module for FPGA-RMX
module top #(
    parameter I2S2_CLK_DIV_BITS = 2,
    parameter I2S2_COUNT_BITS = 9,
    parameter AUDIO_DATA_BITS = 21,
    parameter LED_BITS = 14,
    parameter LED_COUNT_BITS = 22,
    parameter LED_COUNT_PERIOD = 2 ** LED_COUNT_BITS,
    parameter DECIMAL_BITS = 12,
    parameter BINARY_BITS = 4,
    parameter BINARY_WIDTH = 4,
    parameter CATHODE_BITS = 8,
    parameter ANODE_BITS = 4,
    parameter SEVEN_SEGMENT_DISPLAY_COUNT_BITS = 27,
    parameter SEVEN_SEGMENT_DISPLAY_REFRESH_BITS = 20,
    parameter AVERAGE_NUM = 32,
    parameter AVERAGE_BITS = 5
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
    
    output logic [LED_BITS - 1:0] leds,
    output logic [ANODE_BITS - 1:0] anode,
    output logic [CATHODE_BITS - 1:0] cathode
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
    logic i2s2_out_ready;
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
        .out_ready (i2s2_out_ready)
    );
    assign in_data_l = out_data_l;
    assign in_data_r = out_data_r;
    
    // Double moving average modules to measure power
    logic [AUDIO_DATA_BITS - 1:0] moving_average_data_out_1;
    logic [AUDIO_DATA_BITS - 1:0] moving_average_data_out_2;
    
    moving_average #(
        .DATA_IN_BITS (AUDIO_DATA_BITS),
        .DATA_OUT_BITS (AUDIO_DATA_BITS),
        .AVERAGE_NUM (AVERAGE_NUM),
        .AVERAGE_BITS (AVERAGE_BITS)
    ) moving_average_1 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (i2s2_out_ready),
        .data_in (out_data_l),
        .data_out (moving_average_data_out_1)
    );
    
    moving_average #(
        .DATA_IN_BITS (AUDIO_DATA_BITS),
        .DATA_OUT_BITS (AUDIO_DATA_BITS),
        .AVERAGE_NUM (AVERAGE_NUM),
        .AVERAGE_BITS (AVERAGE_BITS)
    ) moving_average_2 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (i2s2_out_ready),
        .data_in (moving_average_data_out_1),
        .data_out (moving_average_data_out_2)
    );
        
    // led_display module
    
    led_display #(
        .LED_BITS (LED_BITS),
        .LED_COUNT_BITS (LED_COUNT_BITS),
        .LED_COUNT_PERIOD (LED_COUNT_PERIOD),
        .DATA_BITS (AUDIO_DATA_BITS)
    ) led_display_1 (
        .clk (clk),
        .rst (rst),
        .data_in (moving_average_data_out_2),
        .leds (leds)
    );

    // seven segment display + double dabbler module
    logic double_dabble_data_in_ready = 1'b1;
    logic double_dabble_data_out_ready;
    logic [DECIMAL_BITS - 1:0] double_dabble_data_in = 12'd1200;
    logic [BINARY_BITS - 1:0] double_dabble_data_out [BINARY_WIDTH - 1:0];
    
    // test seven segment display incrementer
    logic [26:0] count;
    always_ff @(posedge clk) begin
        count <= count + 1;
        if (count == 0) begin
            if (double_dabble_data_in == 12'd1400) begin
                double_dabble_data_in <= 12'd1200;
            end else begin
                double_dabble_data_in <= double_dabble_data_in + 1;
            end
        end
    end

    double_dabble #(
        .DATA_IN_BITS (DECIMAL_BITS),
        .DATA_OUT_BITS (BINARY_BITS),
        .DATA_OUT_WIDTH (BINARY_WIDTH)
    ) double_dabble_1 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (double_dabble_data_in_ready),
        .data_in (double_dabble_data_in),
        .data_out_ready (double_dabble_data_out_ready),
        .data_out (double_dabble_data_out)
    );
    
    seven_segment_display #(
        .CATHODE_BITS (CATHODE_BITS),
        .ANODE_BITS (ANODE_BITS),
        .DATA_IN_BITS (BINARY_BITS),
        .DATA_IN_WIDTH (BINARY_WIDTH),
        .COUNT_BITS (SEVEN_SEGMENT_DISPLAY_COUNT_BITS),
        .REFRESH_BITS (SEVEN_SEGMENT_DISPLAY_REFRESH_BITS)
    ) seven_segment_display_1 (
        .clk (clk),
        .rst (rst),
        .data_in (double_dabble_data_out),
        .anode_out (anode),
        .cathode_out (cathode)
    );
    


endmodule
