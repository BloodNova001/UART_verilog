module UART_top (
    input wire [7:0] data_in,
    input wire Tx_en,
    input wire clk_50m,
    output wire Tx,
    output wire Tx_busy,
    input wire Rx,
    input wire Rx_en,
    output wire ready,
    input wire ready_clr,
    output wire [7:0] data_out
);

    localparam baudrate = 115200;

    wire Txclk_en, Rxclk_en;

    Baud_gen #(
        .BAUDRATE(baudrate)
    ) baudgen (
        .clk_50m(clk_50m),
        .Rxclk_en(Rxclk_en),
        .Txclk_en(Txclk_en)
    );

    UART_tx transmitter (data_in, Tx_en, clk_50m, Txclk_en, Tx, Tx_busy);

    UART_rx reciever (Rx, Rx_en, ready, ready_clr, clk_50m, Rxclk_en, data_out);

endmodule