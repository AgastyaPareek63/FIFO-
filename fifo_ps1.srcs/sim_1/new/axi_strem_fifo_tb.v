`timescale 1ns/1ps

module axi_stream_fifo_tb;
    parameter DATA_WIDTH = 8;
    
    reg clk,rst;
    
    //slave/input side
    reg [DATA_WIDTH-1:0] s_data;
    reg s_valid;
    wire s_ready;


    //master/output side
    wire[DATA_WIDTH-1:0] m_data;
    wire m_valid;
    reg m_ready;
    
    axi_stream_fifo #(.DATA_WIDTH(DATA_WIDTH)) 
        dut (

        .clk(clk),
        .rst(rst),
        
        .s_data (s_data),
        .s_valid(s_valid),
        .s_ready(s_ready),

        .m_data (m_data),
        .m_valid(m_valid),
        .m_ready(m_ready)

    );
    
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    initial begin

        rst     = 1'b1;
        s_data  = 0;
        s_valid = 1'b0;
        m_ready = 1'b0;

    end
    
    // Test sequences

    initial begin

        // Wait while reset is active.
        #20;

        rst = 1'b0;

        // time for FIFO to leave reset.
        #20;


        // TEST 1 : AXI WRITE

        $display("TEST 1 : AXI WRITE");
        
        // giving one data word to the FIFO.
        s_data  = 8'hA5;
        s_valid = 1'b1;

        // Wait until FIFO accepts the word.
        wait(s_ready == 1'b1);

        @(posedge clk);

        s_valid = 1'b0;
        s_data  = 0;

        $display("Write data = %h", 8'hA5);

        wait(m_valid == 1'b1);


        // TEST 2 : CHECK FIFO OUTPUT

         $display("TEST 2 : FIFO OUTPUT");
 
        if (m_valid == 1'b1 && m_data == 8'hA5)
        begin
            $display("PASS: m_valid asserted");
            $display("PASS: m_data = %h", m_data);
        end
        else
        begin
            $display("FAIL: Unexpected FIFO output");
            $display("Expected data = A5");
            $display("Actual data = %h", m_data);
            $display("m_valid = %b", m_valid);
        end 
    
        #20;

    
        // TEST 3 : AXI BACKPRESSURE

        $display("TEST 3 : AXI BACKPRESSURE");



        // m_ready is still 0.
        //
        // Therefore the FIFO must NOT remove the data.
        // The output data must remain A5.

        if (m_valid == 1'b1 &&
            m_data  == 8'hA5 &&
            m_ready == 1'b0)
        begin
            $display("PASS: Data is held while m_ready = 0");
            $display("m_data  = %h", m_data);
            $display("m_valid = %b", m_valid);
            $display("m_ready = %b", m_ready);
        end

        else
        begin
            $display("FAIL: Backpressure condition is incorrect");
            $display("m_data  = %h", m_data);
            $display("m_valid = %b", m_valid);
            $display("m_ready = %b", m_ready);
        end


        // Keep the receiver stalled for several cycles.

        #30;


        // Data must still be present.

        if (m_valid == 1'b1 &&
            m_data  == 8'hA5)
        begin
            $display("PASS: Data remains stable during backpressure");
        end

        else
        begin
            $display("FAIL: Data changed during backpressure");
            $display("m_data = %h", m_data);
        end


        // TEST 4 : ACCEPT DATA

        $display("TEST 4 : AXI DATA ACCEPT");



        // Receiver is now ready.

        m_ready = 1'b1;

        // AXI transfer occurs on the clock edge when
        //
        // m_valid = 1
        // m_ready = 1

        @(posedge clk);


        if (m_valid == 1'b1 &&
            m_ready == 1'b1)
        begin
            $display("PASS: AXI transfer occurred");
            $display("Transferred data = %h", m_data);
        end

        else
        begin
            $display("FAIL: AXI transfer did not occur");
        end


        // Stop accepting data.

        @(negedge clk);

        m_ready = 1'b0;


        // Give FIFO time to update its empty flag.

        #20;

        // TEST 5 : FIFO EMPTY AFTER READ


        $display("TEST 5 : FIFO EMPTY AFTER READ");



        if (m_valid == 1'b0)
        begin
            $display("PASS: m_valid deasserted after data was read");
        end

        else
        begin
            $display("FAIL: m_valid is still asserted");
        end

        $display("AXI STREAM FIFO TEST COMPLETE");

        #20;
        
        // TEST 6 : MULTIPLE AXI STREAM TRANSFERS

        $display("TEST 6 : MULTIPLE AXI TRANSFERS");

        m_ready = 1'b1;

        // First transfer

        @(negedge clk);

        s_data  = 8'hA5;
        s_valid = 1'b1;

        @(posedge clk);

        if (s_ready)
            $display("PASS: Sent A5");
        else
            $display("FAIL: FIFO not ready for A5");


        // Second transfer

        @(negedge clk);

        s_data = 8'h3C;

        @(posedge clk);

        if (s_ready)
            $display("PASS: Sent 3C");
        else
            $display("FAIL: FIFO not ready for 3C");


        // Third transfer

        @(negedge clk);

        s_data = 8'h55;

        @(posedge clk);

        if (s_ready)
            $display("PASS: Sent 55");
        else
            $display("FAIL: FIFO not ready for 55");


        // Stop input
        @(negedge clk);

        s_valid = 1'b0;
        s_data  = 0;

        repeat (10)
            @(posedge clk);



        if (!m_valid)
            $display("PASS: All data consumed");

        else
            $display("FAIL: FIFO still contains data");

        $display("MULTIPLE AXI TRANSFER TEST COMPLETE");

        $finish;

    end

endmodule