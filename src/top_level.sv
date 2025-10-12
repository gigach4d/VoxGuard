// src/top_level.sv
// MODIFIED VERSION FOR SIMULATION
// This module instantiates and connects all blocks EXCEPT the I2S controller,
// which is bypassed to allow the C++ testbench to directly inject audio data.
module top_level (
    input logic clk,
    input logic rst,
    input logic push_to_talk,

    // --- Ports for the Testbench to directly drive/monitor audio ---
    input  logic [15:0] adc_data_in,
    input  logic        adc_data_valid,
    output logic [15:0] dac_data_out,
    output logic        dac_data_valid,

    // SPI Interface (remains for future tests)
    output logic spi_sclk,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs,
    
    // --- Testbench loopback signals ---
    input  logic [15:0] radio_rx_data,
    input  logic        radio_rx_valid,
    output logic [15:0] encrypted_data_out
);

    // --- Internal Wires to Connect Modules ---
    logic        dac_ready;
    assign dac_ready = 1'b1; // <<< ADD THIS LINE TO TIE OFF DAC_READY FOR SIMULATION
    logic        spi_start;
    logic [7:0]  spi_tx_byte;
    logic [7:0]  spi_rx_byte;
    logic        spi_busy;
    logic [15:0] data_to_encrypt;
    logic [15:0] data_to_decrypt;
    logic [15:0] decrypted_data_result;
    logic [31:0] key_stream;
    logic        next_key_en;
    logic        sync_en;
    logic [31:0] sync_state;

    // --- Module Instantiations ---
    
    packet_manager pm_inst (
        .clk(clk),
        .rst(rst),
        .push_to_talk(push_to_talk),
        .dac_data_out(dac_data_out),     // Connect directly to output port
        .dac_data_valid(dac_data_valid), // Connect directly to output port
        .dac_ready(dac_ready),
        .adc_data_in(adc_data_in),       // Connect directly to input port
        .adc_data_valid(adc_data_valid), // Connect directly to input port
        .spi_start(spi_start),
        .spi_data_in(spi_tx_byte),
        .spi_data_out(spi_rx_byte),
        .spi_busy(spi_busy),
        .encrypt_data_out(data_to_encrypt),
        .decrypt_data_in(decrypted_data_result),
        .next_key_en(next_key_en),
        .sync_en(sync_en),
        .sync_state_out(sync_state)
    );

    /* --- I2S Controller is COMMENTED OUT for this test ---
    i2s_controller #( .SYS_CLK_FREQ(50_000_000) ) i2s_inst ( ... );
    */

    spi_master #( .CLK_DIV(4) ) spi_inst (
        .clk(clk),
        .rst(rst),
        .start_tx(spi_start),
        .data_in(spi_tx_byte),
        .data_out(spi_rx_byte),
        .busy(spi_busy),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );
    assign spi_cs = 1'b1;

    chaotic_generator cg_inst (
        .clk(clk),
        .rst(rst),
        .next_key_en(next_key_en),
        .sync_en(sync_en),
        .sync_state_in(sync_state),
        .key_out(key_stream)
    );

    encrypt_decrypt enc_inst (
        .data_in(data_to_encrypt),
        .key_in(key_stream),
        .data_out(encrypted_data_out)
    );

    assign data_to_decrypt = radio_rx_data;

    encrypt_decrypt dec_inst (
        .data_in(data_to_decrypt),
        .key_in(key_stream),
        .data_out(decrypted_data_result)
    );

endmodule