clc;clear;close all;
%% 全局参数初始化
% 发送端参数 (tx_前缀)
tx_N_FFT = 512;
tx_CP_ratio = 1/4;
tx_mod_order = 16;
tx_used_subcarriers = 240;
tx_num_symbols = 10;
tx_pilot_interval = 15;
tx_phase_group_num = 3;
% tx_seq_type = 'logistic';
tx_key = '12345lyy';
tx_x0 = 0.6;
tx_n = 15;  % FEC参数
tx_k = 11;
tx_interleave_key = 'Interleave';

% 频谱异常的根本原因计算
% 需要同时提高符号率
tx_symbol_rate = 1.5e9;
subcarrier_spacing = tx_symbol_rate / (tx_used_subcarriers);

% 更新系统带宽
system_bandwidth = tx_used_subcarriers*subcarrier_spacing;
tx_sample_rate = 4e9;       % 采样率

disp(['理论子载波间隔: ', num2str(subcarrier_spacing/1e6), ' MHz']);
disp(['实际FFT分辨率: ', num2str(tx_sample_rate/tx_N_FFT/1e6), ' MHz']);



%% ============== 发送端处理流程 ==============
% 1. 生成原始数据
tx_raw_bits = randi([0 1], tx_num_symbols*tx_used_subcarriers*log2(tx_mod_order), 1);
tx_seq_length_min = tx_used_subcarriers*tx_num_symbols*log2(tx_mod_order);

% 2. 混沌加密
tx_key_stream = GenerateChaosSeq(tx_key, tx_x0, tx_seq_length_min);
tx_encrypted_bits = xor_encrypt(tx_raw_bits, tx_key_stream);

% prob_dist = [0.1265 0.3735 0.3735 0.1265];
% [shaped_data,shaped_bits] = probabilistic_shaping(tx_encrypted_bits, prob_dist,tx_used_subcarriers,tx_mod_order);

% 3. FEC编码
tx_bits_per_symbol = tx_used_subcarriers * log2(tx_mod_order);
[tx_encoded_data, tx_padding_info] = improved_fec_encoder(...
    tx_encrypted_bits, tx_n, tx_k, tx_bits_per_symbol);

% 4. 交织
tx_interleaved_data = interleave(tx_encoded_data, tx_interleave_key);

% 5. QAM调制
tx_parallel_data = serial_to_parallel(tx_interleaved_data, tx_used_subcarriers, tx_mod_order);
tx_qam_symbols = qam_mapper(tx_parallel_data, tx_mod_order);
% tx_qam_symbols = round(tx_qam_symbols*1e4)/1e4;


% 6. 混沌置乱
tx_num_symbols_actual = size(tx_qam_symbols, 2);
tx_scrambled_data = scramble_with_logistic(tx_qam_symbols, tx_key, tx_x0, ...
    tx_seq_length_min, tx_used_subcarriers, tx_num_symbols_actual);



% 7. 插入导频
[tx_pilot_symbols, tx_pilot_indices, tx_data_with_pilots,carriers_with_pilots] = insert_pilots(...
    tx_scrambled_data, tx_mod_order, tx_pilot_interval, 'BPSK');
tx_carriers_with_pilots = carriers_with_pilots;
% 插入导频后添加
save('pilot_symbols.mat', 'tx_pilot_symbols', 'tx_pilot_indices','carriers_with_pilots');
% %仅保留小数点后四位的值
% tx_data_with_pilots = round(tx_data_with_pilots*10000)/10000;


osnr_range = 10:2:50; % OSNR变化范围
phase_seq_types = {'none', 'logistic', 'random', 'hadamard'};
tx_power_levels = [0,4]; % dBm 入纤功率（两组图）

