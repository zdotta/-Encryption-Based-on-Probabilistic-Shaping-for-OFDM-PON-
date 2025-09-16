function time_signal = remove_cp(tx_signal, cp_length)
    time_signal = tx_signal(cp_length+1:end, :);
end