`timescale 1ns/1ps

// Testbench for magnitude module.
module magnitude_tb #(
    parameter SQUARE_ROOT_BITS = 13,
    parameter INPUT_BITS = 16,
    parameter SQUARE_SUM_OUTPUT_BITS = INPUT_BITS * 2 + 1,
    parameter OUTPUT_BITS = INPUT_BITS + 1
)();

    // DUT inputs/outputs
    logic clk;
    logic rst;
    logic [INPUT_BITS - 1:0] input_1;
    logic [INPUT_BITS - 1:0] input_2;
    logic input_ready;
    logic [OUTPUT_BITS - 1:0] output_1;
    logic output_ready;

    // DUT
    magnitude #(
        .SQUARE_ROOT_BITS (SQUARE_ROOT_BITS),
        .INPUT_BITS (INPUT_BITS)
    ) dut (
        .clk (clk),
        .rst (rst),
        .input_ready (input_ready),
        .input_1 (input_1),
        .input_2 (input_2),
        .output_ready (output_ready),
        .output_1 (output_1)
    );

    // Clock generation (estimate 10ns clock)
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end

    // Stimulus/testing logic
    integer fd;
    string input_1_file;
    string input_2_file;
    string square_sum_1_file;
    string magnitude_1_file;
    string line;

    logic [INPUT_BITS - 1:0] input_1_q [$];
    logic [INPUT_BITS - 1:0] input_2_q [$];
    logic [SQUARE_SUM_OUTPUT_BITS - 1:0] square_sum_1_q [$];
    logic [OUTPUT_BITS - 1:0] magnitude_1_q [$];

    logic [INPUT_BITS - 1:0] input_1_read;
    logic [INPUT_BITS - 1:0] input_2_read;
    logic [SQUARE_SUM_OUTPUT_BITS - 1:0] square_sum_1_read;
    logic [OUTPUT_BITS - 1:0] magnitude_1_read;

    logic [SQUARE_SUM_OUTPUT_BITS - 1:0] square_sum_1_expected;
    logic [OUTPUT_BITS - 1:0] magnitude_1_expected;
    logic done;


    // Reset and load stimulus
    initial begin
        rst = 1'b1;
        done = 1'b0;
        input_1 = 0;
        input_2 = 0;
        input_ready = 1'b0;

        input_1_file = "easemymind_input_1.csv";
        input_2_file = "easemymind_input_2.csv";
        square_sum_1_file = "easemymind_square_sum_1.csv";
        magnitude_1_file = "easemymind_magnitude_1.csv";
        
        fd = $fopen(input_1_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", input_1_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", input_1_read);
            input_1_q.push_back(input_1_read);
        end
        $fclose(fd);

        fd = $fopen(input_2_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", input_2_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", input_2_read);
            input_2_q.push_back(input_2_read);
        end
        $fclose(fd);

        fd = $fopen(square_sum_1_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", square_sum_1_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", square_sum_1_read);
            square_sum_1_q.push_back(square_sum_1_read);
        end
        $fclose(fd);

        fd = $fopen(magnitude_1_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", magnitude_1_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", magnitude_1_read);
            magnitude_1_q.push_back(magnitude_1_read);
        end
        $fclose(fd);
        
        @(posedge clk);
        rst = 1'b0;
        $display("%t: Stimulus files loaded.", $time);
        $display("%t: Input 1 loaded: %d samples.", $time, input_1_q.size());
        $display("%t: Input 2 loaded: %d samples.", $time, input_2_q.size());
        $display("%t: Square sum 1 loaded: %d samples.", $time, square_sum_1_q.size());
        $display("%t: Magnitude 1 loaded: %d samples.", $time, magnitude_1_q.size());
        @(posedge clk);
        repeat (50) @(posedge clk);

        // Begin verification
        $display("%t: Beginning verification.", $time);
        @(posedge clk);
        input_ready <= 1'b1;

        @(posedge done);
        $display("%t: Test passed", $time);
        $finish;
    end

    // Clocked DUT stimulus
    always @(negedge clk) begin
        if (input_ready) begin
            if (input_1_q.size > 0) begin
                input_1 <= input_1_q.pop_front();
            end
            if (input_2_q.size > 0) begin
                input_2 <= input_2_q.pop_front();
            end
        end
    end

    // Checker
    always @(posedge clk) begin
        if (dut.square_sum_output_ready) begin
            if (square_sum_1_q.size() > 0) begin
                square_sum_1_expected = square_sum_1_q.pop_front;
                if (dut.square_sum_output !== square_sum_1_expected) begin
                    $display("%t: Mismatch in square sum output: Expected %d, got %d", $time, square_sum_1_expected, dut.square_sum_output);
                    $fatal;
                end
            end
        end
        if (output_ready) begin 
            if (magnitude_1_q.size() > 0) begin
                magnitude_1_expected = magnitude_1_q.pop_front;
                if (output_1 !== magnitude_1_expected) begin
                    $display("%t: Mismatch in magnitude output: Expected %d, got %d", $time, magnitude_1_expected, output_1);
                    $fatal;
                end
            end else begin
                done <= 1'b1;
            end
        end
    end
    
    // 
endmodule



