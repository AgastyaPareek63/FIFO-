`timescale 1ns/1ps

module synchronizer #(
    parameter WIDTH = 5,// width of signal being synchronized
    parameter SYNC_STAGES = 2// no. of synchronization stages
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    // Synchronizer flip-flops
    reg [WIDTH-1:0] sync_ff [0:SYNC_STAGES-1];

    integer i;


    // Pass the input through multiple flip-flop stages
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            // Clear all stages during reset.
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                sync_ff[i] <= {WIDTH{1'b0}};
        end
        else
        begin
            // First stage samples the incoming signal.
            sync_ff[0] <= din;

            for (i = 1; i < SYNC_STAGES; i = i + 1)
                sync_ff[i] <= sync_ff[i-1];
        end
    end

    // Output from the last synchronization stage.
    assign dout = sync_ff[SYNC_STAGES-1];

endmodule