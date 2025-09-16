function parallel_data = serial_to_parallel(interleaved_data, used_subcarriers, mod_order)
    % 参数说明：
    % data: 输入比特流（列向量）
    % used_subcarriers: 有效子载波数（如200）
    % mod_order: 调制阶数（如16）
    
    % 动态填充到bits_per_symbol的整数倍
    bits_per_symbol = used_subcarriers * log2(mod_order);
    current_length = length(interleaved_data);
    padding_needed = mod(current_length, bits_per_symbol);
    if padding_needed ~= 0
        padding = zeros(bits_per_symbol - padding_needed, 1);
        interleaved_data = [interleaved_data; padding];
    end
    assert(mod(length(interleaved_data), bits_per_symbol) == 0, '数据长度不匹配');
    
    % 串并转换
    parallel_data = reshape(interleaved_data, bits_per_symbol, []);
end