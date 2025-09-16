function qam_symbols = qam_mapper(parallel_data, mod_order)
    % 参数说明：
    % parallel_data: 并行比特矩阵（每列为一个OFDM符号）
    % mod_order: 调制阶数（如16）
    
    bits_per_subcarrier = log2(mod_order);
    num_subcarriers = size(parallel_data, 1) / bits_per_subcarrier;
    % 按子载波分组并映射
    reshaped_data = reshape(parallel_data, bits_per_subcarrier, num_subcarriers, []);
    reshaped_data = permute(reshaped_data, [2 1 3]);
    qam_symbols = qammod(reshaped_data, mod_order, 'InputType', 'bit', 'UnitAveragePower', true);
    qam_symbols = reshape(qam_symbols, num_subcarriers, []);
end