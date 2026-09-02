`timescale 1ns / 1ps

module axi_mm_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8
)(
    
    input wire clk,
    input wire rst,
    
    // AXI WRITE ADDRESS CHANNEL
    input wire [ADDR_WIDTH-1:0] s_awaddr,
    input wire s_awvalid,
    output wire s_awready,

    // AXI WRITE DATA CHANNEL
    input wire [DATA_WIDTH-1:0] s_wdata,
    input wire s_wvalid,
    output wire s_wready,

    // AXI WRITE RESPONSE CHANNEL
    output wire [1:0]s_bresp,
    output wire s_bvalid,
    input wire s_bready,

    // AXI READ ADDRESS CHANNEL
    input wire [ADDR_WIDTH-1:0] s_araddr,
    input wire s_arvalid,
    output wire s_arready,

    // AXI READ DATA CHANNEL
    output wire [DATA_WIDTH-1:0] s_rdata,
    output wire [1:0]s_rresp,
    output wire s_rvalid,
    input wire s_rready

);

    // MEMORY
    localparam MEM_DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    integer i;

    // WRITE REGISTERS
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg aw_received;

    reg [DATA_WIDTH-1:0] wdata_reg;
    reg w_received;

    // WRITE RESPONSE
    reg bvalid_reg;
    reg [1:0] bresp_reg;

    // WRITE FIFO
  
    localparam WRITE_FIFO_WIDTH = ADDR_WIDTH + DATA_WIDTH;

    wire [WRITE_FIFO_WIDTH-1:0] write_fifo_din;
    wire [WRITE_FIFO_WIDTH-1:0] write_fifo_dout;

    wire write_fifo_full;
    wire write_fifo_empty;

    wire write_fifo_wr_en;
    wire write_fifo_rd_en;

    assign write_fifo_din = {awaddr_reg, wdata_reg};

    // WRITE FIFO CONTROL

    assign write_fifo_wr_en = aw_received && w_received && !write_fifo_full;

   
    assign write_fifo_rd_en = !write_fifo_empty;

    // AXI WRITE READY

    assign s_awready =!aw_received && !bvalid_reg && !write_fifo_full;

    assign s_wready =aw_received && !w_received && !write_fifo_full;

    // AXI WRITE RESPONSE

    assign s_bvalid = bvalid_reg;
    assign s_bresp = bresp_reg;

    // WRITE CHANNEL

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            awaddr_reg <= 0;
            aw_received <= 1'b0;

            wdata_reg <= 0;
            w_received <= 1'b0;

            bvalid_reg <= 1'b0;
            bresp_reg <= 2'b00;
        end
        else
        begin

            // Capture write address
            if (s_awvalid && s_awready)
            begin
                awaddr_reg <= s_awaddr;
                aw_received <= 1'b1;
            end

            // Capture write data
            if (s_wvalid && s_wready)
            begin
                wdata_reg <= s_wdata;
                w_received <= 1'b1;
            end

            // Put complete transaction into FIFO
            if (write_fifo_wr_en)
            begin
                aw_received <= 1'b0;
                w_received <= 1'b0;

                bvalid_reg <= 1'b1;
                bresp_reg <= 2'b00;
            end

            // Write response handshake
            if (bvalid_reg && s_bready)
            begin
                bvalid_reg <= 1'b0;
            end

        end
    end

    // MEMORY WRITE PROCESS

    wire [ADDR_WIDTH-1:0] fifo_write_addr;
    wire [DATA_WIDTH-1:0] fifo_write_data;

    assign fifo_write_addr = write_fifo_dout[WRITE_FIFO_WIDTH-1 :DATA_WIDTH];

    assign fifo_write_data = write_fifo_dout[DATA_WIDTH-1 : 0];

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin

            for (i = 0; i < MEM_DEPTH; i = i + 1)
            begin
                memory[i] <= {DATA_WIDTH{1'b0}};
            end

        end
        else
        begin

            if (write_fifo_rd_en)
            begin
                memory[fifo_write_addr] <= fifo_write_data;
            end

        end
    end

    // READ REGISTERS
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg ar_received;

    reg [DATA_WIDTH-1:0] rdata_reg;
    reg rvalid_reg;
    reg [1:0]rresp_reg;

    // AXI READ OUTPUTS
    assign s_rdata  = rdata_reg;
    assign s_rvalid = rvalid_reg;
    assign s_rresp  = rresp_reg;

    // AXI READ READY

    assign s_arready =!ar_received && !rvalid_reg;

    // READ CHANNEL

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            araddr_reg <= 0;
            ar_received <= 1'b0;

            rdata_reg <= 0;
            rvalid_reg <= 1'b0;
            rresp_reg <= 2'b00;
        end
        else
        begin

            // Accept read address
            if (s_arvalid && s_arready)
            begin
                araddr_reg <= s_araddr;
                ar_received <= 1'b1;
            end

            // Generate read response
            if (ar_received)
            begin
                rdata_reg <= memory[araddr_reg];
                rvalid_reg <= 1'b1;
                rresp_reg <= 2'b00;

                ar_received <= 1'b0;
            end

            // Read response handshake
            if (rvalid_reg && s_rready)
            begin
                rvalid_reg <= 1'b0;
            end

        end
    end

    // FIFO SYSTEM
    // DATA_WIDTH = 32 and ADDR_WIDTH = 8:
    // FIFO width = 40 bits
    // 40-bit data requires 7 Hamming parity bits.

    fifo_system #(
        .DATA_WIDTH(WRITE_FIFO_WIDTH),
        .DEPTH(16),
        .ADDR_WIDTH($clog2(16)),
        .PARITY_BITS(7)
    )
    write_fifo_inst (
        
        .wr_clk(clk),
        .wr_rst(rst),
        .wr_en(write_fifo_wr_en),
        .din(write_fifo_din),

        .rd_clk(clk),
        .rd_rst(rst),
        .rd_en(write_fifo_rd_en),
        .dout(write_fifo_dout),

        .full(write_fifo_full),
        .empty(write_fifo_empty),
        .almost_full(),
        .almost_empty(),
        .prog_full(),
        .prog_empty(),

        .ecc_single_error(),
        .ecc_double_error()
    );

endmodule