function interleaved_data = interleave(data, interleave_key)
    % 参数说明：
    % data: 输入数据（列向量）
    % interleave_key: 字符串密钥，用于生成交织索引
    
    % 将密钥转换为随机种子
    seed = sum(double(unicode2native(interleave_key, 'UTF-8')));
    rng(seed); % 固定随机数生成器
    
    % 生成随机置换序列
    interleave_seq = randperm(length(data));
    interleaved_data = data(interleave_seq);
end