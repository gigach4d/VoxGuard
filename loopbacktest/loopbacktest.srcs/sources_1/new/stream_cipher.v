`timescale 1ns / 1ps

module stream_cipher (
    input wire clk,
    input wire rst,
    input wire sync_reset,    
    input wire [15:0] data_in,
    input wire data_valid,
    output reg [15:0] data_out,
    output reg valid_out
);
    wire [31:0] chaotic_key;
    
    // Instantiate your exact chaotic_generator
    chaotic_generator stm_inst (
        .clk(clk),
        .rst(rst),
        .next_key_en(data_valid), 
        .sync_en(sync_reset),     
        .sync_state_in(32'h01F97414), 
        .key_out(chaotic_key)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 0;
            data_out <= 0;
        end else begin
            valid_out <= 0;
            if (data_valid) begin
                // XOR the audio with the 16 highest fractional bits of the Skew-Tent Map
                data_out <= data_in ^ chaotic_key[27:12];
                valid_out <= 1;
            end
        end
    end
endmodule