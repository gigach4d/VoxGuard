`timescale 1ns / 1ps

module nrf24_core (
    input wire clk,
    input wire rst,
    input wire tx_mode, // 1 = PTT pressed (Talk), 0 = Listen
    
    // TX Interface
    input wire [255:0] tx_payload,
    input wire tx_trigger,
    output reg tx_busy,
    output reg tx_ack,  
    
    // RX Interface
    output reg [255:0] rx_payload,
    output reg rx_valid,
    
    // Physical NRF Pins
    output reg ce,
    output reg csn,
    output wire sck,
    output wire mosi,
    input  wire miso,
    input  wire irq
);

    // --- SPI Master Setup ---
    reg spi_start;
    reg [7:0] spi_tx_data;
    wire [7:0] spi_rx_data;
    wire spi_busy;

    spi_master spi_inst (
        .clk(clk), .rst(rst),
        .start(spi_start), .tx_data(spi_tx_data),
        .rx_data(spi_rx_data), .busy(spi_busy),
        .sck(sck), .mosi(mosi), .miso(miso)
    );

    // --- Initialization ROM (No-Ack Streaming Profile) ---
    reg [15:0] init_rom [0:10];
    initial begin
        init_rom[0] = 16'h21_00; // EN_AA: Disable Auto-Ack for all pipes
        init_rom[1] = 16'h25_4C; // RF_CH: Channel 76 (2.476 GHz)
        init_rom[2] = 16'h26_0F; // RF_SETUP: 2Mbps, 0dBm
        init_rom[3] = 16'h23_03; // SETUP_AW: 5-byte addresses
        init_rom[4] = 16'h24_00; // SETUP_RETR: Disable retries
        init_rom[5] = 16'h31_20; // RX_PW_P0: 32 byte payload size
        init_rom[6] = 16'h20_0F; // CONFIG: Power Up, PRX Mode, 2-byte CRC
        init_rom[7] = 16'hE2_00; // FLUSH_RX
        init_rom[8] = 16'hE1_00; // FLUSH_TX
        init_rom[9] = 16'h27_70; // Clear all IRQs
        init_rom[10] = 16'hFF_FF; // END MARKER
    end

    // --- State Machine ---
    localparam S_PWR_ON      = 0;
    localparam S_INIT_ROM    = 1;
    localparam S_IDLE        = 2;
    localparam S_MODE_SWITCH = 3;
    localparam S_TX_PAYLOAD  = 4;
    localparam S_RX_PAYLOAD  = 5;
    localparam S_CLEAR_IRQ   = 6;
    localparam S_FLUSH       = 7;
    localparam S_DELAY       = 8;

    reg [3:0] state = S_PWR_ON;
    reg [23:0] delay_cnt = 0;
    reg [3:0] rom_idx = 0;
    
    reg [5:0] byte_cnt = 0;
    reg [255:0] shift_reg = 0;
    reg spi_wait = 0;
    
    reg last_tx_mode = 0;
    reg flush_is_tx = 0; // 1 = Flush TX, 0 = Flush RX

    always @(posedge clk) begin
        if (rst) begin
            state <= S_PWR_ON;
            ce <= 0; csn <= 1;
            spi_start <= 0; tx_busy <= 1; rx_valid <= 0; tx_ack <= 0;
            delay_cnt <= 0; rom_idx <= 0; flush_is_tx <= 0;
        end else begin
            spi_start <= 0;
            rx_valid <= 0;

            case (state)
                S_PWR_ON: begin
                    if (delay_cnt == 24'd1_200_000) begin
                        state <= S_INIT_ROM;
                        delay_cnt <= 0;
                    end else delay_cnt <= delay_cnt + 1;
                end

                S_INIT_ROM: begin
                    if (!spi_busy && !spi_wait) begin
                        if (init_rom[rom_idx] == 16'hFFFF) begin
                            state <= S_IDLE;
                            ce <= 1; 
                            tx_busy <= 0;
                        end else begin
                            if (byte_cnt == 0) begin
                                csn <= 0; spi_tx_data <= init_rom[rom_idx][15:8]; spi_start <= 1; spi_wait <= 1; byte_cnt <= 1;
                            end else if (byte_cnt == 1) begin
                                spi_tx_data <= init_rom[rom_idx][7:0]; spi_start <= 1; spi_wait <= 1; byte_cnt <= 2;
                            end else begin
                                csn <= 1; byte_cnt <= 0; rom_idx <= rom_idx + 1;
                            end
                        end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end

                S_IDLE: begin
                    tx_ack <= 0; 
                    if (tx_mode != last_tx_mode) begin
                        last_tx_mode <= tx_mode; ce <= 0; state <= S_MODE_SWITCH; byte_cnt <= 0; tx_busy <= 1;
                    end else if (tx_mode && !irq) begin
                        // Catch phantom TX interrupts
                        state <= S_FLUSH; // FLUSH FIRST!
                        flush_is_tx <= 1; tx_busy <= 1; byte_cnt <= 0;
                    end else if (tx_mode && tx_trigger) begin
                        state <= S_TX_PAYLOAD; shift_reg <= tx_payload; byte_cnt <= 0; tx_busy <= 1; tx_ack <= 1; 
                    end else if (!tx_mode && !irq) begin
                        state <= S_RX_PAYLOAD; ce <= 0; byte_cnt <= 0; tx_busy <= 1;
                    end else begin
                        tx_busy <= 0;
                    end
                end

                S_MODE_SWITCH: begin
                    if (!spi_busy && !spi_wait) begin
                        if (byte_cnt == 0) begin csn <= 0; spi_tx_data <= 8'h20; spi_start <= 1; spi_wait <= 1; byte_cnt <= 1; end
                        else if (byte_cnt == 1) begin spi_tx_data <= tx_mode ? 8'h0E : 8'h0F; spi_start <= 1; spi_wait <= 1; byte_cnt <= 2; end
                        else begin csn <= 1; if (!tx_mode) ce <= 1; state <= S_IDLE; end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end

                S_TX_PAYLOAD: begin
                    if (!spi_busy && !spi_wait) begin
                        if (byte_cnt == 0) begin csn <= 0; spi_tx_data <= 8'hA0; spi_start <= 1; spi_wait <= 1; byte_cnt <= 1; end
                        else if (byte_cnt <= 32) begin
                            spi_tx_data <= shift_reg[255:248]; shift_reg <= {shift_reg[247:0], 8'h00};
                            spi_start <= 1; spi_wait <= 1; byte_cnt <= byte_cnt + 1;
                        end else begin 
                            csn <= 1; ce <= 1; state <= S_IDLE; byte_cnt <= 0; 
                        end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end

                S_RX_PAYLOAD: begin
                    if (!spi_busy && !spi_wait) begin
                        if (byte_cnt == 0) begin csn <= 0; spi_tx_data <= 8'h61; spi_start <= 1; spi_wait <= 1; byte_cnt <= 1; end
                        else if (byte_cnt <= 32) begin
                            if (byte_cnt > 1) shift_reg <= {shift_reg[247:0], spi_rx_data};
                            spi_tx_data <= 8'hFF; spi_start <= 1; spi_wait <= 1; byte_cnt <= byte_cnt + 1;
                        end else begin
                            csn <= 1;
                            rx_payload <= {shift_reg[247:0], spi_rx_data};
                            rx_valid <= 1;
                            state <= S_FLUSH; // THE FIX: Go to flush BEFORE clearing IRQ
                            flush_is_tx <= 0; byte_cnt <= 0;
                        end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end

                S_FLUSH: begin
                    if (!spi_busy && !spi_wait) begin
                        if (byte_cnt == 0) begin
                            csn <= 0; spi_tx_data <= flush_is_tx ? 8'hE1 : 8'hE2; 
                            spi_start <= 1; spi_wait <= 1; byte_cnt <= 1; 
                        end else begin
                            csn <= 1; state <= S_CLEAR_IRQ; byte_cnt <= 0;
                        end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end

                S_CLEAR_IRQ: begin
                    if (!spi_busy && !spi_wait) begin
                        if (byte_cnt == 0) begin csn <= 0; spi_tx_data <= 8'h27; spi_start <= 1; spi_wait <= 1; byte_cnt <= 1; end
                        else if (byte_cnt == 1) begin spi_tx_data <= 8'h70; spi_start <= 1; spi_wait <= 1; byte_cnt <= 2; end
                        else begin
                            csn <= 1;
                            state <= S_DELAY; // Let the physical pins recover
                            delay_cnt <= 0;
                        end
                    end else if (!spi_busy && spi_wait) spi_wait <= 0;
                end
                
                S_DELAY: begin
                    if (!tx_mode) ce <= 1; // Turn listening back on if we are in RX mode
                    
                    // Wait 20us (240 clocks at 12MHz) for the silicon to physically pull IRQ High
                    if (delay_cnt < 24'd240) begin
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        byte_cnt <= 0;
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end
endmodule