module spi_transceiver #(
    parameter CLK_DIV = 4 
)(
    input  wire clk,
    input  wire rst,
    input  wire is_master_mode,
    
    input  wire tx_start,
    input  wire [7:0] tx_data,
    output wire tx_busy,      
    
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

    localparam M_IDLE = 0, M_TRANSFER = 1, M_DONE = 2;
    reg [1:0] m_state;
    reg [7:0] clk_cnt; 
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg_tx;

    assign tx_busy = (m_state != M_IDLE) || tx_start;

    // --- Master Logic ---
    always @(posedge clk) begin
        if (rst) begin
            m_state <= M_IDLE;
            sclk_out_en <= 0; sclk_out_val <= 0;
            sdio_out_en <= 0; sdio_out_val <= 0;
            shift_reg_tx <= 0;
            clk_cnt <= 0; bit_cnt <= 0;
        end else if (is_master_mode) begin
            sclk_out_en <= 1; 
            case (m_state)
                M_IDLE: begin
                    sclk_out_val <= 0; 
                    sdio_out_en <= 0;
                    if (tx_start) begin
                        shift_reg_tx <= {tx_data[6:0], 1'b0};
                        sdio_out_val <= tx_data[7];
                        sdio_out_en <= 1;
                        m_state <= M_TRANSFER;
                        clk_cnt <= 0; 
                        bit_cnt <= 0;
                    end
                end
                M_TRANSFER: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= 0;
                        sclk_out_val <= ~sclk_out_val; 
                        if (sclk_out_val) begin 
                            if (bit_cnt < 7) begin
                                sdio_out_val <= shift_reg_tx[7];
                                shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                                bit_cnt <= bit_cnt + 1;
                            end else begin
                                m_state <= M_DONE;
                            end
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                M_DONE: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        m_state <= M_IDLE;
                        sdio_out_en <= 0; 
                        clk_cnt <= 0;
                        sclk_out_val <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end else begin
            m_state <= M_IDLE;
            sclk_out_en <= 0; sdio_out_en <= 0;
        end
    end

    // --- Slave Logic (With Timeout Auto-Align) ---
    reg [2:0] sclk_sync;
    reg [3:0] bit_cnt_rx; 
    reg [7:0] shift_reg_rx;
    wire      sclk_rising_edge;
    
    // NEW: Timeout Counter to reset bit alignment if bus is idle
    reg [5:0] timeout_cnt; 

    always @(posedge clk) begin
        if (rst) sclk_sync <= 0;
        else sclk_sync <= {sclk_sync[1:0], sclk_in};
    end
    assign sclk_rising_edge = (sclk_sync[2:1] == 2'b01);

    always @(posedge clk) begin
        if (rst) begin
            rx_done_tick <= 0;
            bit_cnt_rx <= 0;
            shift_reg_rx <= 0;
            rx_data <= 0;
            timeout_cnt <= 0;
        end else if (!is_master_mode) begin
            rx_done_tick <= 0;

            // 1. Timeout Logic: If no clock edges for ~32 cycles, reset bit counter
            if (sclk_rising_edge) begin
                timeout_cnt <= 0; // Activity detected, clear timeout
                
                // 2. Normal SPI Capture
                shift_reg_rx <= {shift_reg_rx[6:0], sdio_in};
                if (bit_cnt_rx == 7) begin
                    rx_data <= {shift_reg_rx[6:0], sdio_in};
                    rx_done_tick <= 1;
                    bit_cnt_rx <= 0;
                end else begin
                    bit_cnt_rx <= bit_cnt_rx + 1;
                end
            end else begin
                // Increment timeout if line is idle (Low)
                // We use 32 cycles as a safe "Packet Over" threshold
                if (timeout_cnt < 6'd32) timeout_cnt <= timeout_cnt + 1;
                else bit_cnt_rx <= 0; // Force Reset!
            end
        end else begin
            bit_cnt_rx <= 0;
        end
    end
endmodule