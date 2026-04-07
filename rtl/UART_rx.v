module UART_rx (
    input wire Rx,
    input wire Rx_en,
    output reg ready,
    input wire ready_clr,
    input wire clk_50m,
    input wire clken,
    output reg [7:0] data
);

    localparam RX_START = 2'b00, RX_DATA  = 2'b01, RX_STOP  = 2'b10;

    reg [1:0] state = RX_START;
    reg [3:0] sample = 0, bit_pos = 0;
    reg [7:0] temp_data = 8'b0;

    initial begin
        ready = 1'b0;
        data = 8'b0;
    end


    always @(posedge clk_50m) begin
        if (ready_clr) ready <= 1'b0;
        if (clken && ~Rx_en) begin
            case (state)
                RX_START: begin
                    if (!Rx || sample != 0)
                        sample <= sample + 1;
                    if (sample == 15) begin
                        state <= RX_DATA;
                        bit_pos <= 0;
                        sample <= 0;
                        temp_data <= 0;
                    end
                end
                RX_DATA: begin
                    sample <= sample + 1;
                    if (sample == 8) begin
                        temp_data[bit_pos[2:0]] <= Rx;
                        bit_pos <= bit_pos + 1;
                    end
                    if (bit_pos == 8 && sample == 15)
                        state <= RX_STOP;
                end
                RX_STOP: begin
                    if (sample == 15 || (sample >= 8 && !Rx)) begin
                        state <= RX_START;
                        data <= temp_data;
                        ready <= 1'b1;
                        sample <= 0;
                    end 
                    else sample <= sample + 1;
                end
                default: state <= RX_START;
            endcase
        end
    end

endmodule