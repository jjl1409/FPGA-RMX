`timescale 1ns/1ps

// Testbench for magnitude module.
module double_dabble_tb #(
    parameter DATA_IN_BITS = 18,
    parameter DATA_OUT_BITS = 4,
    parameter DATA_OUT_WIDTH = 6,
    parameter ITERATIONS = 1000000
)();

    // DUT inputs/outputs
    logic clk;
    logic rst;
    logic data_in_ready;
    logic [DATA_IN_BITS - 1:0] data_in;
    logic data_out_ready;
    logic [DATA_OUT_BITS - 1:0] data_out [DATA_OUT_WIDTH - 1:0];

    // DUT
    double_dabble #(
        .DATA_IN_BITS (DATA_IN_BITS),
        .DATA_OUT_BITS (DATA_OUT_BITS),
        .DATA_OUT_WIDTH (DATA_OUT_WIDTH)
    ) dut (
        .clk (clk),
        .rst (rst),
        .data_in_ready (data_in_ready),
        .data_in (data_in),
        .data_out_ready (data_out_ready),
        .data_out (data_out)
    );

    // Clock generation (estimate 10ns clock)
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    // Stimulus/testing logic
    integer i;
    integer j;
    localparam DATA_IN_MAX = 2 ** DATA_IN_BITS - 1;

    logic [DATA_IN_BITS - 1:0] data_in_q [$];
    logic [DATA_OUT_BITS - 1:0] data_out_q [$] [DATA_OUT_WIDTH - 1:0];
    logic [DATA_IN_BITS - 1:0] data_in_generated;
    logic [DATA_OUT_BITS - 1:0] data_out_generated [DATA_OUT_WIDTH - 1:0];
    logic [DATA_OUT_BITS - 1:0] data_out_expected [DATA_OUT_WIDTH - 1:0];

    logic done;


    // Reset and load stimulus
    initial begin
        rst = 1'b1;
        done = 1'b0;
        data_in_generated = '0;
        data_in_ready = 1'b0;

        for (i = 0; i < ITERATIONS; i++) begin
            data_in_generated = $urandom_range(DATA_IN_MAX);
            data_in_q.push_back(data_in_generated);
            for (j = 0; j < DATA_OUT_WIDTH; j++) begin
                data_out_generated[j] = data_in_generated % 10;
                data_in_generated = data_in_generated / 10;
//                    $display("%t: Data_in: %d Data_out: %d", $time, data_in_generated,data_out_generated[j]);
            end
            data_out_q.push_back(data_out_generated);
        end
        
        @(posedge clk);
        rst = 1'b0;
        $display("%t: Random stimulus generated.", $time);
        $display("%t: Data in loaded: %d samples.", $time, data_in_q.size());
        $display("%t: Data out loaded: %d samples.", $time, data_out_q.size());
        @(posedge clk);
        repeat (50) @(posedge clk);

        // Begin verification
        $display("%t: Beginning verification.", $time);
        @(posedge clk);
        data_in_ready <= 1'b1;

        @(posedge done);
        $display("%t: Test passed", $time);
        $finish;
    end

    // Clocked DUT stimulus
    always @(negedge clk) begin
        if (data_in_ready) begin
            if (data_in_q.size > 0) begin
                data_in <= data_in_q.pop_front();
            end else begin
                data_in_ready <= 1'b0;
            end
        end
    end

    // Checker
    always @(posedge clk) begin
        if (data_out_ready) begin
            if (data_out_q.size() > 0) begin
                data_out_expected = data_out_q.pop_front;
                for (i = 0; i < DATA_OUT_WIDTH; i++) begin
                    if (data_out[i] !== data_out_expected[i]) begin
                        $display("%t: Mismatch in data out[%d]: Expected %d, got %d", $time, i, data_out_expected[i], data_out[i]);
                        $fatal;
                    end
                end
            end else begin
                done <= 1'b1;
            end
        end
    end
    
    // 
endmodule