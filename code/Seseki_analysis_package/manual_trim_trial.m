%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
関節角度の時系列データを, 手動で作った,各タイミングのフレームの入ったcsvファイルを参考にタスクごとに切り分ける
入力引数:
target_joint: cell配列, calc_joint_angle.mの出力
joint_angle_data: 構造体配列(struct), calc_joint_angle.mの出力
manual_trim_data: double配列, Seseki_manual_trim_filesのxlsxファイルの中身をreadmatrixによって取得したもの
manual_trim_window: double配列, 各タイミングを0として, 何%から何%まで表示するか

[課題点]
構造体の構造を考える
(ex.) 
joint_angle_data_list.trial.タイミング名, 関節名
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function joint_angle_data_list = manual_trim_trial(target_joint, joint_angle_data, manual_trim_data, manual_trim_window)
    % manual_trim_dataを2つに分ける
    timing_list = manual_trim_data(:, 1:end-1);
    trial_sample_num_list = manual_trim_data(:, end);

    % 使用する変数の取得
    [trial_num, timing_num] = size(timing_list);
    target_joint_num = length(target_joint);

    % 構造体の作成
    joint_angle_data_list = struct();

    % trialごとに構造体に値を代入していく
    for ii = 1:target_joint_num
        ref_joint = target_joint{ii};
        ref_data = joint_angle_data.(ref_joint);
        for jj = 1:trial_num
            % trial jj の各タイミングの情報
            ref_timing = timing_list(jj, :);

            % trial jj の100%のサンプル数
            task_duration_sample = trial_sample_num_list(jj);

            % windowサイズにしたがって,±方向に何サンプル分トリミングするか保持する(符号を考慮していることに注意!!)
            first_relative_idx = fix(task_duration_sample * (manual_trim_window(1) / 100));
            last_relative_idx = fix(task_duration_sample * (manual_trim_window(2) / 100));
            for kk = 1:timing_num
                % そのタイミングの与えられた区間の配列を返す.
                ref_timing_idx = ref_timing(kk);
                trimmed_data = ref_data(ref_timing_idx+first_relative_idx-1 : ref_timing_idx+last_relative_idx);
                % 構造体に値を入れる
                joint_angle_data_list.(['trial' num2str(jj)]).(['tim' num2str(kk)]).(ref_joint) = trimmed_data;
            end
        end
    end

end

