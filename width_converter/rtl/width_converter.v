`timescale 1ns/1ps

module width_converter #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 16
)(
    input  wire clk,
    input  wire rst,

    input  wire valid_in,
    input  wire [IN_WIDTH-1:0] data_in,

    output reg valid_out,
    output reg [OUT_WIDTH-1:0] data_out
);

// Internal Registers

reg [IN_WIDTH-1:0] buffer;
reg toggle;

// Packing Logic

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        buffer <= 0;
        toggle <= 0;
        data_out <= 0;
        valid_out <= 0;
    end
    else
    begin
        valid_out <= 0;

        if(valid_in)
        begin
            if(toggle == 0)
            begin
                buffer <= data_in;
                toggle <= 1;
            end
            else
            begin
                data_out <= {data_in, buffer};
                valid_out <= 1;
                toggle <= 0;
            end
        end
    end
end

endmodule
