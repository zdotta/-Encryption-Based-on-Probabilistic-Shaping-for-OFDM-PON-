function [channel_est] = histogram_channel(received_signal, pilot_symbols, pilot_indices)
    % received_signal: 接收的频域信号 (N_subcarriers × N_symbols)
    % pilot_symbols: 发送的导频符号 (N_pilots × N_symbols)
    % pilot_indices: 导频位置索引 (logical vector)
    
    [num_sub, num_sym] = size(received_signal);
    channel_est = zeros(num_sub, num_sym);
    
    % 获取导频位置
    pilot_positions = find(pilot_indices);
    
    % 验证导频数量
    num_pilots = length(pilot_positions);
    if size(pilot_symbols, 1) ~= num_pilots
        error('导频符号数量(%d)与导频位置数量(%d)不匹配', ...
              size(pilot_symbols, 1), num_pilots);
    end
    
    % 提取接收信号中的导频
    received_pilots = received_signal(pilot_indices, :);
    
    % 信道估计 (最小二乘估计)
    for sym_idx = 1:num_sym
        % 当前符号的导频值
        tx_pilots = pilot_symbols(:, sym_idx);
        rx_pilots = received_pilots(:, sym_idx);
        
        % 计算导频位置的信道响应
        H_pilot = rx_pilots ./ tx_pilots;
        
        % 插值获取全信道响应 (线性插值)
        all_pos = (1:num_sub)';
        channel_est(:, sym_idx) = interp1(pilot_positions, H_pilot, all_pos, 'linear', 'extrap');
    end
    
    % 可选：添加平滑处理
    % channel_est = smooth_channel_estimate(channel_est, pilot_positions);
end