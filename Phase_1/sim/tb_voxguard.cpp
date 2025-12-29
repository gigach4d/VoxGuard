// sim/tb_voxguard.cpp
#include "Vtop_level.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cmath>

int main(int argc, char **argv) {
    // Initialization
    Verilated::commandArgs(argc, argv);
    Vtop_level* top = new Vtop_level;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Simulation variables
    vluint64_t sim_time = 0;
    int16_t adc_sample = 0;
    int16_t encrypted_sample_buffer = 0;

    // Simulation Loop
    while (sim_time < 100000) {
        top->clk = !top->clk;
        if (sim_time < 10) {
            top->rst = 1;
        } else {
            top->rst = 0;
        }

        if (top->clk) {
            // Default values
            top->push_to_talk = 0;
            top->adc_data_valid = 0;
            top->radio_rx_valid = 0;

            // TRANSMIT PHASE (100 to 50000)
            if (sim_time > 100 && sim_time < 50000) {
                top->push_to_talk = 1;
                adc_sample = static_cast<int16_t>(16384.0 * sin(2.0 * 3.14159 * sim_time / 2000.0));
                top->adc_data_in = adc_sample;
                top->adc_data_valid = 1;
            } 
            // RECEIVE PHASE (50000 onwards)
            else if (sim_time >= 50000) {
                top->push_to_talk = 0;
                top->radio_rx_data = encrypted_sample_buffer;
                top->radio_rx_valid = 1;
            }
        }

        top->eval();

        // On the falling edge of the clock, capture the encrypted data
        if (!top->clk && sim_time > 100 && sim_time < 50000) {
            encrypted_sample_buffer = top->encrypted_data_out;
        }

        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete top;
    return 0;
}