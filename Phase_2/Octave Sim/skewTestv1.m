% --- Hardware Bit-Accurate Simulation (Octave Compatible) ---
clear; clc;

% 1. Load Audio
% Make sure 'test1.wav' is in your current folder
[input, fs] = audioread('test1.wav');
if size(input,2) > 1, input = mean(input,2); end

% Convert to 16-bit integer (0 to 65535) for bitwise logic simulation
% We map the -1..1 float audio to 0..65535 unsigned integer
audio_int = uint16((input + 1) * 32767.5);
N = length(input);

% --- HARDWARE CONSTANTS (From chaotic_generator.v) ---
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

for k = 1:N
    % 1. Calculate Branches (Fixed Point math)
    mult_res_1 = x_reg * MULT_1;
    % FIXED: Use bitshift(val, -28) instead of bitsrl
    branch1 = bitshift(mult_res_1, -28);

    branch2_sub = ONE - x_reg;
    mult_res_2 = branch2_sub * MULT_2;
    % FIXED: Use bitshift(val, -28) instead of bitsrl
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

    % --- CHECKING THE HARDWARE BIT-SLICE ---

    % OPTION A: SIMULATE YOUR CURRENT (BROKEN) HARDWARE
    % This grabs bits [31:16], which includes 4 empty bits at the top.
    % You should see high correlation with this enabled.
    %this_key = uint16(bitand(bitshift(x_next, -16), 65535));

    % OPTION B: SIMULATE THE FIX (Bits [27:12])
    % Uncomment the line below to see what the fix will do
    this_key = uint16(bitand(bitshift(x_next, -12), 65535));

    key_stream(k) = this_key;

    % 5. Update State
    x_reg = x_next;

    % 6. Update LFSR (16-bit Taps: 0, 2, 3, 5)
    fb = bitxor(bitxor(bitxor(bitget(lfsr_reg,1), bitget(lfsr_reg,3)), ...
         bitget(lfsr_reg,4)), bitget(lfsr_reg,6));

    % FIXED: Use bitshift for right shift
    lfsr_reg = bitor(bitshift(lfsr_reg, -1), bitshift(uint16(fb), 15));
    if mod(k, 10000) == 0
        fprintf('Processed %d / %d samples...\n', k, N);
        fflush(stdout); % Force update the screen
    end
end

% --- Encryption & Analysis ---
cipher = bitxor(audio_int, key_stream);

% Convert back to float -1..1 for analysis
enc_float = double(cipher) / 32768.0 - 1.0;

% Calculate Correlation
R = corrcoef(input, enc_float);
fprintf('Correlation (Original vs Encrypted): %.4f\n', R(1,2));

% Plot
figure;
subplot(2,1,1); plot(input); title('Original Audio'); axis tight;
subplot(2,1,2); plot(enc_float); title('Encrypted Output (Hardware Sim)'); axis tight;
