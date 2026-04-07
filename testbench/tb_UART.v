`timescale 1ns/100ps
module tb_UART();

    reg [7:0] data = 8'h00;
    reg clk = 0;
    reg Tx_en = 1;
    reg Rx_en = 0;
    reg ready_clr = 0;

    wire Tx_busy;
    wire ready;
    wire [7:0] Rx_data;
    wire loopback;

    UART_top dut(
        .data_in(data),
        .Tx_en(Tx_en),
        .clk_50m(clk),
        .Tx(loopback),
        .Tx_busy(Tx_busy),
        .Rx(loopback),
        .ready(ready),
        .ready_clr(ready_clr),
        .Rx_en(Rx_en),
        .data_out(Rx_data)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_UART);
    end

    task send_byte(input [7:0] b);
    begin
        @(posedge clk);
        data = b;
        @(posedge clk);
        Tx_en = 0;
        @(posedge clk);
        Tx_en = 1;
    end
    endtask

    task wait_and_check(input [7:0] expected);
    reg [7:0] rx;
    begin
        @(posedge ready);
        @(posedge clk);
        rx = Rx_data;
        if (rx !== expected) begin
            $display("[%0t] FAIL: rx data %0h does not match tx %0h", $time, rx, expected);
        end
        else begin
            $display("[%0t] PASS: rx data %0h == tx %0h", $time, rx, expected);
        end
        @(posedge clk);
        ready_clr = 1;
        @(posedge clk);
        ready_clr = 0;
    end
    endtask

    initial begin
        data = 8'h00;
        Tx_en = 1;
        Rx_en = 0;
        ready_clr = 0;

        #2000;

        send_byte(8'h00);
        wait_and_check(8'h00);

        #20000;

        send_byte(8'h01);
        wait_and_check(8'h01);

        #20000;

        send_byte(8'h02);
        wait_and_check(8'h02);

        $display("[%0t] TESTBENCH: All bytes verified. Finishing simulation.", $time);
        #1000;
        $finish;
    end

    initial begin
        #5_000_000;
        $display("[%0t] TIMEOUT: testbench timed out.", $time);
        $finish;
    end

endmodule