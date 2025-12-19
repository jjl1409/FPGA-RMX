// Top level module for FPGA-RMX
module top #(
    parameter I2S2_CLK_DIV_BITS = 2,
    parameter I2S2_COUNT_BITS = 9,
    parameter AUDIO_DATA_BITS = 21,
    parameter LED_BITS = 16,
    parameter LED_COUNT_BITS = 21,
    parameter LED_COUNT_PERIOD = 2 ** LED_COUNT_BITS,
    parameter BINARY_BITS = 12,
    parameter DECIMAL_BITS = 4,
    parameter DECIMAL_WIDTH = 4,
    parameter CATHODE_BITS = 8,
    parameter ANODE_BITS = 4,
    parameter SEVEN_SEGMENT_DISPLAY_COUNT_BITS = 27,
    parameter SEVEN_SEGMENT_DISPLAY_REFRESH_BITS = 20,
    parameter AVERAGE_BITS = 4,
    parameter AVERAGE_NUM = 2 ** AVERAGE_BITS,
    parameter SQUARE_ROOT_BITS = 13,
    parameter SQUARE_SUM_OUT_BITS = 33,
    parameter MAGNITUDE_DATA_IN_BITS = 16,
    parameter DSP_DATA_BITS = 17,
    parameter FILTER_BITS = 12,
    parameter FILTER_TAPS = 64,
    parameter COEFFICIENTS_FILE = "fir_filter_coefficients.mem",
    parameter BPM_BITS = 11,
    parameter THRESHOLD = 80000,
    parameter MIN_PERIOD = 1181,
    parameter MAX_PERIOD = 1378,
    parameter SAMPLING_RATE = 44100,
    parameter AVERAGE_BPM_BITS = 8,
    parameter AVERAGE_BPM_NUM = 2 ** AVERAGE_BPM_BITS,
    parameter AVERAGE_BPM_COUNT_BITS = 21,
    parameter SWITCH_BITS = 4,
    parameter TRANSIENT_DECIMATION_BITS = 6,
    parameter TRANSIENT_DEPTH = 26495,
    parameter string TRANSIENT_FILE = "snare.mem"
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
    input logic [SWITCH_BITS - 1:0] sw,
    
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
    
    logic audio_out_ready_prev;
    logic audio_out_ready;
    always @(posedge clk) begin
        audio_out_ready_prev <= i2s2_out_ready;
        if (!audio_out_ready_prev && i2s2_out_ready) begin
            audio_out_ready <= 1'b1;
        end else begin
            audio_out_ready <= 1'b0;
        end
    end

    // Magnitude module to take RMS of left and right audio signals
    logic magnitude_data_out_ready;
    logic [DSP_DATA_BITS - 1:0] magnitude_data_out;
    magnitude #(
        .SQUARE_ROOT_BITS (SQUARE_ROOT_BITS),
        .SQUARE_SUM_OUT_BITS (SQUARE_SUM_OUT_BITS),
        .DATA_IN_BITS (MAGNITUDE_DATA_IN_BITS),
        .DATA_OUT_BITS (DSP_DATA_BITS)
    ) magnitude_i (
        .clk (clk),
        .rst (rst),
        .data_in_ready (audio_out_ready),
        .data_in_1 (out_data_r[AUDIO_DATA_BITS - 1 -: MAGNITUDE_DATA_IN_BITS]),
        .data_in_2 (out_data_l[AUDIO_DATA_BITS - 1 -: MAGNITUDE_DATA_IN_BITS]),
        .data_out_ready (magnitude_data_out_ready),
        .data_out (magnitude_data_out)
    );    
    
    // Moving average module to decimate/average every 16 inputs
    logic moving_average_data_out_ready;
    logic [DSP_DATA_BITS - 1:0] moving_average_data_out;
    
    
    moving_average #(
        .DATA_IN_BITS (DSP_DATA_BITS),
        .DATA_OUT_BITS (DSP_DATA_BITS),
        .AVERAGE_NUM (AVERAGE_NUM),
        .AVERAGE_BITS (AVERAGE_BITS)
    ) moving_average_1 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (magnitude_data_out_ready),
        .data_in (magnitude_data_out),
        .data_out_ready (moving_average_data_out_ready),
        .data_out (moving_average_data_out)
    );

    // FIR filter module to apply bandpass filter over 64 inputs
    logic fir_filter_data_out_ready;
    logic [DSP_DATA_BITS - 1:0] fir_filter_data_out; 

    fir_filter #(
        .DATA_IN_BITS (DSP_DATA_BITS),
        .DATA_OUT_BITS (DSP_DATA_BITS),
        .FILTER_BITS (FILTER_BITS),
        .FILTER_TAPS (FILTER_TAPS),
        .COEFFICIENTS_FILE (COEFFICIENTS_FILE)
    ) fir_filter_i (
        .clk (clk),
        .rst (rst),
        .data_in_ready (moving_average_data_out_ready),
        .data_in (moving_average_data_out),
        .data_out_ready (fir_filter_data_out_ready),
        .data_out (fir_filter_data_out)
    );

    // BPM detection module to get BPM and transient information
    logic bpm_detection_data_out_ready;
    logic transient_out;
    logic [BPM_BITS - 1:0] bpm_out;

    bpm_detection #(
        .DATA_IN_BITS (DSP_DATA_BITS),
        .BPM_BITS (BPM_BITS),
        .THRESHOLD (THRESHOLD),
        .MIN_PERIOD (MIN_PERIOD),
        .MAX_PERIOD (MAX_PERIOD)
    ) bpm_detection_i (
        .clk (clk),
        .rst (rst),
        .data_in_ready (fir_filter_data_out_ready),
        .data_in (fir_filter_data_out),
        .data_out_ready(bpm_detection_data_out_ready),
        .transient_out (transient_out),
        .bpm_out (bpm_out)
    );
    // Extra moving average for bpm_out
    
    logic [AVERAGE_BPM_COUNT_BITS - 1:0] average_bpm_count = '0;
    logic average_bpm_in_ready;
    logic average_bpm_out_ready;
    logic [AVERAGE_BPM_BITS + BPM_BITS - 1:0] average_bpm_out;
    
    always_ff @(posedge clk) begin
        average_bpm_count <= average_bpm_count + 1;
    end
    assign average_bpm_in_ready = average_bpm_count == 0;   
    
    moving_average #(
        .DATA_IN_BITS (BPM_BITS + AVERAGE_BPM_BITS),
        .DATA_OUT_BITS (BPM_BITS + AVERAGE_BPM_BITS),
        .AVERAGE_NUM (AVERAGE_BPM_NUM),
        .AVERAGE_BITS (AVERAGE_BPM_BITS)
    ) moving_average_2 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (average_bpm_in_ready),
        .data_in ({bpm_out, {AVERAGE_BPM_BITS{1'b0}}}),
        .data_out_ready (average_bpm_out_ready),
        .data_out (average_bpm_out)
    );

    // Transient to play snare sound based on switches
    transient #(
        .SWITCH_BITS (SWITCH_BITS),
        .BPM_BITS (BPM_BITS),
        .DATA_IN_BITS (AUDIO_DATA_BITS),
        .DATA_OUT_BITS (AUDIO_DATA_BITS),
        .DECIMATION_BITS (TRANSIENT_DECIMATION_BITS),
        .TRANSIENT_DEPTH (TRANSIENT_DEPTH),
        .TRANSIENT_FILE (TRANSIENT_FILE)
    ) transient_i (
        .clk (clk),
        .rst (rst),
        .data_in_l (out_data_l),
        .data_in_r (out_data_r),
        .transient (transient_out),
        .bpm (bpm_out),
        .switch (sw),
        .data_out_l (in_data_l),
        .data_out_r (in_data_r)
    );
    
    // samples_to_bpm module to convert bpm_out (in samples between beats) to bpm in binary
    logic [BINARY_BITS - 1:0] samples_to_bpm_out;
    samples_to_bpm #(
        .DATA_IN_BITS (BPM_BITS),
        .DATA_OUT_BITS (BINARY_BITS),
        .MIN_PERIOD (MIN_PERIOD),
        .MAX_PERIOD (MAX_PERIOD),
        .SAMPLING_RATE (SAMPLING_RATE),
        .DECIMATION_FACTOR (AVERAGE_NUM)
    ) samples_to_bpm_i (
        .clk (clk),
        .rst (rst),
        .data_in (average_bpm_out[BPM_BITS + AVERAGE_BPM_BITS - 1 -:BPM_BITS]),
        .data_out (samples_to_bpm_out)
    );

    
    // led_display module
    
    led_display #(
        .LED_BITS (LED_BITS),
        .LED_COUNT_BITS (LED_COUNT_BITS),
        .DATA_IN_BITS (DSP_DATA_BITS)
    ) led_display_1 (
        .clk (clk),
        .rst (rst),
        .data_in (moving_average_data_out),
        .transient (transient_out),
        .leds (leds)
    );

    // seven segment display + double dabbler module
    logic double_dabble_data_in_ready = 1'b1;
    logic double_dabble_data_out_ready;
    logic [DECIMAL_BITS - 1:0] double_dabble_data_out [DECIMAL_WIDTH - 1:0];

    double_dabble #(
        .DATA_IN_BITS (BINARY_BITS),
        .DATA_OUT_BITS (DECIMAL_BITS),
        .DATA_OUT_WIDTH (DECIMAL_WIDTH)
    ) double_dabble_1 (
        .clk (clk),
        .rst (rst),
        .data_in_ready (double_dabble_data_in_ready),
        .data_in (samples_to_bpm_out),
        .data_out_ready (double_dabble_data_out_ready),
        .data_out (double_dabble_data_out)
    );
    
    seven_segment_display #(
        .CATHODE_BITS (CATHODE_BITS),
        .ANODE_BITS (ANODE_BITS),
        .DATA_IN_BITS (DECIMAL_BITS),
        .DATA_IN_WIDTH (DECIMAL_WIDTH),
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
