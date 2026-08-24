`timescale 1ns/1ps

module synchronizer #(
    parameter WIDTH = 5,
    parameter SYNC_STAGES = 2
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    // Synchronizer Registers
  
    reg [WIDTH-1:0] sync_ff [0:SYNC_STAGES-1];

    integer i;

    // Synchronizer Logic
   
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            for(i=0; i<SYNC_STAGES; i=i+1)
                sync_ff[i] <= 0;
        end
        else
        begin
            sync_ff[0] <= din;

            for(i=1; i<SYNC_STAGES; i=i+1)
                sync_ff[i] <= sync_ff[i-1];
        end
    end

    // Output
    
    assign dout = sync_ff[SYNC_STAGES-1];

endmodule
