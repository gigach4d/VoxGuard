# FPGA VoxGuard: Chaos-Based Real-Time Secure Audio Communication

FPGA VoxGuard is a secure digital voice system that uses chaos theory for robust, hardware-friendly encryption. Designed to replace vulnerable analog voice systems, VoxGuard operates as a full two-way digital radio transceiver capable of real-time encrypted communication.

## Hardware Architecture

* **Processing Core:** The digital datapath and cryptographic engines are executed on a Digilent Cmod S7 board, utilizing a Xilinx Spartan-7 FPGA.


* **Audio Acquisition:** Voice capture is handled by an INMP441 omnidirectional MEMS microphone. This module bypasses external ADCs by outputting a digital Pulse Code Modulation (PCM) stream directly to the FPGA via a native I2S interface.


* **Wireless Transmission:** The encrypted packets are transmitted over the air using an nRF24L01+ radio transceiver operating in the 2.4 GHz ISM band.


* **Audio Reconstruction:** The receiving FPGA outputs the decrypted plaintext I2S stream to a PCM5102A Digital-to-Analog Converter (DAC). A PAM8403 Class-D audio amplifier then boosts this analog signal to drive an external 5W speaker.



## Cryptographic Core & System Logic

* **Hybrid Chaotic Key Generation:** The system generates its cryptographic keystream using a discretized Skew Tent Map paired with a Linear Feedback Shift Register (LFSR). The parallel LFSR applies continuous mathematical perturbations to the chaotic map's internal state, preventing finite-precision cycle collapse and vastly extending the key's period.


* **Fixed-Point DSP Arithmetic:** To ensure high throughput without excessive logic cell consumption, the chaotic map utilizes 32-bit fixed-point arithmetic (Q2.30 format) mapped directly to the Spartan-7's DSP slices.


* **Zero-Latency Stream Cipher:** Encryption is achieved through a purely combinational bitwise XOR operation between the 16-bit I2S audio samples and the 16 Least Significant Bits (LSBs) of the chaotic keystream. This hardware-level execution introduces zero perceptible audio latency.


* **FSM Packet Management:** A central Finite State Machine (FSM) orchestrates the datapath, packaging ciphertext into strict 256-bit frames. These frames include a 16'hCAFE preamble and an 8-bit plaintext sequence number.


* **Gap-Detection Synchronization:** The receiver utilizes the plaintext sequence numbers to detect dropped packets and mathematically fast-forward its local chaotic generator, ensuring perfect cryptographic lockstep in noisy RF environments.



---

### Legal & Copyright Notice

> **Copyright (c) 2026 Sreejith T.R, Sharon Benny, Mohamed Afsal, Pranav Ramesh Mannatt. All Rights Reserved.**
> This repository is public strictly for academic visibility, portfolio purposes, and prior art documentation. No license is granted to use, modify, copy, or distribute this code, the associated SystemVerilog logic, or the physical hardware designs.
