`timescale 1ns/1ps

module ecc_decoder_tb;

reg  [7:0] data;

wire [12:0] encoded;

reg  [12:0] corrupted;

wire [7:0] decoded;

wire single_error;
wire double_error;

//--------------------------------------------------
// Encoder
//--------------------------------------------------

ecc_encoder encoder(

    .data_in(data),
    .code_out(encoded)

);

//--------------------------------------------------
// Decoder
//--------------------------------------------------

ecc_decoder decoder(

    .code_in(corrupted),

    .data_out(decoded),

    .single_error(single_error),
    .double_error(double_error)

);

//--------------------------------------------------
// Test Sequence
//--------------------------------------------------

initial
begin

    //--------------------------------------------------
    // Test 1
    //--------------------------------------------------

    data = 8'hA5;

    #10;

    corrupted = encoded;

    #10;

    $display("--------------------------------");
    $display("No Error");
    $display("Original = %h",data);
    $display("Decoded  = %h",decoded);
    $display("Single Error = %b",single_error);
    $display("Double Error = %b",double_error);

    //--------------------------------------------------
    // Test 2
    // Inject Single Bit Error
    //--------------------------------------------------

    corrupted = encoded;

    corrupted[5] = ~corrupted[5];

    #10;

    $display("--------------------------------");
    $display("Single Bit Error");
    $display("Original = %h",data);
    $display("Decoded  = %h",decoded);
    $display("Single Error = %b",single_error);
    $display("Double Error = %b",double_error);

    //--------------------------------------------------
    // Test 3
    // Inject Double Bit Error
    //--------------------------------------------------

    corrupted = encoded;

    corrupted[5] = ~corrupted[5];
    corrupted[8] = ~corrupted[8];

    #10;

    $display("--------------------------------");
    $display("Double Bit Error");
    $display("Original = %h",data);
    $display("Decoded  = %h",decoded);
    $display("Single Error = %b",single_error);
    $display("Double Error = %b",double_error);

    #20;

    $finish;

end

endmodule