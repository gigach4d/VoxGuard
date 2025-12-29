[input, fs] = audioread('test1.wav');	%audio file input
if size(input,2) > 1
    input = mean(input,2); %mono conversion
end
N = length(input);

r = 4.0; %chaos parameter
x = zeros(N,1);
x(1) = 0.1234; %secret (fixed) key seed
for k = 2:N
    x(k) = r * x(k-1) * (1 - x(k-1));
end

audio_int = int16(input * 2^15);
key_int = int16(x * (2^16-1) - 2^15);

cipher = bitxor(audio_int, key_int);
audiowrite('encrypted.wav', double(cipher)/2^15, fs);

recovered = bitxor(cipher, key_int);
audiowrite('recovered.wav', double(recovered)/2^15, fs);


figure;
subplot(3,1,1); plot(input); title('Original'); axis tight;
subplot(3,1,2); plot(double(cipher)/2^15); title('Encrypted'); axis tight;
subplot(3,1,3); plot(double(recovered)/2^15); title('Decrypted'); axis tight;


fprintf('--- Basic Analysis ---\n');

orig = input;
dec  = double(recovered)/2^15;
enc  = double(cipher)/2^15;

mse_val = mean((orig - dec).^2);
corr_val = corrcoef(orig, dec);
fprintf('MSE (decrypted vs. original): %.6f\n', mse_val);
fprintf('Correlation (original vs. decrypted): %.4f\n', corr_val(1,2));

corr_enc = corrcoef(orig, enc);
fprintf('Correlation (input vs. encrypted): %.4f\n', corr_enc(1,2));

figure;
hist(enc, 100);
title('Histogram of Encrypted Audio');
xlabel('Encrypted Value');
ylabel('Count');

max_lag = 100;
key_double = double(key_int);
s = key_double - mean(key_double); % De-mean the signal
acor = zeros(max_lag+1, 1);
for lag = 0:max_lag
    acor(lag+1) = sum(s(1:end-lag) .* s(1+lag:end));
end
acor = acor / acor(1); % Normalize by the value at lag 0
lags = 0:max_lag;

figure;
plot(lags, acor, '.-');
grid on;
title('Autocorrelation of Key Stream');
xlabel('Lag');
ylabel('Autocorrelation');
xlim([0 max_lag]);

fprintf('\n--- Extended Analysis ---\n');

% 1. Key Sensitivity Test
x_sens = zeros(N,1);
x_sens(1) = 0.123400000000001; %small change in secret key
for k = 2:N
    x_sens(k) = r * x_sens(k-1) * (1 - x_sens(k-1));
end
key_sens_int = int16(x_sens * (2^16-1) - 2^15);
recovered_sens = bitxor(cipher, key_sens_int);
dec_sens = double(recovered_sens)/2^15;

mse_sens = mean((orig - dec_sens).^2);
corr_sens = corrcoef(orig, dec_sens);
fprintf('Key Sensitivity MSE: %.6f\n', mse_sens);
fprintf('Key Sensitivity Correlation: %.4f\n', corr_sens(1,2));

SNR_dB = 25;
encrypted_double = double(cipher);
signal_power = mean(encrypted_double.^2);
noise_power = signal_power / (10^(SNR_dB / 10));
noise = sqrt(noise_power) * randn(size(encrypted_double));
noisy_cipher = int16(encrypted_double + noise);
recovered_noisy = bitxor(noisy_cipher, key_int);
dec_noisy = double(recovered_noisy)/2^15;

mse_noisy = mean((orig - dec_noisy).^2);
corr_noisy = corrcoef(orig, dec_noisy);
fprintf('Channel Noise MSE: %.6f\n', mse_noisy);
fprintf('Channel Noise Correlation: %.4f\n', corr_noisy(1,2));

r_sync = 4.0 - 1e-12;
x_sync = zeros(N,1);
x_sync(1) = x(1);
for k = 2:N
    x_sync(k) = r_sync * x_sync(k-1) * (1 - x_sync(k-1));
end
key_sync_int = int16(x_sync * (2^16-1) - 2^15);
recovered_sync = bitxor(cipher, key_sync_int);
dec_sync = double(recovered_sync)/2^15;

mse_sync = mean((orig - dec_sync).^2);
corr_sync = corrcoef(orig, dec_sync);
fprintf('Sync Error MSE: %.6f\n', mse_sync);
fprintf('Sync Error Correlation: %.4f\n', corr_sync(1,2));

figure;
subplot(3,1,1);
plot(dec_sens);
title('Decryption with Slightly Wrong Key (Key Sensitivity)');
axis tight;

subplot(3,1,2);
plot(dec_noisy);
title('Decryption of Noisy Signal (Channel Noise)');
axis tight;

subplot(3,1,3);
plot(dec_sync);
title('Decryption with Slight Sync Error (r mismatch)');
axis tight;
