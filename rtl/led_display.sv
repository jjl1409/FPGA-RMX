module led_display #(
    parameter LED_BITS = 16,
    parameter LED_COUNT_BITS = 28,
    parameter LED_COUNT_PERIOD = 2 ** LED_COUNT_BITS,
    parameter DATA_IN_BITS = 24
)(
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic [LED_BITS - 1:0] leds
);
    // LED logic
    logic [LED_COUNT_BITS - 1:0] count = '0;   
    always_ff @(posedge clk) begin
        count <= count + 1;
    end

    always_ff @(posedge clk) begin
        if (count == 1'b0) begin
            for (int i = 0; i < LED_BITS; i++) begin
                // Max value is (2 ** DATA_IN_BITS - 1 / sqrt(2)/ so approximate with 10/7
                if (data_in >= (((2 ** DATA_IN_BITS) - 1) * (i + 1) * 7) / (LED_BITS * 10)) begin 
                    leds[i] <= 1'b1;
                end else begin
                    leds[i] <= 1'b0;
                end
            end
        end
    end
endmodule