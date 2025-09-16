function parallel_signal = serial_to_parallel_t(serial_signal, symbol_length)
    num_samples = length(serial_signal);
    num_symbols = floor(num_samples / symbol_length);
    truncated_length = num_symbols * symbol_length;
    parallel_signal = reshape(serial_signal(1:truncated_length), ...
                             symbol_length, num_symbols);
end