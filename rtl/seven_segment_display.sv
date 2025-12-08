module seven_segment_display #(
    parameter CATHODE_BITS = 8,
    parameter ANODE_BITS = 4,
    parameter DATA_IN_BITS = 4,
    parameter DATA_IN_WIDTH = 4,
    parameter COUNT_BITS = 27,
    parameter REFRESH_BITS = 20,
    parameter SELECT_BITS = 2
)(
    input logic clk,
    input logic rst,
    input logic [DATA_IN_BITS - 1:0] data_in [DATA_IN_WIDTH],
    output logic [ANODE_BITS - 1:0] anode_out,
    output logic [CATHODE_BITS - 1:0] cathode_out
);  
    // Count logic
    logic [COUNT_BITS - 1:0] count = '0;
    logic [SELECT_BITS - 1:0] select;
    always_ff @(posedge clk) begin
        count <= count + 1;
    end

    assign select = count[REFRESH_BITS - 1 : REFRESH_BITS - 2];

    // Anode and cathode display logic
    // Anode represents which LED is displayed, cathode represents the number
    // Active bit is reversed (for some reason numbers are reversed)
    localparam logic [ANODE_BITS - 1:0] anode [0:3]= {
        4'b0111,
        4'b1011,
        4'b1101,
        4'b1110
        };
    localparam logic [CATHODE_BITS - 1:0] cathode [0:15] = {
        8'b11000000,
        8'b11111001,
        8'b10100100,
        8'b10110000,
        8'b10011001, 
        8'b10010010,
        8'b10000010,
        8'b11111000,
        8'b10000000,
        8'b10010000,
        8'b10111111,
        8'b10111111,
        8'b10111111,
        8'b10111111,
        8'b10111111,
        8'b10111111
        };
    logic [DATA_IN_BITS - 1:0] cathode_in [DATA_IN_BITS];

    always_ff @(posedge clk) begin
        if (count == 0) begin
            for (int i = 0; i < DATA_IN_BITS; i++) begin
                cathode_in[i] <= data_in[i];
            end
        end
    end

    always_ff @(posedge clk) begin
        case (select)
        2'b00: begin
            anode_out <= anode[0];
            cathode_out <= cathode[cathode_in[0]];
        end
        2'b01: begin
            anode_out <= anode[1];
            cathode_out <= {1'b0, cathode[cathode_in[1]][CATHODE_BITS - 2:0]};
        end
        2'b10: begin
            anode_out <= anode[2];
            cathode_out <= cathode[cathode_in[2]];
        end
        2'b11: begin
            anode_out <= anode[3];
            cathode_out <= cathode[cathode_in[3]];
        end
        endcase
    end

    
endmodule