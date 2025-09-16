function serial_signal = parallel_to_serial(parallel_data)
% 输入参数:
%   parallel_data: 并行时域信号矩阵（N_FFT × N_symbols）
% 输出参数:
%   serial_signal: 串联后的时域信号（列向量）

    % 按列展开为长向量
    serial_signal = parallel_data(:);
end