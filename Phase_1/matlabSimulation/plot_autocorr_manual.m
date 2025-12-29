function plot_autocorr_manual(x, maxLag)
    x = x(:) - mean(x);  % zero mean
    n = length(x);
    acf = zeros(maxLag+1,1);
    
    for lag = 0:maxLag
        acf(lag+1) = sum(x(1:n-lag) .* x(1+lag:n)) / (n - lag);
    end
    
    % Normalize
    acf = acf / acf(1);
    
    figure;
    stem(0:maxLag, acf, 'filled');
    xlabel('Lag');
    ylabel('Autocorrelation');
    title('Autocorrelation of Key Stream (manual)');
    grid on;
end
