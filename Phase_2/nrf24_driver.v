`timescale 1ns / 1ps

module nrf24_driver (
    input wire clk, rst, tx_en, start_tx,
    input wire [255:0] tx_data,
    output reg tx_done, rx_ready,
    output reg [255:0] rx_data,
    
    output reg ce, csn, sck, 
    output wire mosi, 
    input wire miso, irq
);

    localparam S_BOOT = 0, S_CONFIG = 1, S_IDLE = 2,
               S_TX_SET_PTX = 3, S_TX_RUN = 4,
               S_TX_PULSE = 5, S_TX_WAIT = 6, S_CLEAR_IRQ = 7,
               S_FLUSH_FIFO = 8, S_RX_SET_PRX = 9, 
               S_POWER_UP_DELAY = 10, S_RX_READ = 11;

    reg [3:0] state;
    reg [7:0] config_step;
    reg [8:0] bit_cnt; 
    reg [15:0] boot_delay; 
    
    reg [263:0] shift_out; 
    reg [255:0] shift_in;

    assign mosi = shift_out[263];

    reg [1:0] clk_div;
    wire spi_tick = (clk_div == 2'b11);

    wire [8:0] target_bits = (config_step == 5 || config_step == 6) ? 48 : 
                             (config_step == 8 || config_step == 9) ? 8 : 16;

    always @(posedge clk) begin
        if (rst) clk_div <= 0;
        else     clk_div <= clk_div + 1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_BOOT;
            ce <= 0; csn <= 1; sck <= 0;
            tx_done <= 0; rx_ready <= 0;
            config_step <= 0; bit_cnt <= 0; boot_delay <= 0;
        end else if (spi_tick) begin
            tx_done <= 0; rx_ready <= 0;

            case (state)
                S_BOOT: begin
                    boot_delay <= boot_delay + 1;
                    if (boot_delay == 10) begin
                        state <= S_CONFIG;
                        config_step <= 0;
                        // FIX: Power Up, PRX Mode, CRC HARDWARE DISABLED (0x03)
                        shift_out[263:248] <= {8'h20, 8'h03}; 
                    end
                end

                S_CONFIG: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1;
                        else begin 
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == target_bits) begin 
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                config_step <= config_step + 1;
                                
                                if (config_step == 0)      shift_out[263:248] <= {8'h21, 8'h00}; 
                                else if (config_step == 1) shift_out[263:248] <= {8'h22, 8'h01}; 
                                else if (config_step == 2) shift_out[263:248] <= {8'h23, 8'h03}; 
                                else if (config_step == 3) shift_out[263:248] <= {8'h25, 8'd100}; 
                                // FIX: 2Mbps, Max Power. Clones often fail at 1Mbps.
                                else if (config_step == 4) shift_out[263:248] <= {8'h26, 8'h0F}; 
                                else if (config_step == 5) shift_out[263:216] <= {8'h2A, 40'h3E3E3E3E3E}; // Safe MAC
                                else if (config_step == 6) shift_out[263:216] <= {8'h30, 40'h3E3E3E3E3E}; // Safe MAC
                                else if (config_step == 7) shift_out[263:248] <= {8'h31, 8'h20}; 
                                else if (config_step == 8) shift_out[263:248] <= {8'hE1, 8'h00}; 
                                else if (config_step == 9) shift_out[263:248] <= {8'hE2, 8'h00}; 
                                else if (config_step == 10) shift_out[263:248] <= {8'h27, 8'h70}; 
                                else begin
                                    state <= S_POWER_UP_DELAY; 
                                    boot_delay <= 0;
                                end
                            end
                        end
                    end
                end

                S_POWER_UP_DELAY: begin
                    boot_delay <= boot_delay + 1;
                    if (boot_delay == 6000) state <= S_IDLE; 
                end

                S_IDLE: begin
                    if (tx_en) begin
                        ce <= 0; 
                        if (start_tx) begin
                            state <= S_TX_SET_PTX;
                            // FIX: PTX Mode, CRC HARDWARE DISABLED (0x02)
                            shift_out[263:248] <= {8'h20, 8'h02}; 
                        end
                    end else begin
                        ce <= 1; 
                        if (!irq) begin
                            state <= S_RX_READ;
                            shift_out[263:256] <= 8'h61; 
                        end
                    end
                end

                S_TX_SET_PTX: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1; 
                        else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 16) begin
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                state <= S_TX_RUN;
                                shift_out <= {8'hA0, tx_data}; 
                            end
                        end
                    end
                end

                S_TX_RUN: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1; 
                        else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 264) begin 
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                state <= S_TX_PULSE;
                            end
                        end
                    end
                end

                S_TX_PULSE: begin
                    ce <= 1; state <= S_TX_WAIT;
                end

                S_TX_WAIT: begin
                    ce <= 1; 
                    if (!irq) begin 
                        ce <= 0; tx_done <= 1;
                        state <= S_CLEAR_IRQ;
                        shift_out[263:248] <= {8'h27, 8'h70}; 
                    end
                end

                S_RX_READ: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) begin 
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt >= 8) shift_in <= {shift_in[254:0], miso}; 
                        end else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 264) begin
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                rx_data <= shift_in;
                                rx_ready <= 1;
                                state <= S_CLEAR_IRQ;
                                shift_out[263:248] <= {8'h27, 8'h70};
                            end
                        end
                    end
                end

                S_CLEAR_IRQ: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1; 
                        else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 16) begin
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                state <= S_FLUSH_FIFO;
                                shift_out[263:248] <= tx_en ? {8'hE1, 8'h00} : {8'hE2, 8'h00}; 
                            end
                        end
                    end
                end

                S_FLUSH_FIFO: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1; 
                        else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 8) begin 
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                if (!tx_en) begin
                                    state <= S_RX_SET_PRX; 
                                    // FIX: PRX Mode, CRC HARDWARE DISABLED (0x03)
                                    shift_out[263:248] <= {8'h20, 8'h03}; 
                                end else begin
                                    state <= S_IDLE; 
                                end
                            end
                        end
                    end
                end

                S_RX_SET_PRX: begin
                    if (csn == 1) begin csn <= 0; sck <= 0; end
                    else begin
                        sck <= !sck;
                        if (!sck) bit_cnt <= bit_cnt + 1; 
                        else begin
                            shift_out <= {shift_out[262:0], 1'b0};
                            if (bit_cnt == 16) begin
                                csn <= 1; sck <= 0; bit_cnt <= 0;
                                state <= S_IDLE;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule