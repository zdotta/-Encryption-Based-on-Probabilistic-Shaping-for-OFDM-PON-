clc;clear;close all;
%% 全局参数初始化
% 发送端参数 (tx_前缀)
tx_N_FFT = 512;
tx_CP_ratio = 1/4;
tx_mod_order = 16;
tx_used_subcarriers = 240;
tx_num_symbols = 10;
tx_pilot_interval = 15;
% tx_phase_group_num = 2;
tx_seq_type = 'logistic';
tx_key = '202208030124wzd';
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



%lab1:绘制不同相位组数时的ccdf
figure;
hold on;
colors = lines(5); % 获取5种不同颜色
legend_entries = cell(1, 5); % 图例
pre_papr = 0;
pre_ccdf = 0;
for idx = 1:5
    tx_phase_group_num = idx - 1;
    if tx_phase_group_num ==0
        tx_time_signal = ifft(tx_data_with_pilots,tx_N_FFT);
    else
        % 生成统一的相位扰动矩阵
        tx_phase_perturbations = generate_phase_perturbations(...
            tx_seq_type, tx_key, tx_x0, tx_phase_group_num, tx_N_FFT, tx_carriers_with_pilots);

        % SLM处理
        [tx_time_signal, tx_phase_indices, ~] = slm_papr_reduction(...
            tx_data_with_pilots, tx_N_FFT, tx_phase_perturbations);
        % disp(['max(abs)^2 = ', num2str(max(abs(tx_time_signal).^2))]);
        % disp(['mean(abs)^2 = ', num2str(mean(abs(tx_time_signal).^2))]);
    end
    % 计算 PAPR 值
    papr = 10*log10(max(abs(tx_time_signal).^2) ./ mean(abs(tx_time_signal).^2));

    % 调用改进后的ccdf函数
    [ccdf_vals, papr_vals] = calcu_ccdf(papr);

    % 绘图部分：根据是否重复切换绘图方式
    if (abs(sum(ccdf_vals - pre_ccdf)) <= 1e-9)
        fprintf('与上一次结果相同，绘制散点图\n');
        scatter(papr_vals, ccdf_vals, 10, colors(idx, :), 'filled'); % 画散点图
        legend_entries{idx} = sprintf('group\\_num = %d ', tx_phase_group_num);
    else
        semilogy(papr_vals, ccdf_vals, 'LineWidth', 2.5, 'Color', colors(idx, :)); % 画线图
        legend_entries{idx} = sprintf('group\\_num = %d', tx_phase_group_num);
    end
    pre_ccdf = ccdf_vals;  % 更新记录

end

hold off;
xlabel('PAPR (dB)');
ylabel('CCDF (Pr(PAPR > x))');
grid on;
legend(legend_entries);
title(sprintf('CCDF for Different Phase Group Numbers(%s)',tx_seq_type));
