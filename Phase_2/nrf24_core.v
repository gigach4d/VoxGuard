`timescale 1ns / 1ps

module nrf24_core (
    input  wire clk, rst, tx_en, start_tx,
    input  wire [255:0] tx_data,
    output reg  tx_done, rx_ready,
    output reg  [255:0] rx_data,
    
    output reg  ce, csn, sck, mosi,
    input  wire miso, irq // The physical IRQ pin is now completely ignored by the logic
);

    reg [2:0] clk_div;
    wire spi_tick = (clk_div == 3'd5); // 2MHz SPI Clock
    always @(posedge clk) begin
        if (rst) clk_div <= 0;
        else clk_div <= spi_tick ? 0 : clk_div + 1;
    end

    // --- SPI Transceiver ---
    reg [8:0]  spi_bits;
    reg [263:0] spi_tx_buf;
    reg [263:0] spi_rx_buf;
    reg spi_start, spi_busy, spi_done;
    reg [1:0] spi_state;
    reg [8:0] bit_cnt;

    always @(posedge clk) begin
        if (rst) begin
            spi_state <= 0; csn <= 1; sck <= 0; mosi <= 0; 
            spi_busy <= 0; spi_done <= 0;
        end else if (spi_tick) begin
            spi_done <= 0;
            case (spi_state)
                0: begin
                    csn <= 1; sck <= 0; spi_busy <= 0;
                    if (spi_start) begin
                        csn <= 0; bit_cnt <= spi_bits; 
                        spi_busy <= 1; spi_state <= 1;
                    end
                end
                1: begin sck <= 0; mosi <= spi_tx_buf[bit_cnt - 1]; spi_state <= 2; end
                2: begin 
                    sck <= 1; spi_rx_buf[bit_cnt - 1] <= miso;
                    bit_cnt <= bit_cnt - 1;
                    if (bit_cnt == 1) spi_state <= 3; else spi_state <= 1;
                end
                3: begin sck <= 0; csn <= 1; spi_done <= 1; spi_state <= 0; end
            endcase
        end
    end

    reg spi_done_prev;
    always @(posedge clk) spi_done_prev <= spi_done;
    wire spi_done_edge = spi_done && !spi_done_prev;

    // --- The Blind Polling Logic ---
    localparam S_POR       = 0,  S_INIT      = 1,  S_PWR_WAIT   = 2, 
               S_IDLE      = 3,  S_RX_POLL   = 4,  S_RX_READ    = 5,
               S_RX_CLEAR  = 6,  S_TX_CONF   = 7,  S_TX_SEND    = 8, 
               S_TX_PULSE  = 9,  S_TX_WAIT   = 10, S_TX_CLEAR   = 11, 
               S_THROTTLE  = 12;

    reg [3:0] state;
    reg [4:0] init_step, clear_step;
    reg [23:0] timer;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_POR; timer <= 0; ce <= 0; spi_start <= 0;
            tx_done <= 0; rx_ready <= 0; init_step <= 0;
        end else begin
            tx_done <= 0; rx_ready <= 0;

            case (state)
                S_POR: begin
                    timer <= timer + 1;
                    if (timer == 24'd2_400_000) begin state <= S_INIT; init_step <= 0; end // 200ms
                end

                S_INIT: begin
                    if (!spi_busy && !spi_start) begin
                        case (init_step)
                            // THE FIX: 0x7B = 0111 1011. 
                            // This explicitly masks the RX, TX, and MAX_RT interrupts. The hardware IRQ pin is now dead.
                            0:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h20_7B; end 
                            1:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h21_00; end // No Auto-Ack 
                            2:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h24_00; end // Disable Auto-Retransmit
                            3:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h22_01; end // Pipe 0
                            4:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h23_03; end // 5 Byte MAC
                            5:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h25_5A; end // Channel 90
                            6:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h26_00; end // Whisper Mode
                            7:  begin spi_bits <= 48; spi_tx_buf[47:0] <= 48'h2A_D7D7D7D7D7; end 
                            8:  begin spi_bits <= 48; spi_tx_buf[47:0] <= 48'h30_D7D7D7D7D7; end 
                            9:  begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h31_20; end // 32-Byte Payload
                            10: begin spi_bits <= 8;  spi_tx_buf[7:0]  <= 8'hE1; end     // Flush TX
                            11: begin spi_bits <= 8;  spi_tx_buf[7:0]  <= 8'hE2; end     // Flush RX
                            12: begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h27_70; end // Clear Status
                        endcase
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0;
                        if (init_step == 0) begin
                            state <= S_PWR_WAIT; timer <= 0; 
                        end else if (init_step == 12) begin
                            state <= S_IDLE; ce <= 1; timer <= 0;
                        end else begin
                            init_step <= init_step + 1;
                        end
                    end
                end

                S_PWR_WAIT: begin
                    timer <= timer + 1;
                    if (timer == 24'd18_000) begin state <= S_INIT; init_step <= 1; end
                end

                S_IDLE: begin
                    if (tx_en) begin
                        ce <= 0; 
                        if (start_tx) state <= S_TX_CONF;
                    end else begin
                        ce <= 1; 
                        timer <= timer + 1;
                        // Poll the radio every 1ms
                        if (timer == 24'd12_000) begin
                            ce <= 0; state <= S_RX_POLL; 
                        end
                    end
                end

                // --- RECEIVE POLLING FLOW ---
                S_RX_POLL: begin
                    if (!spi_busy && !spi_start) begin
                        spi_bits <= 8; spi_tx_buf[7:0] <= 8'hFF; // NOP command fetches STATUS register
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0;
                        // Check bit 6 (RX_DR) of the returned STATUS register
                        if (spi_rx_buf[6] == 1'b1) begin
                            state <= S_RX_READ;
                        end else begin
                            state <= S_IDLE; timer <= 0; ce <= 1;
                        end
                    end
                end

                S_RX_READ: begin
                    if (!spi_busy && !spi_start) begin
                        spi_bits <= 264; spi_tx_buf[263:0] <= {8'h61, 256'b0}; 
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0; rx_data <= spi_rx_buf[255:0];
                        state <= S_RX_CLEAR; clear_step <= 0;
                    end
                end

                S_RX_CLEAR: begin
                    if (!spi_busy && !spi_start) begin
                        if (clear_step == 0) begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h27_70; end
                        if (clear_step == 1) begin spi_bits <= 8;  spi_tx_buf[7:0]  <= 8'hE2; end
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0;
                        if (clear_step == 1) begin
                            rx_ready <= 1; state <= S_IDLE; timer <= 0; ce <= 1;
                        end else begin
                            clear_step <= clear_step + 1;
                        end
                    end
                end

                // --- TRANSMIT TIMED FLOW (BLIND, NO IRQ) ---
                S_TX_CONF: begin
                    if (!spi_busy && !spi_start) begin
                        // 0x7A = 0111 1010 -> MASK IRQs, PWR_UP, PTX mode
                        spi_bits <= 16; spi_tx_buf[15:0] <= 16'h20_7A; 
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0; state <= S_TX_SEND;
                    end
                end

                S_TX_SEND: begin
                    if (!spi_busy && !spi_start) begin
                        spi_bits <= 264; 
                        spi_tx_buf[263:0] <= {8'hA0, tx_data}; 
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0; state <= S_TX_PULSE; timer <= 0;
                    end
                end

                S_TX_PULSE: begin
                    ce <= 1; timer <= timer + 1;
                    if (timer == 240) begin ce <= 0; state <= S_TX_WAIT; timer <= 0; end
                end

                S_TX_WAIT: begin
                    timer <= timer + 1;
                    // BLIND TIMEOUT: Wait exactly 2ms. Do NOT check the IRQ pin.
                    // 2ms is mathematically guaranteed to be enough time to finish transmitting.
                    if (timer == 24'd24_000) begin 
                        state <= S_TX_CLEAR; clear_step <= 0;
                    end
                end

                S_TX_CLEAR: begin
                    if (!spi_busy && !spi_start) begin
                        if (clear_step == 0) begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h27_70; end
                        if (clear_step == 1) begin spi_bits <= 8;  spi_tx_buf[7:0]  <= 8'hE1; end
                        if (clear_step == 2) begin spi_bits <= 16; spi_tx_buf[15:0] <= 16'h20_7B; end // Back to PRX
                        spi_start <= 1;
                    end else if (spi_done_edge) begin
                        spi_start <= 0;
                        if (clear_step == 2) begin
                            tx_done <= 1; state <= S_THROTTLE; timer <= 0;
                        end else begin
                            clear_step <= clear_step + 1;
                        end
                    end
                end

                S_THROTTLE: begin
                    timer <= timer + 1;
                    if (timer == 24'd48_000) begin state <= S_IDLE; timer <= 0; ce <= 1; end // 4ms Cooldown
                end
            endcase
        end
    end
endmodule