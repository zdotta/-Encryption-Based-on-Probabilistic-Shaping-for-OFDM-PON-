function [encoded_bits, padding_info] = improved_fec_encoder(input_bits, n, k, bits_per_symbol)
    % 参数验证
    if n <= k || n > 255
        error('无效的RS编码参数(n,k)');
    end
    
    % 1. 计算FEC输入填充 (确保长度是k*m的倍数)
    m = ceil(log2(n+1)); % RS符号比特数
    num_bits = length(input_bits);
    bits_per_block = k * m;
    info_padding = mod(-num_bits, bits_per_block);
    
    % 填充输入数据
    padded_input = [input_bits; zeros(info_padding, 1)];
    
    % 2. RS编码
    num_blocks = length(padded_input) / bits_per_block;
    encoded_blocks = cell(num_blocks, 1);
    
    for i = 1:num_blocks
        % 提取当前块比特
        start_idx = (i-1)*bits_per_block + 1;
        end_idx = i*bits_per_block;
        block_bits = padded_input(start_idx:end_idx);
        
        % 转换为RS符号 (m比特/符号)
        msg_decimal = bi2de(reshape(block_bits, m, [])', 'left-msb')';
        
        % ==== 关键修正：创建伽罗华域对象 ====
        % 计算伽罗华域阶数
        gf_order = 2^m;
        
        % 创建伽罗华域消息
        msg_gf = gf(msg_decimal, m); % 这里创建了伽罗华域数组
        
        % RS编码
        code = rsenc(msg_gf, n, k); % 现在msg_gf是伽罗华域数组
        
        % 转换回比特流
        % 转换为双精度数值数组
        code_numeric = double(code.x);
        encoded_blocks{i} = reshape(de2bi(code_numeric, m, 'left-msb')', [], 1);
    end
    
    encoded_bits = vertcat(encoded_blocks{:});
    
    % 3. 计算FEC输出填充 (确保长度是OFDM符号比特数的整数倍)
    fec_padding = mod(-length(encoded_bits), bits_per_symbol);
    if fec_padding > 0
        encoded_bits = [encoded_bits; zeros(fec_padding, 1)];
    end
    
    % 4. 保存填充信息
    padding_info.info_padding = info_padding;
    padding_info.fec_padding = fec_padding;
    padding_info.original_length = num_bits;
    padding_info.m = m; % 保存RS符号比特数
end