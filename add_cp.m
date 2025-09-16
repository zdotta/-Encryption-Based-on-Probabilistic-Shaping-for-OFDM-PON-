function tx_matrix = add_cp(time_signal, cp_length)
% 输入参数:
%   time_signal: 时域信号矩阵（N_FFT × N_symbols）
%   cp_length: 循环前缀长度（整数）
% 输出参数:
%   tx_matrix: 带CP的时域信号矩阵（(N_FFT + cp_length) × N_symbols）

    % 提取每个符号的CP（末尾cp_length个采样点）
    cp = time_signal(end - cp_length + 1 : end, :);
    
    % 将CP添加到每个符号的开头
    tx_matrix = [cp; time_signal];
end