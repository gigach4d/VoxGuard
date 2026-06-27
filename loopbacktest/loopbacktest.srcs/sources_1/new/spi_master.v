`timescale 1ns / 1ps

module spi_master (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg busy,
    output reg sck,
    output reg mosi,
    input wire miso
);
    // 12 MHz / 6 = 2 MHz SCK
    localparam CLK_DIV = 6; 
    
    reg [2:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] clk_cnt;
    reg [7:0] shift_reg_tx;
    reg [7:0] shift_reg_rx;

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            busy <= 0;
            sck <= 0;
            mosi <= 0;
            bit_cnt <= 0;
            clk_cnt <= 0;
            rx_data <= 0;
        end else begin
            case (state)
                0: begin // IDLE
                    sck <= 0;
                    if (start) begin
                        shift_reg_tx <= tx_data;
                        busy <= 1;
                        bit_cnt <= 0;
                        clk_cnt <= 0;
                        state <= 1;
                    end else begin
                        busy <= 0;
                    end
                end
                
                1: begin // Setup MOSI (Falling Edge / Pre-clock)
                    mosi <= shift_reg_tx[7];
                    if (clk_cnt == (CLK_DIV/2)-1) begin
                        clk_cnt <= 0;
                        state <= 2;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                2: begin // SCK High (Rising Edge - Sample MISO)
                    sck <= 1;
                    if (clk_cnt == 0) begin
                        shift_reg_rx <= {shift_reg_rx[6:0], miso};
                    end
                    
                    if (clk_cnt == (CLK_DIV/2)-1) begin
                        clk_cnt <= 0;
                        state <= 3;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                3: begin // SCK Low
                    sck <= 0;
                    if (clk_cnt == (CLK_DIV/2)-1) begin
                        clk_cnt <= 0;
                        shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                        if (bit_cnt == 7) begin
                            rx_data <= shift_reg_rx;
                            state <= 0; // Done
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                            state <= 1; // Next bit
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end
endmodule