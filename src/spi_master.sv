// spi_master.sv
// Generic single-byte SPI master controller.
module spi_master #(
    parameter CLK_DIV = 4 // System Clock / (2 * SPI Clock)
) (
    input logic clk,
    input logic rst,
    
    // Control interface
    input logic start_tx,       // Pulse to start a transaction
    input logic [7:0] data_in,  // Byte to transmit
    output logic [7:0] data_out, // Byte received
    output logic busy,          // High during transaction
    
    // SPI physical interface
    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso
);

    typedef enum {IDLE, TRANSFER, DONE} state_t;
    state_t state;

    logic [7:0] tx_reg, rx_reg;
    logic [$clog2(CLK_DIV):0] clk_counter;
    logic [3:0] bit_counter;

    assign busy = (state != IDLE);
    assign data_out = rx_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            spi_sclk <= 1'b1;
            clk_counter <= '0;
            bit_counter <= '0;
            tx_reg <= '0;
            rx_reg <= '0;
        end else begin
            case (state)
                IDLE: begin
                    spi_sclk <= 1'b1;
                    if (start_tx) begin
                        tx_reg <= data_in;
                        state <= TRANSFER;
                        clk_counter <= '0;
                        bit_counter <= '0;
                    end
                end
                TRANSFER: begin
                    if (clk_counter == CLK_DIV - 1) begin
                        clk_counter <= '0;
                        spi_sclk <= ~spi_sclk;
                        
                        // Shift on falling edge of SCLK
                        if (spi_sclk) begin
                             if (bit_counter < 8) begin
                                tx_reg <= tx_reg << 1;
                                rx_reg <= {rx_reg[6:0], spi_miso};
                                bit_counter <= bit_counter + 1;
                             end else begin
                                state <= DONE;
                             end
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    assign spi_mosi = tx_reg[7];

endmodule