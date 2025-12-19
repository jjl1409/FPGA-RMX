// Generates a transient by adding a drum sample to the incoming audio input
// This is triggered with an internal counter connected to the samples between beats measurement
// When a transient is received, it will set the internal counter to 0
// The transient will play [samples between beats] after the transient
// If the transient is not received and the counter hits samples between beats, reset and timeout
// The switches control the samples between beats (e.g. switch 0 corresponds to 1x, switch 1 corresponds to 1/2x, switch 3 corresponds to 1/4x, switch 4 corresponds to 1/8x)
// This represents a drum roll (samples between beats decreases as note length decreases)
module transient #(
    parameter SWITCH_BITS = 4,
    parameter BPM_BITS = 11,
    parameter DATA_IN_BITS = 24,
    parameter DATA_OUT_BITS = 24,
    parameter DECIMATION_BITS = 6,
    parameter COUNT_BITS = DECIMATION_BITS + BPM_BITS,
    parameter TRANSIENT_DEPTH = 26495,
    parameter string TRANSIENT_FILE
) (
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in_l,
    input logic [DATA_IN_BITS - 1:0] data_in_r,
    input logic transient,
    input logic [BPM_BITS - 1:0] bpm,
    input logic [SWITCH_BITS - 1:0] switch,
    output logic [DATA_IN_BITS - 1:0] data_out_l,
    output logic [DATA_OUT_BITS - 1:0] data_out_r
);
    logic [COUNT_BITS - 1:0] count = '0;
    logic [COUNT_BITS - 1:0] calculated_bpm;
    logic [DATA_IN_BITS - 1:0] transient_ram [TRANSIENT_DEPTH - 1 : 0];

    initial begin
        $readmemb(TRANSIENT_FILE, transient_ram);
    end    

    always_ff @(posedge clk) begin
        if (transient || count == calculated_bpm - 1) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end
        if (switch[3]) begin
            calculated_bpm <= bpm << (DECIMATION_BITS - 3);
        end else if (switch[2]) begin
            calculated_bpm <= bpm << (DECIMATION_BITS - 2);
        end else if (switch[1]) begin
            calculated_bpm <= bpm << (DECIMATION_BITS - 1);
        end else if (switch[0]) begin
            calculated_bpm <= bpm << (DECIMATION_BITS);
        end else
        if (calculated_bpm < TRANSIENT_DEPTH && switch != 4'b0) begin
            data_out_l <= data_in_l + transient_ram[calculated_bpm];
            data_out_r <= data_in_r + transient_ram[calculated_bpm];
        end else begin
            data_out_l <= data_in_l;
            data_out_r <= data_in_r;
        end            
    end
endmodule
