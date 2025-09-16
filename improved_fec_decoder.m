function decoded_bits = improved_fec_decoder(encoded_bits, n, k, padding_info)
    % 1. 移除FEC输出填充
    if padding_info.fec_padding > 0
        encoded_bits = encoded_bits(1:end - padding_info.fec_padding);
    end
    
    % 2. 计算RS参数
    m = padding_info.m; % 从编码器获取m值
    bits_per_block = n * m;
    num_blocks = floor(length(encoded_bits) / bits_per_block);
    
    % 3. 确保长度匹配
    if num_blocks * bits_per_block < length(encoded_bits)
        encoded_bits = encoded_bits(1:num_blocks * bits_per_block);
    end
    
    decoded_blocks = cell(num_blocks, 1);
    
    for i = 1:num_blocks
        % 提取当前块比特
        start_idx = (i-1)*bits_per_block + 1;
        end_idx = i*bits_per_block;
        block_bits = encoded_bits(start_idx:end_idx);
        
        % 转换为RS符号
        code_symbols = bi2de(reshape(block_bits, m, [])', 'left-msb')';
        
        % ==== 关键修改：创建伽罗华域对象 ====
        code_gf = gf(code_symbols, m); % 创建伽罗华域数组
        
        % RS解码 (带纠错)
        try
            [decoded_msg, ~] = rsdec(code_gf, n, k);
        catch
            % 解码失败时使用零填充
            decoded_msg = gf(zeros(1, k), m);
        end
        
        % 转换回比特流
        % 转换为双精度数值数组
        decoded_symbols = double(decoded_msg.x);
        decoded_blocks{i} = reshape(de2bi(decoded_symbols, m, 'left-msb')', [], 1);
    end
    
    decoded_bits = vertcat(decoded_blocks{:});
    
    % 4. 移除FEC输入填充（符号级填充）
    if padding_info.info_padding > 0
        decoded_bits = decoded_bits(1:end - padding_info.info_padding);
    end
    
    % 5. 恢复原始长度（直接使用原始比特长度）
    decoded_bits = decoded_bits(1:padding_info.original_length);
end