module Baud_gen #(
    parameter BAUDRATE = 115200
)(
    input wire clk_50m,
    output wire Rxclk_en,
    output wire Txclk_en
);

    localparam RX_ACC_MAX = 50000000 / (BAUDRATE * 16);
    localparam TX_ACC_MAX = 50000000 / BAUDRATE;
    localparam RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
    localparam TX_ACC_WIDTH = $clog2(TX_ACC_MAX);

    reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
    reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

    assign Rxclk_en = (rx_acc == 0);
    assign Txclk_en = (tx_acc == 0);


    always @(posedge clk_50m) begin
        if (rx_acc == RX_ACC_MAX - 1) rx_acc <= 0;
        else rx_acc <= rx_acc + 1;

        if (tx_acc == TX_ACC_MAX - 1) tx_acc <= 0;
        else tx_acc <= tx_acc + 1;
    end

endmodule