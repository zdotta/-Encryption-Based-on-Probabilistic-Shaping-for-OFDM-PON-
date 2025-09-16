function [chaos_real_seq,binary_key] = GenerateChaosSeq(key_str, x0, data_length, transient_len)
    % 输入:
    %   key_str     - 密钥字符串（如'MySecretKey'）
    %   x0          - 初始值（0 < x0 < 1）
    %   data_length - 数据流长度（8000 bits）
    %   transient_len - 暂态长度（默认500）
    % 输出:
    %   binary_key  - 8000 bits二进制密钥流（列向量）
    
    % 参数校验
    assert(x0 > 0 && x0 < 1, '初始条件x0必须在(0,1)区间内');
    if nargin < 4
        transient_len = 500;
    end
    
    % === 使用更强的哈希函数生成μ ===
    md = java.security.MessageDigest.getInstance('MD5');
    hash = md.digest(uint8(key_str));
    hash = typecast(hash, 'uint8'); % 转换为 uint8 数组

    % 提取前几个字节组合成浮点数
    mu_seed = double(sum(hash(1:8))) / 2048; % 范围大约在 [0,1]
    mu = 3.9 + 0.1 * mu_seed;  % μ ∈ [3.9, 4.0)
    
    % 生成混沌序列（总长度=数据长度+暂态）
    total_iter = data_length + transient_len;
    chaos_seq = zeros(1, total_iter);
    chaos_seq(1) = x0;
    for n = 1:total_iter-1
        chaos_seq(n+1) = mu * chaos_seq(n) * (1 - chaos_seq(n));
    end
    
    % 去除暂态
    chaos_real_seq = chaos_seq(transient_len+1:end); % 保留实数序列
    chaos_real_seq = chaos_real_seq(1:data_length);
    
    % 二值化处理
    binary_key = chaos_real_seq > 0.5;
    binary_key = binary_key(:);

    binary_key = binary_key(1:data_length); % 严格匹配长度
    assert(length(binary_key) == data_length, '密钥流长度错误');
    binary_key = binary_key(:); % 转为列向量

end