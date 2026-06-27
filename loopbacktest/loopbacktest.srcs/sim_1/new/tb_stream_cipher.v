`timescale 1ns / 1ps

module tb_stream_cipher;

    // Inputs
    reg clk;
    reg rst;
    reg sync_reset;
    reg [15:0] data_in;
    reg data_valid;

    // Outputs
    wire [15:0] data_out;
    wire valid_out;

    // Instantiate your exact Stream Cipher
    stream_cipher uut (
        .clk(clk),
        .rst(rst),
        .sync_reset(sync_reset),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // 12 MHz Clock Generation (83.33 ns period)
    always #41.66 clk = ~clk;

    integer file;
    integer i;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        sync_reset = 0;
        data_in = 16'd0;
        data_valid = 0;

        // Open CSV file for writing
        file = $fopen("voxguard_sim_data.csv", "w");
        if (file == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end
        
        // Write the Headers perfectly for the Python script
        $fdisplay(file, "adc_data,encrypted_data");

        // Release Reset
        #100;
        rst = 0;

        // Fire the Sync Pulse (Simulates pressing PTT)
        #100;
        sync_reset = 1;
        #83.33;
        sync_reset = 0;
        #100;

        $display("Generating 10,000 samples. Please wait...");

        // Generate 10,000 samples (~0.42 seconds of audio at 23.4 kHz)
        for (i = 0; i < 10000; i = i + 1) begin
            // Wait 42.6us (Simulating the slow I2S microphone arrival rate)
            #42600;
            
            // Create a Ramp Wave: A perfectly predictable diagonal line
            data_in = data_in + 16'd5;
            
            // Pulse the valid flag for exactly 1 clock cycle
            data_valid = 1;
            #83.33;
            data_valid = 0;
        end

        // Close the file and end the simulation
        $fclose(file);
        $display("Done! Saved to voxguard_sim_data.csv");
        $finish;
    end

    // The Capture Logic: ONLY write to the CSV when a valid encrypted frame pops out
    always @(posedge clk) begin
        if (valid_out) begin
            // $signed() forces it to write normal negative/positive numbers
            $fdisplay(file, "%d,%d", $signed(data_in), $signed(data_out));
        end
    end

endmodule