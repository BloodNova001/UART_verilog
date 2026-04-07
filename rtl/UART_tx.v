module UART_tx (
    input wire [7:0] data_in,
    input wire Tx_en,
    input wire clk_50m,
    input wire clken,
    output reg Tx,
    output wire Tx_busy
);

    parameter TX_IDLE  = 2'b00, TX_START = 2'b01, TX_DATA  = 2'b10, TX_STOP  = 2'b11;

    reg [7:0] data = 8'h00;
    reg [2:0] bit_pos = 3'h0;
    reg [1:0] prs_state = TX_IDLE;

    initial begin
        Tx = 1'b1; 
    end

    assign Tx_busy = (prs_state != TX_IDLE);


    always @(posedge clk_50m) begin
        case (prs_state)
            TX_IDLE: begin
                if (~Tx_en) begin
                    prs_state <= TX_START;
                    data <= data_in;
                    bit_pos <= 3'h0;
                end
            end
            TX_START: begin
                if (clken) begin
                    Tx <= 1'b0;
                    prs_state <= TX_DATA;
                end
            end
            TX_DATA: begin
                if (clken) begin
                    Tx <= data[bit_pos];
                    bit_pos <= bit_pos + 1;
                    if (bit_pos == 3'h7)
                        prs_state <= TX_STOP;
                end
            end
            TX_STOP: begin
                if (clken) begin
                    Tx <= 1'b1;
                    prs_state <= TX_IDLE;
                end
            end
            default: begin
                Tx <= 1'b1;
                prs_state <= TX_IDLE;
            end
        endcase
    end

endmodule