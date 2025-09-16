%% 异或加密模块
function enc_bits = xor_encrypt(data, key)
        % 确保key是列向量且长度匹配
    key = key(:); 
    assert(length(key) == length(data), '密钥流与数据长度不匹配');
    enc_bits = xor(data, key);

end