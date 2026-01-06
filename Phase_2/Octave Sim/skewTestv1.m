% --- Hardware Bit-Accurate Simulation (Octave Compatible) ---
clear; clc; close all;

% 1. Load Audio
try
    [input, fs] = audioread('test1.wav');
catch
    error('File "test1.wav" not found. Please ensure it is in the working directory.');
end

if size(input,2) > 1, input = mean(input,2); end

% Convert to 16-bit integer (0 to 65535) for bitwise logic simulation
audio_int = uint16((input + 1) * 32767.5);
N = length(input);

% --- HARDWARE CONSTANTS ---
ONE     = uint64(hex2dec('10000000'));
P_PARAM = uint64(hex2dec('07333333'));
MULT_1  = uint64(hex2dec('238E38E3'));
MULT_2  = uint64(hex2dec('1D1745D1'));
SEED_X  = uint64(hex2dec('01F97414'));
SEED_L  = uint16(hex2dec('ACE1'));

% --- SIMULATION LOOP ---
x_reg = SEED_X;
lfsr_reg = SEED_L;
key_stream = zeros(N, 1, 'uint16');

% [NEW] Setup for Chaos Visualization
% We record the first 2000 states to verify the map shape
viz_samples = 2000;
x_history = zeros(viz_samples, 1);

fprintf('Starting encryption simulation...\n');

for k = 1:N
    % [NEW] Capture state for plotting (Normalized 0.0 to 1.0)
    if k <= viz_samples
        x_history(k) = double(x_reg) / double(ONE);
    end

    % 1. Calculate Branches (Fixed Point math)
    mult_res_1 = x_reg * MULT_1;
    branch1 = bitshift(mult_res_1, -28);

    branch2_sub = ONE - x_reg;
    mult_res_2 = branch2_sub * MULT_2;
    branch2 = bitshift(mult_res_2, -28);

    % 2. Select Raw
    if x_reg < P_PARAM
        x_next = branch1;
    else
        x_next = branch2;
    end

    % 3. Perturbation (XOR with LFSR)
    x_next = bitxor(x_next, uint64(lfsr_reg));

    % 4. Cap Value
    if x_next >= ONE
        x_next = bitand(x_next, ONE - 1);
    end

    % 5. Bit-Slice extraction (Simulating the FIX: Bits [27:12])
    this_key = uint16(bitand(bitshift(x_next, -12), 65535));
    key_stream(k) = this_key;

    % 6. Update State
    x_reg = x_next;

    % 7. Update LFSR (16-bit Taps: 0, 2, 3, 5)
    fb = bitxor(bitxor(bitxor(bitget(lfsr_reg,1), bitget(lfsr_reg,3)), ...
         bitget(lfsr_reg,4)), bitget(lfsr_reg,6));
    lfsr_reg = bitor(bitshift(lfsr_reg, -1), bitshift(uint16(fb), 15));

    if mod(k, 50000) == 0
        fprintf('Processed %d / %d samples...\n', k, N);
        fflush(stdout);
    end
end

% --- Encryption ---
cipher = bitxor(audio_int, key_stream);
enc_float = double(cipher) / 32768.0 - 1.0;

% --- Analysis & Results ---
R = corrcoef(input, enc_float);
fprintf('\n--- Results ---\n');
fprintf('Correlation (Original vs Encrypted): %.6f\n', R(1,2));

% FIGURE 1: Waveform Comparison
figure('Name', 'Waveform Analysis');
subplot(2,1,1);
plot(input, 'b');
title('Original Audio Signal');
ylabel('Amplitude'); axis tight;

subplot(2,1,2);
plot(enc_float, 'r');
title('Encrypted Audio Signal (White Noise-like)');
ylabel('Amplitude'); axis tight;

% FIGURE 2: Histogram Analysis
figure('Name', 'Histogram Analysis');
subplot(3,1,1);
hist(audio_int, 256); title('Histogram: Original Audio');
subplot(3,1,2);
hist(key_stream, 256); title('Histogram: Chaotic Key Stream');
subplot(3,1,3);
hist(cipher, 256); title('Histogram: Encrypted Audio');

% [NEW] FIGURE 3: Chaotic Map Evolution
figure('Name', 'Chaotic Map Analysis');

% Subplot 1: Return Map (x_n+1 vs x_n)
% This proves the hardware is implementing a Skew Tent Map
subplot(2,1,1);
hold on;
% Plot the theoretical Skew Tent shape for reference
p_float = double(P_PARAM) / double(ONE);
plot([0, p_float, 1], [0, 1, 0], 'k-', 'LineWidth', 2);
% Plot the actual simulated points
scatter(x_history(1:end-1), x_history(2:end), 10, 'b', 'filled', 'MarkerFaceAlpha', 0.5);
title('Return Map: x_{n+1} vs x_n (Hardware Simulation)');
xlabel('Current State (x_n)');
ylabel('Next State (x_{n+1})');
legend('Theoretical Skew Tent', 'Simulated States');
grid on; axis square;

% Subplot 2: Time Series (First 100 samples)
% Shows the sensitive dependence on initial conditions
subplot(2,1,2);
plot(x_history(1:100), 'r.-', 'LineWidth', 1);
title('Chaotic Orbit Evolution (First 100 Iterations)');
xlabel('Iteration Number (n)');
ylabel('State Value (Normalized 0-1)');
ylim([0 1]); grid on;

fprintf('Simulation complete. Plots generated.\n');
