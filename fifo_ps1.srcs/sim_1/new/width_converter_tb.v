`timescale 1ns/1ps

module width_converter_tb;

reg clk;
reg rst;
reg valid_in;
reg [7:0] data_in;

wire valid_out;
wire [15:0] data_out;
// DUT

width_converter dut(

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

// Test

initial
begin

    rst = 1;
    valid_in = 0;
    data_in = 0;

    #20;

    rst = 0;

    // First Byte

    @(posedge clk);

    valid_in = 1;
    data_in = 8'hAA;

    @(posedge clk);

    // Second Byte

    data_in = 8'h55;

    @(posedge clk);

    valid_in = 0;

    #20;

    $display("Packed Data = %h", data_out);

    #20;

    $finish;

end

endmodule