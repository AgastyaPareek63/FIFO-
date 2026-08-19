`timescale 1ns/1ps

module ecc_encoder_tb;

reg  [7:0] data_in;
wire [12:0] code_out;

ecc_encoder dut(
    .data_in(data_in),
    .code_out(code_out)
);

initial
begin

    $display("ECC Encoder Test");

    data_in = 8'h00;
    #10;
    $display("Data = %h  Code = %b", data_in, code_out);

    data_in = 8'hA5;
    #10;
    $display("Data = %h  Code = %b", data_in, code_out);

    data_in = 8'hFF;
    #10;
    $display("Data = %h  Code = %b", data_in, code_out);

    data_in = 8'h3C;
    #10;
    $display("Data = %h  Code = %b", data_in, code_out);

    $finish;

end

endmodule