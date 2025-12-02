`timescale 1ns/1ps

// Testbench for magnitude module.
module magnitude_tb #(
    parameter SQUARE_ROOT_BITS = 13,
    parameter DATA_IN_BITS = 16,
    parameter SQUARE_SUM_OUT_BITS = DATA_IN_BITS * 2 + 1,
    parameter DATA_OUT_BITS = DATA_IN_BITS + 1
)();

    // DUT inputs/outputs
    logic clk;
    logic rst;
    logic [DATA_IN_BITS - 1:0] data_in_1;
    logic [DATA_IN_BITS - 1:0] data_in_2;
    logic data_in_ready;
    logic [DATA_OUT_BITS - 1:0] data_out;
    logic data_out_ready;

    // DUT
    magnitude #(
        .SQUARE_ROOT_BITS (SQUARE_ROOT_BITS),
        .DATA_IN_BITS (DATA_IN_BITS)
    ) dut (
        .clk (clk),
        .rst (rst),
        .data_in_ready (data_in_ready),
        .data_in_1 (data_in_1),
        .data_in_2 (data_in_2),
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
    integer fd;
    string data_in_1_file;
    string data_in_2_file;
    string square_sum_1_file;
    string magnitude_1_file;
    string line;

    logic [DATA_IN_BITS - 1:0] data_in_1_q [$];
    logic [DATA_IN_BITS - 1:0] data_in_2_q [$];
    logic [SQUARE_SUM_OUT_BITS - 1:0] square_sum_1_q [$];
    logic [DATA_OUT_BITS - 1:0] magnitude_1_q [$];

    logic [DATA_IN_BITS - 1:0] data_in_1_read;
    logic [DATA_IN_BITS - 1:0] data_in_2_read;
    logic [SQUARE_SUM_OUT_BITS - 1:0] square_sum_1_read;
    logic [DATA_OUT_BITS - 1:0] magnitude_1_read;

    logic [SQUARE_SUM_OUT_BITS - 1:0] square_sum_1_expected;
    logic [DATA_OUT_BITS - 1:0] magnitude_1_expected;
    logic done;


    // Reset and load stimulus
    initial begin
        rst = 1'b1;
        done = 1'b0;
        data_in_1 = 0;
        data_in_2 = 0;
        data_in_ready = 1'b0;

        data_in_1_file = "easemymind_input_1.csv";
        data_in_2_file = "easemymind_input_2.csv";
        square_sum_1_file = "easemymind_square_sum_1.csv";
        magnitude_1_file = "easemymind_magnitude_1.csv";
        
        fd = $fopen(data_in_1_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", data_in_1_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", data_in_1_read);
            data_in_1_q.push_back(data_in_1_read);
        end
        $fclose(fd);

        fd = $fopen(data_in_2_file, "r");
        if (fd == 0) begin
            $display("Error: Could not open %s", data_in_2_file);
            $fatal;
        end
        while ($fgets(line, fd)) begin
            $sscanf(line, "%d", data_in_2_read);
            data_in_2_q.push_back(data_in_2_read);
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
        $display("%t: Data in 1 loaded: %d samples.", $time, data_in_1_q.size());
        $display("%t: Data in 2 loaded: %d samples.", $time, data_in_2_q.size());
        $display("%t: Square sum 1 loaded: %d samples.", $time, square_sum_1_q.size());
        $display("%t: Magnitude 1 loaded: %d samples.", $time, magnitude_1_q.size());
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
            if (data_in_1_q.size > 0) begin
                data_in_1 <= data_in_1_q.pop_front();
            end
            if (data_in_2_q.size > 0) begin
                data_in_2 <= data_in_2_q.pop_front();
            end
        end
    end

    // Checker
    always @(posedge clk) begin
        if (dut.square_sum_out_ready) begin
            if (square_sum_1_q.size() > 0) begin
                square_sum_1_expected = square_sum_1_q.pop_front;
                if (dut.square_sum_out !== square_sum_1_expected) begin
                    $display("%t: Mismatch in square sum data out: Expected %d, got %d", $time, square_sum_1_expected, dut.square_sum_out);
                    $fatal;
                end
            end
        end
        if (data_out_ready) begin 
            if (magnitude_1_q.size() > 0) begin
                magnitude_1_expected = magnitude_1_q.pop_front;
                if (data_out !== magnitude_1_expected) begin
                    $display("%t: Mismatch in magnitude data out: Expected %d, got %d", $time, magnitude_1_expected, data_out);
                    $fatal;
                end
            end else begin
                done <= 1'b1;
            end
        end
    end
    
    // 
endmodule



