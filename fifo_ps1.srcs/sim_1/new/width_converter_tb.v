`timescale 1ns/1ps

module width_converter_tb;

    reg clk;
    reg rst;

    reg valid_in;
    reg [7:0] data_in;

    wire valid_out;
    wire [15:0] data_out;


    //--------------------------------------------------
    // DUT
    //--------------------------------------------------

    width_converter dut (

        .clk(clk),
        .rst(rst),

        .valid_in(valid_in),
        .data_in(data_in),

        .valid_out(valid_out),
        .data_out(data_out)

    );


    //--------------------------------------------------
    // Clock
    //--------------------------------------------------

    initial
        clk = 0;

    always #5 clk = ~clk;


    //--------------------------------------------------
    // Test
    //--------------------------------------------------

    initial begin

        rst = 1;
        valid_in = 0;
        data_in = 0;

        //--------------------------------------------------
        // Reset
        //--------------------------------------------------

        #20;

        rst = 0;


        //--------------------------------------------------
        // Send first byte
        //--------------------------------------------------

        @(negedge clk);

        valid_in = 1;
        data_in = 8'hAA;


        //--------------------------------------------------
        // Send second byte
        //--------------------------------------------------

        @(negedge clk);

        data_in = 8'h55;


        //--------------------------------------------------
        // Stop sending data
        //--------------------------------------------------

        @(negedge clk);

        valid_in = 0;
        data_in = 0;


        //--------------------------------------------------
        // Check output
        //--------------------------------------------------

        @(posedge clk);

        if (valid_out && data_out == 16'h55AA)
            $display("PASS : Packed Data = %h", data_out);
        else
            $display("FAIL : Expected 55AA, Received %h", data_out);


        #20;

        $finish;

    end

endmodule