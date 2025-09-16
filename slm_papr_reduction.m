function [best_time_signal, best_phase_indices, min_papr] = slm_papr_reduction(freq_data, N_FFT, phase_perturbations)
    [N_subcarriers, N_symbols] = size(freq_data);
    
    % 确定有效子载波位置
    start_idx = floor((N_FFT - N_subcarriers)/2) + 1;
    end_idx = start_idx + N_subcarriers - 1;
    
    % 创建完整频域矩阵
    full_spectrum = zeros(N_FFT, N_symbols, 'like', 1i);
    full_spectrum(start_idx:end_idx, :) = freq_data;
    
    [num_phases, ~] = size(phase_perturbations);
    best_phase_indices = zeros(1, N_symbols);
    best_time_signal = zeros(N_FFT, N_symbols, 'like', 1i);
    min_papr = Inf;
    
    for sym_idx = 1:N_symbols
        current_papr = Inf;
        
        for phase_idx = 1:num_phases
            % 应用复数相位扰动
            perturbed_freq = full_spectrum(:, sym_idx) .* phase_perturbations(phase_idx, :).';
            
            % IFFT转换
            time_signal = ifft(perturbed_freq, N_FFT);
            
            % 计算PAPR
            papr = calculate_papr(time_signal);
            
            % 更新最优候选
            if papr < current_papr
                current_papr = papr;
                best_time_signal(:, sym_idx) = time_signal;
                best_phase_indices(sym_idx) = phase_idx;
                min_papr = min(min_papr, current_papr);
            end
        end
    end
end
% PAPR计算辅助函数
function papr_db = calculate_papr(signal)
    power = abs(signal).^2;
    peak_power = max(power);
    avg_power = mean(power);
    papr_db = 10 * log10(peak_power / avg_power);
end