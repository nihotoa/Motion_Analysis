%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
EMGとvideoが一致しているかどうかを確認する際の1部分を担っている
【引数】
success_timing: NibaliのEMG解析で作ったやつ(save_data -> 3D_motion_analysis -> Nibali -> EMG_success_timingの中)
timing_frame_list: type => table, extract_timing_frameの出力結果(save_data -> 3D_motion_analysis -> Nibali -> timing_frame_listの中)
EMG_trial_idx: 参照するトライアル(EMGにおける)
movie_trial_idx: 参照するトライアル(movieにおける)
※基本的に2つのidxは同じはずだが, movieのフレーム落ちとかでズレが生じている可能性がある + movieの方が早めに録画を終えているのでtrial数が少ない
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [evaluation_div_value] = calc_frame_div(success_timing, timing_frame_list, EMG_trial_idx, movie_trial_idx)
% EMGの経過サンプル数と, 動画の経過フレーム数を比較して割合を出す
EMG_one_task_frame = success_timing(5, EMG_trial_idx)-1;
movie_one_task_frame = timing_frame_list{movie_trial_idx,4}-1;
ref_ratio = EMG_one_task_frame / movie_one_task_frame;
% EMGをmovieの基準に合わせて, tim2とtim3を比較
EMG_compired_tim2 = (success_timing(2,  EMG_trial_idx) - success_timing(1,EMG_trial_idx)) / ref_ratio;
EMG_compired_tim3 = (success_timing(3,  EMG_trial_idx) - success_timing(1,EMG_trial_idx)) / ref_ratio;
tim2_div = abs(EMG_compired_tim2 - (timing_frame_list{movie_trial_idx, 2}-1));
tim3_div = abs(EMG_compired_tim3 - (timing_frame_list{movie_trial_idx, 3}-1));

% ズレを計算する
evaluation_div_value = power(tim2_div, 2) + power(tim3_div, 2);
end

