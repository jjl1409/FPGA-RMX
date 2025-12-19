module bpm_detection #(
    parameter DATA_IN_BITS = 17,
    parameter BPM_BITS = 11,
    parameter THRESHOLD = 70000,
    parameter MIN_PERIOD = 1181,
    parameter MAX_PERIOD = 1378
) (
    input logic clk,
    input logic rst,
    input logic data_in_ready,
    input logic [DATA_IN_BITS - 1:0] data_in,
    output logic data_out_ready,
    output logic transient_out,
    output logic [BPM_BITS - 1:0] bpm_out
);
    localparam STATE_BITS = 2;
    localparam [STATE_BITS - 1:0]
        IDLE = 2'b00,
        COUNT = 2'b01,
        TRANSIENT = 2'b10,
        TIMEOUT = 2'b11;
    logic [BPM_BITS - 1:0] count = '0;
    logic [BPM_BITS - 1:0] bpm = MIN_PERIOD;

    // state logic
    logic [STATE_BITS - 1:0] state, next;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next;
        end
    end

    always_comb begin
        next = IDLE;
        case (state)
            IDLE: begin
                next = COUNT;
            end
            COUNT: begin
                if (count >= MIN_PERIOD && data_in > THRESHOLD) begin
                    next = TRANSIENT;
                end else if (count >= MAX_PERIOD) begin
                    next = TIMEOUT;
                end else begin
                    next = COUNT;
                end
            end
            TRANSIENT: begin
                next = COUNT;
            end
            TIMEOUT: begin
                next = COUNT;
            end
        endcase
    end

    // Synchronous state logic
    always @(posedge clk) begin
        case (next)
            IDLE: ;
            COUNT: begin
                if (data_in_ready) begin
                    count <= count + 1;
                end
                transient_out <= 0;
            end
            TRANSIENT: begin
                bpm <= count;
                count <= 1;
                transient_out <= 1;
            end
            TIMEOUT: begin
                count <= MAX_PERIOD - bpm + 1;
                transient_out <= 0;
            end
        endcase
    end
    assign data_out_ready = data_in_ready;
    assign bpm_out = bpm;
endmodule