`timescale 1ns / 1ps

module axi_mm_fifo_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 8;

    reg clk;
    reg rst;

    always #5 clk = ~clk;

    // AXI WRITE ADDRESS
    reg [ADDR_WIDTH-1:0] s_awaddr;
    reg s_awvalid;
    wire s_awready;

    // AXI WRITE DATA
    reg [DATA_WIDTH-1:0] s_wdata;
    reg s_wvalid;
    wire s_wready;

    // AXI WRITE RESPONSE
    wire [1:0] s_bresp;
    wire s_bvalid;
    reg s_bready;

    // AXI READ ADDRESS
    reg [ADDR_WIDTH-1:0] s_araddr;
    reg s_arvalid;
    wire s_arready;

    // AXI READ DATA
    wire [DATA_WIDTH-1:0] s_rdata;
    wire [1:0]s_rresp;
    wire s_rvalid;
    reg s_rready;

    // DUT

    axi_mm_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    dut (
        .clk(clk),
        .rst(rst),

        .s_awaddr(s_awaddr),
        .s_awvalid(s_awvalid),
        .s_awready(s_awready),

        .s_wdata(s_wdata),
        .s_wvalid(s_wvalid),
        .s_wready(s_wready),

        .s_bresp(s_bresp),
        .s_bvalid(s_bvalid),
        .s_bready(s_bready),

        .s_araddr(s_araddr),
        .s_arvalid(s_arvalid),
        .s_arready(s_arready),

        .s_rdata(s_rdata),
        .s_rresp(s_rresp),
        .s_rvalid(s_rvalid),
        .s_rready(s_rready)
    );

    // WRITE TASK

    task axi_write;

    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] data;

    begin

        $display("AXI WRITE");
        $display("Address = %h", addr);
        $display("Data = %h", data);

        // WRITE ADDRESS

        @(negedge clk);

        s_awaddr  = addr;
        s_awvalid = 1'b1;

        wait(s_awready);

        @(negedge clk);

        s_awvalid = 1'b0;

        // WRITE DATA

        s_wdata  = data;
        s_wvalid = 1'b1;

        wait(s_wready);

        @(negedge clk);

        s_wvalid = 1'b0;

        // WRITE RESPONSE

        s_bready = 1'b1;

        // Wait until BVALID becomes active
        wait(s_bvalid);

        // Keep BREADY HIGH through a rising edge
        @(posedge clk);

        if (s_bresp == 2'b00)
            $display("WRITE RESPONSE = OKAY");
        else
            $display("WRITE RESPONSE = ERROR");

        @(negedge clk);

        s_bready = 1'b0;

    end

endtask

    // READ TASK

    task axi_read;

    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] expected;

    begin

        $display("AXI READ");
        $display("Address  = %h", addr);
        $display("Expected = %h", expected);

        // READ ADDRESS

        @(negedge clk);

        s_araddr  = addr;
        s_arvalid = 1'b1;

        wait(s_arready);

        @(negedge clk);

        s_arvalid = 1'b0;

        // READ DATA

        s_rready = 1'b1;

        // Wait until RVALID becomes active
        wait(s_rvalid);

        // Keep RREADY HIGH through a rising edge
        @(posedge clk);

        $display("Received = %h", s_rdata);

        if (s_rdata == expected)
        begin
            $display("READ PASS");
        end
        else
        begin
            $display("READ FAIL");
        end

        if (s_rresp == 2'b00)
            $display("READ RESPONSE = OKAY");
        else
            $display("READ RESPONSE = ERROR");

        @(negedge clk);

        s_rready = 1'b0;

    end

endtask

    // TEST SEQUENCES

    initial
    begin

        clk = 1'b0;
        rst = 1'b1;

        s_awaddr  = 0;
        s_awvalid = 0;
        s_wdata   = 0;
        s_wvalid  = 0;
        s_bready  = 0;
        s_araddr  = 0;
        s_arvalid = 0;
        s_rready  = 0;


        #30;

        rst = 1'b0;

        // TEST 1 : Write different data to different addresses

        $display("TEST 1 : MULTIPLE ADDRESS WRITES");

        axi_write(8'h10, 32'hA5A5A5A5);
        axi_write(8'h20, 32'h12345678);
        axi_write(8'h30, 32'hDEADBEEF);
        axi_write(8'h40, 32'hCAFEBABE);

        // let FIFO enter into the memory
        repeat(10)
            @(posedge clk);

        // TEST 2 : Read addresses OUT OF ORDER

        $display("TEST 2 : ADDRESS BASED READS");

        axi_read(8'h30, 32'hDEADBEEF);
        axi_read(8'h10, 32'hA5A5A5A5);
        axi_read(8'h40, 32'hCAFEBABE);
        axi_read(8'h20, 32'h12345678);

        // TEST 3 : Overwrite an existing address

        $display("TEST 3 : ADDRESS OVERWRITE");
      
        axi_write(8'h20, 32'hFACE1234);

        repeat(5)
            @(posedge clk);

        axi_read(8'h20, 32'hFACE1234);

        $display("ALL AXI-MM TESTS COMPLETE");
        
        #50;

        $finish;

    end

endmodule