for tx_power_idx = 1:length(tx_power_levels)
    tx_power = tx_power_levels(tx_power_idx);
    figure;
    hold on;
    legend_entries = {};
    for idx_seq = 1:length(phase_seq_types)
        ber_curve = zeros(1, length(osnr_range));
        tx_seq_type = phase_seq_types{idx_seq};
        tx_phase_group_num = 3;  % 固定组数，控制变量
        % 8. SLM降低PAPR

        if strcmp(tx_seq_type, 'none')
            tx_time_signal = ifft(tx_data_with_pilots,tx_N_FFT);
        else
            % 生成统一的相位扰动矩阵
            tx_phase_perturbations = generate_phase_perturbations(...
                tx_seq_type, tx_key, tx_x0, tx_phase_group_num, tx_N_FFT, tx_carriers_with_pilots);
            % SLM处理
            [tx_time_signal, tx_phase_indices, ~] = slm_papr_reduction(...
                tx_data_with_pilots, tx_N_FFT, tx_phase_perturbations);
        end


        %%
        tx_freq_signal = fft(tx_time_signal,tx_N_FFT);
        tx_start_idx = floor((tx_N_FFT - tx_carriers_with_pilots)/2) + 1;
        tx_end_idx = tx_start_idx + tx_carriers_with_pilots - 1;
        tx_freq_signal = tx_freq_signal(tx_start_idx:tx_end_idx,:);



        %%

        % 9. 添加循环前缀
        tx_CP_length = round(tx_N_FFT * tx_CP_ratio);
        tx_signal_with_cp = add_cp(tx_time_signal, tx_CP_length);

        % 10. 生成发送信号
        tx_final_signal = parallel_to_serial(tx_signal_with_cp);

        % 11. 归一化处理
        I = real(tx_final_signal(:));
        Q = imag(tx_final_signal(:));
        max_val = max([max(abs(I)) max(abs(Q))]);
        I_norm = I/max_val;
        Q_norm = Q/max_val;

        OFDM = I_norm + 1i*Q_norm;

        for idx_osnr = 1:length(osnr_range)
            osnr_db = osnr_range(idx_osnr);
            %% 信道
            % % 光纤信道传输
            fiber_length = 100;         % 光纤长度 (km)
            attenuation_dB_km = 0.2;    % 每公里衰减 (dB/km)
            dispersion_ps_nm_km = 200;   % 色散系数 (ps/nm/km)
            lambda_nm = 1552;           % 光波长 (nm)
            % 控制入纤功率
            target_power_linear = 10^(tx_power/10);
            OFDM = OFDM * sqrt(target_power_linear);  % 信号幅度决定功率
            rx_received_signal = fiber_channel(...
                OFDM, ...               % 发送信号
                tx_sample_rate, ...     % 采样率
                fiber_length, ...       % 光纤长度
                attenuation_dB_km, ...  % 衰减系数
                dispersion_ps_nm_km, ...% 色散系数
                lambda_nm, ...
                osnr_db);             % 波长
            time = (0:length(tx_final_signal)-1) / tx_sample_rate; % 时间向量（单位：秒）

            %% ============== 接收端处理流程 ==============
            % 接收端参数 (rx_前缀)
            rx_CP_ratio = tx_CP_ratio;  % 与发送端一致
            rx_N_FFT = tx_N_FFT;
            rx_mod_order = tx_mod_order;
            rx_used_subcarriers = tx_used_subcarriers;
            rx_phase_group_num = tx_phase_group_num;
            % rx_seq_type = tx_seq_type;

            % 1. 信号预处理
            rx_symbol_length = rx_N_FFT + round(rx_N_FFT * rx_CP_ratio);
            rx_num_symbols = floor(length(rx_received_signal) / rx_symbol_length);
            % 截断
            rx_truncated_signal = rx_received_signal(1:rx_num_symbols*rx_symbol_length);
            % 串并转换
            rx_parallel_signal = serial_to_parallel_t(rx_truncated_signal,rx_symbol_length);

            % 2. 移除循环前缀
            rx_time_signal = rx_parallel_signal(round(rx_N_FFT*rx_CP_ratio)+1:end, :);

            % 3. 提取有效子载波
            % 计算有效子载波位置
            load('pilot_symbols.mat');
            rx_carriers_with_pilots = carriers_with_pilots;
            rx_start_idx = floor((rx_N_FFT - rx_carriers_with_pilots)/2) + 1;
            rx_end_idx = rx_start_idx + rx_carriers_with_pilots - 1;

            % 4. FFT转换
            rx_freq_signal = fft(rx_time_signal, rx_N_FFT);

            rx_valid_freq = rx_freq_signal(rx_start_idx:rx_end_idx, :);
            % 观察信道估计之前的星座图


            if strcmp(tx_seq_type, 'none')
                rx_demodslm_freq = rx_valid_freq;
            else
                % 5. SLM解调
                % 使用相同的函数生成相位扰动
                rx_phase_perturbations = generate_phase_perturbations(...
                    tx_seq_type, tx_key, tx_x0, rx_phase_group_num, rx_N_FFT, rx_carriers_with_pilots);

                % SLM解调
                rx_demodslm_freq = slm_demod(rx_valid_freq, rx_phase_perturbations,...
                    tx_phase_indices, rx_start_idx, rx_end_idx,tx_pilot_indices);
            end
            % %仅保留小数点后四位的值
            % rx_demodslm_freq = round(rx_demodslm_freq*10000)/10000;
            % %观察slm解调是否成功
            % rx = rx_demodslm_freq(:);
            % tx = tx_data_with_pilots(:);
            % sum(rx(1:length(rx))~=tx(1:length(rx)))



            % 6. 信道均衡
            % 应用信道均衡

            channel_est = histogram_channel(rx_demodslm_freq, tx_pilot_symbols, tx_pilot_indices);
            rx_valid_freq_H = rx_demodslm_freq ./ channel_est;
            % rx_valid_freq_H = round(rx_valid_freq_H*1e4)/1e4; %保留小数点后四位


            % 7. 移除导频（使用解置乱后的导频索引）
            rx_data_freq = rx_valid_freq_H(~tx_pilot_indices, :);
            se_rx_data_freq = rx_data_freq(:);



            % 8. 解置乱
            rx_row_perm1 = generate_permutation(...
                GenerateChaosSeq([tx_key '_row1'], tx_x0, rx_used_subcarriers), rx_used_subcarriers);
            rx_col_perm = generate_permutation(...
                GenerateChaosSeq([tx_key '_col'], tx_x0, rx_num_symbols), rx_num_symbols);
            rx_row_perm2 = generate_permutation(...
                GenerateChaosSeq([tx_key '_row2'], tx_x0, rx_used_subcarriers), rx_used_subcarriers);

            rx_descrambled_data = descramble_with_logistic(...
                rx_data_freq ,rx_row_perm1, rx_col_perm, rx_row_perm2);

            se_descrambled_data = rx_descrambled_data(:);
            se_tx_qam_symbols = tx_qam_symbols(:);

            % 比较解置乱后与发送端未置乱的误码个数 应该为导频数*符号数
            error_scrambled=sum(se_descrambled_data(1:length(se_tx_qam_symbols))~=se_tx_qam_symbols(1:length(se_tx_qam_symbols)));
            fprintf('解置乱后错码：%d\n',error_scrambled)


            % 9. QAM解调
            rx_demod_bits_parrallel = qam_demapper(rx_descrambled_data, rx_mod_order);

            % 10. 解交织
            rx_bit_serial = rx_demod_bits_parrallel(:);
            rx_deinterleaved_bits = deinterleave(rx_bit_serial, tx_interleave_key);

            length_interleaved = length(tx_encoded_data);
            error_interleaved = sum(rx_deinterleaved_bits(1:length_interleaved)~=tx_encoded_data(1:length_interleaved));
            fprintf('解交织后错码：%d\n',error_interleaved)
            % 11. FEC解码
            rx_decoded_bits = improved_fec_decoder(...
                rx_deinterleaved_bits, tx_n, tx_k, tx_padding_info);

            % 12. 解密
            rx_decrypt_key = GenerateChaosSeq(tx_key, tx_x0, length(rx_decoded_bits));
            rx_final_bits = xor_decrypt(rx_decoded_bits, rx_decrypt_key);

            %% 性能评估
            min_len = min(length(tx_raw_bits), length(rx_final_bits));
            errors = sum(tx_raw_bits(1:min_len) ~= rx_final_bits(1:min_len));
            ber = errors / min_len;
            fprintf('系统误码率(BER): %.4f\n', ber);
            fprintf('错误比特数: %d / %d\n', errors, min_len);
            ber_curve(idx_osnr) = ber;
        end
        semilogy(osnr_range, ber_curve, '-o', 'LineWidth', 1.5);
        legend_entries{end+1} = tx_seq_type;
        all_ber_results{tx_power_idx, idx_seq} = ber_curve;
    end
    xlabel('OSNR (dB)');
    ylabel('Bit Error Rate (BER)');
    title(sprintf('BER vs OSNR @ %ddBm Launch Power', tx_power));
    legend(legend_entries, 'Location', 'southwest');
    grid on;
end

