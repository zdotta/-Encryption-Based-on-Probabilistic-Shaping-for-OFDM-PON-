function decrypted = xor_decrypt(enc_bits, key)
    key = key(1:length(enc_bits));
    key = key(:);
    decrypted = xor(enc_bits, key);
end