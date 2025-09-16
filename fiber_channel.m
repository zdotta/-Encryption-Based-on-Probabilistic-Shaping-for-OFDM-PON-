function rx_signal = fiber_channel(tx_signal, Fs, fiber_length, attenuation_dB_km, ...
    dispersion_ps_nm_km, lambda_nm,osnr_dB)
% FIBER_CHANNEL 模拟光纤信道传输
    %  输入:
    %    tx_signal       - 发送信号 (复基带信号)
    %    Fs              - 采样率 (Hz)
    %    fiber_length    - 光纤长度 (km)
    %    attenuation_dB_km - 每公里衰减 (dB/km)
    %    dispersion_ps_nm_km - 色散系数 (ps/nm/km)
    %    lambda_nm       - 光波长 (nm)
    %
    %  输出:
    %    rx_signal       - 接收信号 (复基带信号)
    c = 3e8; % 光速 (m/s)
    lambda = lambda_nm * 1e-9; % 波长转换为米
    N = length(tx_signal);
    rng(1)
    % 计算频率向量 (从 -Fs/2 到 Fs/2)
    f = (-Fs/2:Fs/N:Fs/2-Fs/N)';
    % ==================== 1. 功率归一化 ====================
    avg_power = mean(abs(tx_signal).^2);
    tx_signal = tx_signal / sqrt(avg_power);  % 归一化到单位功率
    
    % ==================== 2. 光纤衰减 ====================
    attenuation_factor = 10^(-attenuation_dB_km * fiber_length / 20); % 电压衰减系数
    attenuated_signal = tx_signal * attenuation_factor;
    
    % ==================== 3. 色散效应 ====================
    
    
    % 计算色散相位响应
    beta2 = -dispersion_ps_nm_km * 1e-3 * (lambda^2) / (2*pi*c); % 单位: s^2/km
    dispersion_phase = exp(-1i * pi * beta2 * fiber_length * (2*pi*f).^2);
    
    % 应用色散效应 (频域处理)
    freq_signal = fftshift(fft(attenuated_signal));
    dispersed_freq = freq_signal .* dispersion_phase;
    dispersed_signal = ifft(ifftshift(dispersed_freq));
    
    
    % ==================== 4. 噪声添加 ====================
    % % 计算接收端信噪比 (考虑衰减后的信号功率)
    % rx_power = mean(abs(dispersed_signal).^2);
    %
    % % 计算等效噪声功率 (假设接收机噪声系数为5dB)
    % noise_power_dB = 10*log10(rx_power) - 30; % 30dB信噪比
    % noise_power = 10^(noise_power_dB/10);
    %
    % % 添加复高斯噪声
    % noise_real = sqrt(noise_power/2) * randi(N, 1);
    % noise_imag = sqrt(noise_power/2) * randi(N, 1);
    % rx_signal = dispersed_signal + (noise_real + 1i*noise_imag);
    rx_signal = awgn(dispersed_signal,osnr_dB);

    % % 假设光纤信道不置噪
    % rx_signal = dispersed_signal;
    % % ==================== 5. 绘图 (可选) ====================
    % figure;
    % subplot(2,1,1);
    % plot(real(tx_signal(1:1000))), hold on;
    % plot(real(rx_signal(1:1000)));
    % title('发送与接收信号对比 (实部)');
    % legend('发送信号', '接收信号');
    % 
    % subplot(2,1,2);
    % plot(imag(tx_signal(1:1000))), hold on;
    % plot(imag(rx_signal(1:1000)));
    % title('发送与接收信号对比 (虚部)');
    % legend('发送信号', '接收信号');
    
    % % 显示信道参数
    % disp('===== 光纤信道参数 =====');
    % disp(['光纤长度: ' num2str(fiber_length) ' km']);
    % disp(['总衰减: ' num2str(attenuation_dB_km * fiber_length) ' dB']);
    % disp(['色散量: ' num2str(dispersion_ps_nm_km * fiber_length) ' ps/nm']);
end