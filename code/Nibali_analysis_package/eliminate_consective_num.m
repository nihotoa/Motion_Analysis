function [output_array] = eliminate_consective_num(num_array)
output_array = [];
start_idx = 1; %連続する中で一番小さい値のindex
% 入力の長さが1だったとき
if length(num_array) == 1
    output_array = num_array;
else
    for ii = 2:length(num_array) %consective
        if ii==length(num_array) % 最後のループの場合は値をoutput_arrayに代入する
            output_array = [output_array, num_array(ii)];
        else
            if num_array(ii) - num_array(ii-1) == 1
                continue
            else % not consective (もし連続じゃないのなら)
                subset = num_array(start_idx:ii-1); % 連続する値のサブセットを作成
                max_val = max(subset); %一番値が大きいもののみをpickupする 
                output_array = [output_array, max_val]; %outputにappendする
                start_idx = ii; %start_idxを更新
            end
       end
    end
end
end

