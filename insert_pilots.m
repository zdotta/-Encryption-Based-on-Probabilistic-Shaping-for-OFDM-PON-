function [pilot_symbols, pilot_indices, data_with_pilots,total_subcarriers] = insert_pilots(data_matrix, mod_order, pilot_interval, pilot_type)
% 输入参数:
%   data_matrix: 原始数据矩阵（num_data_subcarriers × num_symbols）
%   mod_order: 调制阶数
%   pilot_interval: 导频插入间隔
%   pilot_type: 导频类型
% 输出参数:
%   pilot_symbols: 导频符号矩阵
%   pilot_indices: 导频位置索引
%   data_with_pilots: 插入导频后的矩阵

% 参数校验
if nargin < 4
    pilot_type = 'BPSK';
end
[num_data_sub, num_symbols] = size(data_matrix);

% 计算导频数量
num_blocks = ceil(num_data_sub / pilot_interval);
num_pilots = num_blocks;
total_subcarriers = num_data_sub + num_pilots;

% 初始化导频索引
pilot_indices = false(total_subcarriers, 1);

% 生成导频符号
switch upper(pilot_type)
    case 'BPSK'
        pilot_vals = (randi([0, 1], num_pilots, num_symbols)) * 2 - 1;
    case 'QPSK'
        qpsk_sym = randi([0, 3], num_pilots, num_symbols);
        pilot_vals = qammod(qpsk_sym, 4, 'UnitAveragePower', true);
    otherwise
        error('不支持的导频类型');
end

% 创建输出矩阵
data_with_pilots = zeros(total_subcarriers, num_symbols);

% 插入导频和数据
data_idx = 1;
pilot_idx = 1;
output_idx = 1;

for block = 1:num_blocks
    % 插入导频
    data_with_pilots(output_idx, :) = pilot_vals(pilot_idx, :);
    pilot_indices(output_idx) = true;
    output_idx = output_idx + 1;
    pilot_idx = pilot_idx + 1;
    
    % 插入数据（10个子载波）
    block_end = min(data_idx + pilot_interval - 1, num_data_sub);
    block_data = data_matrix(data_idx:block_end, :);
    block_length = size(block_data, 1);
    
    data_with_pilots(output_idx:output_idx+block_length-1, :) = block_data;
    output_idx = output_idx + block_length;
    data_idx = data_idx + block_length;
end

pilot_symbols = pilot_vals;
end