function scrambled_data = scramble_with_logistic(qam_symbols, key, x0, seq_length_min, used_subcarriers, num_symbols_actual)
    % 行置乱1
    chaos_row1 = GenerateChaosSeq([key '_row1'], x0, used_subcarriers);
    row_perm1 = generate_permutation(chaos_row1, used_subcarriers);
    
    % 列置乱
    chaos_col = GenerateChaosSeq([key '_col'], x0, num_symbols_actual);
    col_perm = generate_permutation(chaos_col, num_symbols_actual);
    
    % 行置乱2
    chaos_row2 = GenerateChaosSeq([key '_row2'], x0, used_subcarriers);
    row_perm2 = generate_permutation(chaos_row2, used_subcarriers);
    
    % 应用置乱
    scrambled_data = qam_symbols(row_perm1, :);
    scrambled_data = scrambled_data(:, col_perm);
    scrambled_data = scrambled_data(row_perm2, :);
end