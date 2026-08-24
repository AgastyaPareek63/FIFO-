`timescale 1ns/1ps

module width_converter_tb;

    parameter IN_WIDTH  = 8;
    parameter OUT_WIDTH = 16;

    reg clk;
    reg rst;
    reg valid_in;
    reg [IN_WIDTH-1:0] data_in;

    wire valid_out;
    wire [OUT_WIDTH-1:0] data_out;


    // DUT
    width_converter #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .data_out(data_out)
    );


    // Clock
    initial clk = 0;
    always #5 clk = ~clk;


    initial begin

        // Initial values
        rst = 1;
        valid_in = 0;
        data_in = 0;

        // Reset
        #20;
        rst = 0;


        // First 8-bit data
        @(negedge clk);
        valid_in = 1;
        data_in = 8'hA5;

        // Second 8-bit data
        @(negedge clk);
        data_in = 8'h3C;

        @(negedge clk);
        valid_in = 0;

        #10;

        // Check output: {3C, A5}
        if (valid_out && data_out == 16'h3CA5)
            $display("PASS: Width conversion successful");
        else
            $display("FAIL: Expected 3CA5, Got %h", data_out);


        // Second conversion
        @(negedge clk);
        valid_in = 1;
        data_in = 8'h55;

        @(negedge clk);
        data_in = 8'hAA;

        @(negedge clk);
        valid_in = 0;

        #10;

        // Check output: {AA, 55}
        if (data_out == 16'hAA55)
            $display("PASS: Second conversion successful");
        else
            $display("FAIL: Expected AA55, Got %h", data_out);


        #20;
        $finish;

    end

endmodule
