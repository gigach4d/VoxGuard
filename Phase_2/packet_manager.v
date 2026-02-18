`timescale 1ns / 1ps

module packet_manager (
    input wire clk,
    input wire rst,
    input wire push_to_talk,
    
    // TX FIFO Interface (From Mic)
    input  wire [15:0] tx_fifo_dout,
    input  wire tx_fifo_empty,
    output reg  tx_fifo_rd_en,
    
    // RX FIFO Interface (To Speaker)
    output reg [15:0] rx_fifo_din,
    output reg  rx_fifo_wr_en,
    input  wire rx_fifo_full,
    
    // SPI Transceiver Interface
    output reg  spi_tx_start,
    output reg  [7:0] spi_tx_data,
    input  wire spi_tx_busy,   
    
    input  wire [7:0] spi_rx_data,
    input  wire spi_rx_done
);

    localparam [15:0] SYNC_WORD = 16'hCAFE;

    // --- Chaotic Encryption Integration ---
    wire [31:0] chaos_key;
    reg next_key_en;
    reg sync_en;
    
    chaotic_generator cipher (
        .clk(clk),
        .rst(rst),
        .next_key_en(next_key_en),
        .sync_en(sync_en),
        .sync_state_in(32'h01F97414), // Default reset seed
        .key_out(chaos_key)
    );

    // --- State Machine ---
    localparam IDLE = 0,
               TX_SYNC_H = 1, TX_WAIT_SH = 2, TX_SYNC_L = 3, TX_WAIT_SL = 4,
               TX_POP = 5, TX_ENCRYPT = 6, 
               TX_DATA_H = 7, TX_WAIT_DH = 8, TX_DATA_L = 9, TX_WAIT_DL = 10,
               RX_WAIT_H = 11, RX_WAIT_L = 12, RX_DECRYPT = 13;
               
    reg [3:0] state;
    reg [15:0] tx_buffer;
    reg [15:0] rx_buffer;
    reg [15:0] rx_sliding_window;
    
    // Timeout counter to reset RX if SPI connection drops
    reg [15:0] rx_idle_cnt;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            spi_tx_start <= 0;
            tx_fifo_rd_en <= 0;
            rx_fifo_wr_en <= 0;
            next_key_en <= 0;
            sync_en <= 0;
            rx_idle_cnt <= 0;
            rx_sliding_window <= 0;
        end else begin
            // Default Pulses
            spi_tx_start <= 0;
            tx_fifo_rd_en <= 0;
            rx_fifo_wr_en <= 0;
            next_key_en <= 0;
            sync_en <= 0;
            
            // RX Timeout Logic
            if (spi_rx_done) rx_idle_cnt <= 0;
            else if (rx_idle_cnt < 16'hFFFF) rx_idle_cnt <= rx_idle_cnt + 1;
            
            // RX Sliding Window Hunt (Always active in IDLE/RX modes)
            if (spi_rx_done) rx_sliding_window <= {rx_sliding_window[7:0], spi_rx_data};

            if (push_to_talk) begin
                // ==========================================
                // TRANSMIT MODE (TX)
                // ==========================================
                case (state)
                    IDLE: begin
                        // Wait until we have some audio data before broadcasting
                        if (!tx_fifo_empty) begin
                            sync_en <= 1; // Reset encryption key for new transmission
                            state <= TX_SYNC_H;
                        end
                    end
                    // 1. Send SYNC Preamble
                    TX_SYNC_H: if (!spi_tx_busy) begin spi_tx_data <= SYNC_WORD[15:8]; spi_tx_start <= 1; state <= TX_WAIT_SH; end
                    TX_WAIT_SH: if (!spi_tx_busy && !spi_tx_start) state <= TX_SYNC_L;
                    TX_SYNC_L: if (!spi_tx_busy) begin spi_tx_data <= SYNC_WORD[7:0]; spi_tx_start <= 1; state <= TX_WAIT_SL; end
                    TX_WAIT_SL: if (!spi_tx_busy && !spi_tx_start) state <= TX_POP;
                    
                    // 2. Process Audio
                    TX_POP: begin
                        if (!tx_fifo_empty) begin
                            tx_fifo_rd_en <= 1; // Pop FWFT FIFO
                            state <= TX_ENCRYPT;
                        end else begin
                            state <= IDLE; // Buffer empty, restart preamble next time
                        end
                    end
                    TX_ENCRYPT: begin
                        tx_buffer <= tx_fifo_dout ^ chaos_key[15:0]; // Encrypt
                        next_key_en <= 1; // Advance chaos sequence
                        state <= TX_DATA_H;
                    end
                    TX_DATA_H: if (!spi_tx_busy) begin spi_tx_data <= tx_buffer[15:8]; spi_tx_start <= 1; state <= TX_WAIT_DH; end
                    TX_WAIT_DH: if (!spi_tx_busy && !spi_tx_start) state <= TX_DATA_L;
                    TX_DATA_L: if (!spi_tx_busy) begin spi_tx_data <= tx_buffer[7:0]; spi_tx_start <= 1; state <= TX_WAIT_DL; end
                    TX_WAIT_DL: if (!spi_tx_busy && !spi_tx_start) state <= TX_POP; // Loop back for next sample
                    
                    default: state <= IDLE;
                endcase
                
            end else begin
                // ==========================================
                // RECEIVE MODE (RX)
                // ==========================================
                
                // PRIORITY CHECK: Always hunt for the Sync Word (CAFE)
                // If we see it, FORCE a reset, no matter what state we are in.
                if (rx_sliding_window == SYNC_WORD) begin
                    sync_en <= 1;           // Reset Decryption Engine
                    rx_sliding_window <= 0; // Clear window to prevent double-trigger
                    state <= RX_WAIT_H;     // Align to expect High Byte next
                end
                
                // Standard State Machine
                else begin
                    case (state)
                        IDLE: begin
                            // Just waiting for the Sync Word (handled above)
                        end
                        
                        RX_WAIT_H: begin
                            if (rx_idle_cnt == 16'hFFFF) state <= IDLE; // Connection dropped
                            else if (spi_rx_done) begin
                                rx_buffer[15:8] <= spi_rx_data;
                                state <= RX_WAIT_L;
                            end
                        end
                        
                        RX_WAIT_L: begin
                            if (rx_idle_cnt == 16'hFFFF) state <= IDLE;
                            else if (spi_rx_done) begin
                                rx_buffer[7:0] <= spi_rx_data;
                                state <= RX_DECRYPT;
                            end
                        end
                        
                        RX_DECRYPT: begin
                            rx_fifo_din <= rx_buffer ^ chaos_key[15:0]; // Decrypt
                            next_key_en <= 1;
                            if (!rx_fifo_full) rx_fifo_wr_en <= 1;
                            state <= RX_WAIT_H; // Wait for next sample
                        end
                        
                        default: state <= IDLE;
                    endcase
                end
            end
        end
    end
endmodule