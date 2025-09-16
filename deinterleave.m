function deinterleaved_data = deinterleave(data, interleave_key)
    seed = sum(double(unicode2native(interleave_key, 'UTF-8')));
    rng(seed);
    interleave_seq = randperm(length(data));
    [~, deinterleave_seq] = sort(interleave_seq);
    deinterleaved_data = data(deinterleave_seq);
end