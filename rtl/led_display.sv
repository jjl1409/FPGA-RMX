module led_display #(
    parameter LED_BITS = 16,
    parameter LED_COUNT_BITS = 28,
    parameter DATA_IN_BITS = 24
)(
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in,
    input logic transient,
    output logic [LED_BITS - 1:0] leds
);
    localparam LED_BEAT_BIT = LED_BITS - 1;
    localparam LED_DISPLAY_BITS = LED_BITS - 2;
    localparam LED_COUNT_MAX = 2 ** LED_COUNT_BITS - 1;

    // Volume LED logic
    logic [LED_COUNT_BITS - 1:0] count = '0;   

    always_ff @(posedge clk) begin
        if (transient) begin
            count <= 0;
            leds[LED_BEAT_BIT] <= 1;
        end else begin
            count <= count + 1;
        end
        if (count == LED_COUNT_MAX) begin
            for (int i = 0; i < LED_DISPLAY_BITS; i++) begin
                // Max value is (2 ** DATA_IN_BITS - 1 / sqrt(2)/ so approximate with 10/7
                if (data_in >= (((2 ** DATA_IN_BITS) - 1) * (i + 1) * 7) / (LED_DISPLAY_BITS * 10)) begin 
                    leds[i] <= 1'b1;
                end else begin
                    leds[i] <= 1'b0;
                end
            end
            leds[LED_BEAT_BIT] <= 0;
        end
    end
endmodule