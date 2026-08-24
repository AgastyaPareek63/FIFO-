`timescale 1ns/1ps

module synchronizer #(
    parameter WIDTH = 5,// Number of bits being synchronized.
    parameter SYNC_STAGES = 2// Number of flip-flop stages used for synchronization.
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    // Synchronizer Registers
    
    reg [WIDTH-1:0] sync_ff [0:SYNC_STAGES-1]; // sync_ff is an array of flip-flop registers.
    // Each element represents one synchronization stage:
    //
    //     sync_ff[0]              -> First stage
    //     sync_ff[1]              -> Second stage
    //     ...
    //     sync_ff[SYNC_STAGES-1]   -> Final stage
    
    integer i;

    // Synchronizer Logic
    
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            // Clear all stages during reset.
            for(i=0; i<SYNC_STAGES; i=i+1)
                sync_ff[i] <= 0;
        end
        else
        begin
            // First stage samples the asynchronous input.
            sync_ff[0] <= din;
            // Pass the signal through the remaining synchronization stages.
            for(i=1; i<SYNC_STAGES; i=i+1)
                sync_ff[i] <= sync_ff[i-1];
        end
    end

    // Output

    assign dout = sync_ff[SYNC_STAGES-1];

endmodule