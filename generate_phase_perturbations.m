function phase_perturbations = generate_phase_perturbations(...
        seq_type, key, x0, phase_group_num, N_FFT, used_subcarriers)
    
    % 计算有效子载波位置
    start_idx = floor((N_FFT - used_subcarriers)/2) + 1;
    end_idx = start_idx + used_subcarriers - 1;
    
    % 初始化全尺寸扰动矩阵 (复数)
    phase_perturbations = ones(phase_group_num, N_FFT, 'like', 1i);
    
    % 生成有效子载波区域的扰动
    switch lower(seq_type)
        case 'hadamard'
            % Hadamard 序列提供离散相位变化
            used_subcarriers
            H = hadamard(used_subcarriers);
            complex_phases = exp(1i * pi * (H > 0)); % 转换为复数相位
            phase_perturbations(:, start_idx:end_idx) = complex_phases(1:phase_group_num, :);
            
        case 'random'
            % 完全随机相位 [0, 2π)
            random_phases = exp(1i * 2*pi*rand(phase_group_num, used_subcarriers));
            phase_perturbations(:, start_idx:end_idx) = random_phases;
            
        case 'logistic'
            % 基于混沌序列的连续相位
            required_length = phase_group_num * used_subcarriers;
            chaos_seq = GenerateChaosSeq(key, x0, required_length);
            % 映射到 [0, 2π)
            chaos_phases = 2*pi*chaos_seq;
            complex_phases = reshape(exp(1i*chaos_phases), used_subcarriers, phase_group_num).';
            phase_perturbations(:, start_idx:end_idx) = complex_phases;
            
        otherwise
            error('不支持的序列类型');
    end
end