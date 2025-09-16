function plot_ccdf_papr(signal, title_str)
    % 计算功率
    power = abs(signal).^2;
    % PAPR计算
    papr = 10*log10(max(power)./mean(power));
    % CCDF
    [ccdf_vals, papr_vals] = calcu_ccdf(papr);
    semilogy(papr_vals, ccdf_vals);
    grid on; xlabel('PAPR (dB)'); ylabel('CCDF');
    title(['CCDF曲线: ', title_str]);
end
