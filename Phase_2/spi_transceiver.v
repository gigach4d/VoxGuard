module spi_transceiver #(
    parameter CLK_DIV = 4 
)(
    input  wire clk,
    input  wire rst,
    input  wire is_master_mode,
    
    input  wire tx_start,
    input  wire [7:0] tx_data,
    output reg  tx_busy,
    
    output reg  [7:0] rx_data,
    output reg  rx_done_tick,
    
    inout  wire spi_sclk_pin,
    inout  wire spi_sdio_pin
);

    reg sclk_out_en, sclk_out_val;
    reg sdio_out_en, sdio_out_val;
    wire sclk_in, sdio_in;

    assign spi_sclk_pin = sclk_out_en ? sclk_out_val : 1'bz;
    assign spi_sdio_pin = sdio_out_en ? sdio_out_val : 1'bz;

    assign sclk_in = spi_sclk_pin;
    assign sdio_in = spi_sdio_pin;

    // --- Master Logic ---
    localparam M_IDLE = 0, M_TRANSFER = 1, M_DONE = 2;
    reg [1:0] m_state;
    reg [7:0] clk_cnt; // sized generously
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg_tx;

    always @(posedge clk) begin
        if (rst) begin
            m_state <= M_IDLE;
            sclk_out_en <= 0;
            sclk_out_val <= 1;
            sdio_out_en <= 0;
            sdio_out_val <= 0;
            tx_busy <= 0;
            shift_reg_tx <= 0;
            clk_cnt <= 0;
            bit_cnt <= 0;
        end else if (is_master_mode) begin
            sclk_out_en <= 1;
            
            case (m_state)
                M_IDLE: begin
                    sclk_out_val <= 1;
                    sdio_out_en <= 0;
                    tx_busy <= 0;
                    if (tx_start) begin
                        shift_reg_tx <= tx_data;
                        m_state <= M_TRANSFER;
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        tx_busy <= 1;
                    end
                end
                
                M_TRANSFER: begin
                    sdio_out_en <= 1;
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= 0;
                        sclk_out_val <= ~sclk_out_val;
                        
                        if (sclk_out_val) begin // Falling Edge
                            sdio_out_val <= shift_reg_tx[7];
                            shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                            bit_cnt <= bit_cnt + 1;
                        end
                        
                        if (bit_cnt == 8 && sclk_out_val == 0) begin
                            m_state <= M_DONE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
					 M_DONE: begin
                    // FIX: Hold the data line for 8 cycles to allow Slave Sync to catch up.
                    // If we release too early, the Slave reads a '1' (Pullup) instead of '0'.
                    if (clk_cnt == 8) begin
                        m_state <= M_IDLE;
                        tx_busy <= 0;
                        sdio_out_en <= 0; // Now safe to release
                        clk_cnt <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                        sdio_out_en <= 1; // KEEP DRIVING!
                    end
                end
            endcase
        end else begin
            // Slave Reset
            m_state <= M_IDLE;
            sclk_out_en <= 0;
            sdio_out_en <= 0;
            tx_busy <= 0;
        end
    end

    // --- Slave Logic ---
    reg [2:0] sclk_sync;
    reg [2:0] bit_cnt_rx;
    reg [7:0] shift_reg_rx;
    reg       sclk_rising_edge;

    always @(posedge clk) begin
        if (rst) begin
            sclk_sync <= 3'b111;
            rx_done_tick <= 0;
            bit_cnt_rx <= 0;
            shift_reg_rx <= 0;
            rx_data <= 0;
        end else if (!is_master_mode) begin
            sclk_sync <= {sclk_sync[1:0], sclk_in};
            sclk_rising_edge = (sclk_sync[2:1] == 2'b01);
            rx_done_tick <= 0;

            if (sclk_rising_edge) begin
                shift_reg_rx <= {shift_reg_rx[6:0], sdio_in};
                bit_cnt_rx <= bit_cnt_rx + 1;
                
                if (bit_cnt_rx == 7) begin
                    rx_data <= {shift_reg_rx[6:0], sdio_in};
                    rx_done_tick <= 1;
                    bit_cnt_rx <= 0;
                end
            end
        end else begin
            bit_cnt_rx <= 0;
            rx_done_tick <= 0;
        end
    end
endmodule
