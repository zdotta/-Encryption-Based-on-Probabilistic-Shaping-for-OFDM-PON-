function descrambled = descramble_with_logistic(...
    scrambled_data, row_perm1, col_perm, row_perm2)
% 输入：
%   scrambled_data: 包含导频的完整子载波数据 (N_subcarriers × N_symbols)
%   row_perm1, col_perm, row_perm2: 置乱序列
% 输出：
%   descrambled: 解置乱后的完整子载波数据





% 逆操作1：第二次行置换的逆
[~, inv_row_perm2] = sort(row_perm2);
temp_data = scrambled_data(inv_row_perm2, :);

% 逆操作2：列置换的逆
[~, inv_col_perm] = sort(col_perm);
temp_data = temp_data(:, inv_col_perm);

% 逆操作3：第一次行置换的逆
[~, inv_row_perm1] = sort(row_perm1);
descrambled = temp_data(inv_row_perm1, :);


end