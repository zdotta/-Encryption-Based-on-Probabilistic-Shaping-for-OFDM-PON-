load('tx_raw_bits+logistic(group_num=2).mat')
load('rx_final_bits+logistic(group_num=2).mat')
%% 性能评估
min_len = min(length(tx_raw_bits), length(rx_final_bits));
errors = sum(tx_raw_bits(1:min_len) ~= rx_final_bits(1:min_len));
ber = errors / min_len;
fprintf('系统误码率(BER): %.4f\n', ber);
fprintf('错误比特数: %d / %d\n', errors, min_len);
