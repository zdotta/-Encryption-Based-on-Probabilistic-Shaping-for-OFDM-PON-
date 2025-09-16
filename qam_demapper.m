function demod_bits = qam_demapper(qam_symbols, mod_order)
% 输入:
%   qam_symbols: QAM符号矩阵 (num_subcarriers × num_symbols)
%   mod_order: 调制阶数
% 输出:
%   demod_bits: 解调比特矩阵 (原始结构，与映射函数输入一致)

    % 获取调制参数
    bits_per_subcarrier = log2(mod_order);
    
    % 验证输入尺寸
    [num_subcarriers, num_symbols] = size(qam_symbols);
    
    % 解调为比特流
    demod_bits = qamdemod(qam_symbols, mod_order, ...
                         'OutputType', 'bit', ...
                         'UnitAveragePower', true);
    
    % 重构原始比特矩阵结构
    % 注意：这与映射函数中的reshape和permute操作完全对称
    demod_bits = reshape(demod_bits, num_subcarriers, bits_per_subcarrier, num_symbols);
    demod_bits = permute(demod_bits, [2 1 3]);
    demod_bits = reshape(demod_bits, num_subcarriers * bits_per_subcarrier, num_symbols);
end