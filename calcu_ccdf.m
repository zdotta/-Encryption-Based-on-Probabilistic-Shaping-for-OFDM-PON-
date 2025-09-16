function [ccdf_vals_interp, papr_vals_interp] = calcu_ccdf(papr_dB)
% 计算 PAPR 的 CCDF，并对其进行平滑插值
% papr_dB: 以 dB 为单位的一维向量

    % 输入检查
    if isempty(papr_dB)
        error('输入的 PAPR 数据为空，无法计算 CCDF。');
    end

    papr_dB = papr_dB(:); % 转为列向量
    total = length(papr_dB);

    % 创建原始PAPR值区间
    min_val = floor(min(papr_dB));
    max_val = ceil(max(papr_dB));

    if max_val == min_val
        warning('PAPR 值范围太小，无法计算 CCDF 曲线，仅返回单值。');
        papr_vals = min_val;
        ccdf_vals = 1;
    else
        papr_vals = linspace(min_val, max_val, 100);
        ccdf_vals = arrayfun(@(x) sum(papr_dB > x) / total, papr_vals);
    end

    % 只在点数大于2时插值
    if length(papr_vals) > 2
        papr_vals_interp = linspace(min_val, max_val, 300); % 插值点
        ccdf_vals_interp = pchip(papr_vals, ccdf_vals, papr_vals_interp); % 插值
    else
        % 不足以插值，直接返回原始点
        papr_vals_interp = papr_vals;
        ccdf_vals_interp = ccdf_vals;
    end

    % 防止 NaN
    ccdf_vals_interp(isnan(ccdf_vals_interp)) = 0;
end
