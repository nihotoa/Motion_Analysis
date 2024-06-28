%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
連続した数値の中から一つだけをピックアップして,　非連続な値のarrayを返す
num_array => double型の配列
adopt_type => 連続した時にどれを採用するか 'back' => 後ろを採用する/ 'front' => 前を採用する
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [output_array] = eliminate_consective_num(num_array, adopt_type)
output_array = [];
start_idx = 1; %連続する中で一番小さい値のindex
% 入力の長さが1だったとき
if length(num_array) == 1
    output_array = num_array;
else
    for ii = 2:length(num_array) %候補を調べていく
        if ii==length(num_array)
            switch adopt_type
                case 'back'
                    output_array = [output_array, num_array(ii)];  % 最後のループの場合は値をoutput_arrayに代入する(絶対に採用されるので)
                case 'front'
                    subset = num_array(start_idx:ii); %最後の値を含むsubsetを作る
                    output_array = [output_array, min(subset)];
                    break; %ループを抜ける
            end
        end
        if num_array(ii) - num_array(ii-1) == 1 %一個前と連続であれば
            continue
        else % 1個前と連続でないのなら
            subset = num_array(start_idx:ii-1); % 連続する値のサブセットを作成
            switch adopt_type
                case 'back'
                    ref_val = max(subset); %一番値が大きいもののみをpickupする 
                case 'front'
                    ref_val = min(subset); %一番値が大きいもののみをpickupする 
            end
            output_array = [output_array, ref_val]; %outputにappendする
            start_idx = ii; %start_idxを更新
        end
    end
end
end

