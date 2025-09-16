function demodulated = slm_demod(perturbed_freq, phase_perturbations, phase_indices, ...
    start_idx, end_idx,pilot_indices)
    [num_subcarriers, num_symbols] = size(perturbed_freq);
    demodulated = perturbed_freq;
    
    % 提取有效子载波对应的相位扰动
    valid_phase_perturbations = phase_perturbations(:, start_idx:end_idx);
% valid_phase_perturbations = valid_phase_perturbations(:,~pilot_indices);
    for sym_idx = 1:num_symbols
        phase_idx = phase_indices(sym_idx);
        % 应用逆相位扰动（复数共轭）
        demodulated(:, sym_idx) = demodulated(:, sym_idx) .* ...
            conj(valid_phase_perturbations(phase_idx, :)).';
    end
end