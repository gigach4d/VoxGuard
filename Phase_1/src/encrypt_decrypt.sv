// encrypt_decrypt.sv
// Performs the XOR operation for both encryption and decryption.
module encrypt_decrypt (
    input  logic [15:0] data_in,
    input  logic [31:0] key_in,
    output logic [15:0] data_out
);

    // XOR the data with the upper 16 bits of the key
    assign data_out = data_in ^ key_in[31:16];

endmodule