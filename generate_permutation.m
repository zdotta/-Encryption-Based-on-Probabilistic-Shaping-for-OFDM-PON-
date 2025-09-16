function perm_indices = generate_permutation(chaos_seq, N)
    % 输入:
    %   chaos_seq: 混沌实数序列（列向量）
    %   N: 需要生成的排列长度（如矩阵行数或列数）
    % 输出:
    %   perm_indices: 随机排列索引（1~N）

    % 截取前N个混沌值并排序生成索引
    [~, perm_indices] = sort(chaos_seq(1:N));
end