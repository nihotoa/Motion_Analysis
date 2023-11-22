%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]

[role of this code]
Performs all processing related to Seseki behavior analysis

[caution!!]
> this code is created for Nibali movie analaysis. So, this code may not be compatible with other analyses.
> The functions used in this code are stored in the following location
  path: Motion_analysis/code/Nibali_analysis_package

[saved basic_data location]

[procedure]
pre: nothing
post: coming soon...

改善点:
Sesekiと同じコードを使う際は,そのコードをcode -> common_packageというフォルダの中に移す
参照フォルダの中にあるもの全部を回すんじゃなくて，guiで選んだもののみを使う方がいいかもしれない.
拡張子がaviで固定されているので,変数で指定するように変更する
筋電と動画の称号について,   4タイミング全てを比較することで，同じタスクを捉えているかどうかを確認する
timing_frame_listについて, 手動で切り出したcamera3だけ精度が悪すぎる => 原因の究明
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param

monkey_name = 'Ni';
real_name = 'Nibali'; % monkey's full name
project_name = '3D_motion_analysis';
max_camera_num = 4; % number of cameras
timing_num = 4;

extract_timing_frame = 0; % chach the specific frame rate of  the trimmed video(resolution is integer)

make_table_EMG_to_movie = 0;
div_threshold = 8; % ズレの閾値(EMGと動画の対応づけに使う). divの計算がどのように行われているかはコードを見て
search_range = 5; % 動画とEMGのトライアル数が何個までずれていていいか(説明が難しい)

search_frame_rate = 1; % search for the frame rate of recoded movie
EMG_sampleRate = 1375;%[Hz]

create_real_time_videos = 0; % Create a new video by modifying the original video 
select_fold = 'manual'; %'auto'/'maunal'
changed_fps = 60;
movie_extension = '.avi';  % Extension of video to be analyzed

%% code section
% get data common to all functions
movie_fold_path = fullfile(pwd, [real_name '_movie']);
day_folders = getfileName(movie_fold_path, 'dir');
% Create a struct array containing the names of all video files
movie_files_name_struct = struct();
for ii = 1:length(day_folders)
    ref_dir = fullfile(movie_fold_path, day_folders{ii});
    movie_files_name = getfileName(ref_dir, '.avi');
    % Inseting the required information into 'movie_files_name_struct'
    file_count = zeros(1, max_camera_num);
    for jj = 1:length(movie_files_name)
        num_parts = extract_num_part(movie_files_name{jj});
        camera_id = str2double(num_parts{1});
        file_count(camera_id) = file_count(camera_id) + 1;
        eval(['movie_files_name_struct.' monkey_name day_folders{ii} '.camera' num2str(camera_id) '.trial' num2str(file_count(camera_id)) ' = movie_files_name{jj};'])
    end
end

%% this analysis requires EMG timing data & trimmed videos.
if extract_timing_frame
    save_data_common_path = fullfile(pwd, 'save_data', project_name, real_name, 'timing_frame_list');
    if not(exist(save_data_common_path))
        mkdir(save_data_common_path)
    end
    for ii = 1:length(day_folders)
        each_day_frame_struct = struct();
        ref_struct =eval(['movie_files_name_struct.' monkey_name day_folders{ii}]); %対象の日の各カメラの各トライアルに対応する動画ファイル名の構造体
        camera_name_list = fieldnames(ref_struct);
        used_cameras = zeros(length(camera_name_list),1);
        % checking the camera used
        for jj = 1:length(camera_name_list)
            num_parts = extract_num_part(camera_name_list{jj});
            used_cameras(jj) = str2double(num_parts{1});
        end
        % find relative fps(which is based on trial seetart timing) at each timing
        for jj = 1:length(used_cameras) 
            ref_camera_num = used_cameras(jj);
            each_camera_files_name = eval(['ref_struct.camera' num2str(ref_camera_num)]);
            output_array = extract_each_timing_frame(each_camera_files_name, timing_num, day_folders{ii}, real_name);

            % データのセーブ
            movie_name_list = each_camera_files_name;
            timing_frame_list = output_array;
            % タイミングをテーブルにする
            row_names = strcat('trial', cellstr(num2str((1:file_count(jj))')));
            col_names = strcat('timing', cellstr(num2str((1:timing_num)')));
            % テーブルの作成
            timing_frame_list =  array2table(timing_frame_list, 'RowNames', row_names, 'VariableNames', col_names);
            % セーブ
            save(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list_camera' num2str(jj) '.mat']), 'timing_frame_list', 'movie_name_list')
        end
    end
end

%% 筋電と,その筋電に対応する各カメラからの動画の対応表(テーブル)を作成する
if make_table_EMG_to_movie
    % load EMG_success_timing
    load(fullfile('save_data', '3D_motion_analysis',real_name, 'EMG_success_timing', 'success_timing_struct.mat'), 'success_timing_struct');
    each_days_movie_frameRate_list = cell(length(day_folders),1); 
    all_frame_list_struct = struct(); %後で.matに保存するためのstructの作成
    for ii = 1:length(day_folders)
        % extract reference days EMG_success_timing
        success_timing = eval(['success_timing_struct.' monkey_name day_folders{ii}]);
        % load timing_frame_list
        save_data_common_path = fullfile(pwd, 'save_data', project_name, real_name, 'timing_frame_list');
        % セーブする表の外枠を作る(日毎に作成する)
        [~, EMG_trial_num] = size(success_timing);
        EMG_movie_correspond_table = nan(EMG_trial_num, camera_id);
        all_movie_file_name_list = struct();
        for jj = 1:camera_id %カメラごとに，フレームレートを求める
            load(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list_camera' num2str(jj) '.mat']), 'timing_frame_list', 'movie_name_list')
            eval(['all_movie_file_name_list.camera' num2str(jj) ' = movie_name_list;'])
            [movie_trial_num,~] =size(timing_frame_list);
            movie_frameRate_list = zeros(movie_trial_num,1);

            %各トライアルが,筋電のどのトライアルに対応しているのかを調べていく
            movie_count = 1; % 何個の動画ファイルが一致したか(この値がmovie_trial_numを上回った瞬間にbreakする)
            pre_adequate_movie_idx = 0;
            % ここから大事(表に対応づけのデータを代入していく)
            while true
                not_correspond_flag = true; %その動画に一致するEMGがあったかどうか(無いならtrue)
                empty_row = find(isnan(EMG_movie_correspond_table(:, jj)));
                for kk = 1:search_range % EMGのトライアルをiterationしていく
                    % EMGのトライアルempty_row(kk)と,camera jjのトライアルmovie_count のズレを評価していく
                    evaluation_div_value = calc_frame_div(success_timing, timing_frame_list, empty_row(kk), movie_count);
                    % ズレが閾値以内であった場合
                    if evaluation_div_value <= div_threshold
                        EMG_movie_correspond_table(empty_row(kk), jj) = movie_count;
                        % pre_adequateと現在のmovie_countの間にNaN値がある場合は10000で埋める
                        if pre_adequate_movie_idx > 0
                            start_idx = find(EMG_movie_correspond_table(:,1)==pre_adequate_movie_idx);
                            end_idx = find(EMG_movie_correspond_table(:,1)==movie_count);
                            ref_row = EMG_movie_correspond_table(:, jj);
                            sliced_array = ref_row(start_idx:end_idx);
                            relative_idx_list = find(isnan(sliced_array));
                            if ~isempty(relative_idx_list)
                                absolute_idx_list = relative_idx_list + start_idx-1;
                                EMG_movie_correspond_table(absolute_idx_list, jj) = 10000;
                            end
                        end
                        pre_adequate_movie_idx = movie_count;
                        movie_count = movie_count + 1;
                        not_correspond_flag = false;
                        break;
                    end
                end
                if not_correspond_flag
                    movie_count = movie_count + 1;
                end
                % 全ての動画と対応づけができたらループを抜ける
                if movie_count > movie_trial_num 
                    break
                end
            end
            % ここまで大事
        end
        % tableを作成する
        row_names = strcat('EMG trial', cellstr(num2str((1:EMG_trial_num)')));
        col_names = strcat('camera', cellstr(num2str((1:camera_id)')), '_trial ?');
        % テーブルの作成
        EMG_movie_correspond_table =  array2table(EMG_movie_correspond_table, 'RowNames', row_names, 'VariableNames', col_names);
        % セーブ(セーブパスと,セーブする変数の指定)
        path_parts = strsplit(save_data_common_path, '/');
        use_parts = path_parts(1:end-1);
        save_data_fold_path = fullfile(strjoin(use_parts, '/'), 'EMG_Movie_Correspond');
        if not(exist(save_data_fold_path))
            mkdir(save_data_fold_path)
        end
        save(fullfile(save_data_fold_path, [day_folders{ii} '_EMG_Movie_Correspond.mat']), 'EMG_movie_correspond_table', 'all_movie_file_name_list');
    end
end

%% Please do 'extract_timing_frame' firstly 
%{
改善点:
 ・修正途中で投げ出したので,途中でエラー吐くはず
・jjのループが1:camera_idになっている
=> .matファイルを他の関数でexportして，そのファイルをimportすることで使う
%}
if search_frame_rate
    % load EMG_success_timing
    load(fullfile('save_data', '3D_motion_analysis',real_name, 'EMG_success_timing', 'success_timing_struct.mat'), 'success_timing_struct');
    each_days_movie_frameRate_list = cell(length(day_folders),1); 
    all_frame_list_struct = struct();
    for ii = 1:length(day_folders)
        % extract reference days EMG_success_timing
        success_timing = eval(['success_timing_struct.' monkey_name day_folders{ii}]);
        % load timing_frame_list
        save_data_common_path = fullfile(pwd, 'save_data', project_name, real_name, 'timing_frame_list');
        % load(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list.mat']), 'timing_frame_list', 'movie_name_list')
        % 筋電と動画の対応づけが合っていると仮定して話しを進める
        for jj = 1:camera_id %カメラごとに，フレームレートを求める(念の為)
            load(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list_camera' num2str(jj) '.mat']), 'timing_frame_list', 'movie_name_list')
            [trial_num,~] =size(timing_frame_list);
            movie_frameRate_list = zeros(trial_num,1);
            % 筋電との対応から，各トライアルにおけるフレームレートを算出する
            for kk = 1:trial_num
                EMG_all_sample = success_timing(5,kk) - 1;
                movie_all_frame = timing_frame_list.(['camera' num2str(jj)])(kk,4)-1;
                movie_frameRate_list(kk) = (movie_all_frame/EMG_all_sample) * EMG_sampleRate;
            end
            % 最初の5つをpickupして平均値と分散を出す
            pick_up_SR = movie_frameRate_list(1:5);
            mean_value = mean(pick_up_SR);
            std_value = std(pick_up_SR);
            frame_rate_table = table;
            frame_rate_table.mean = mean_value;
            frame_rate_table.std = std_value;
            eval(['all_frame_list_struct.' monkey_name day_folders{ii} '.camera' num2str(jj) ' = frame_rate_table;']) 
            % each_days_movie_frameRate_list{ii} = [num2str(mean_value) '+-' num2str(std_value)];
        end
    end
end

%% originalのvideoを読み込んで,指定したフレームレートの等倍速の動画を作成する
if create_real_time_videos
    % 解析対象の動画を手動で選ぶか，自動で選ぶか
    switch select_fold
        case 'auto'
            ref_folders = day_folders;
        case 'manual'
            % 複数選択できなことに注意
            disp(['解析したい動画の入っているフォルダを選択してください'])
            ref_folders{1} = uigetdir();
    end
    %対象の動画のpathを指定
    for ii = 1:length(ref_folders)
        % 対象のフォルダのpathを取得
        switch select_fold
            case 'auto'
                movie_day_fold_path = fullfile(movie_fold_path, ref_folders{ii});
            case 'manual'
                movie_day_fold_path = ref_folders{1};
        end
        % 対象フォルダ内の動画ファイル名の取得
        movie_list = getfileName(movie_day_fold_path, movie_extension);
        movie_num = length(movie_list);
        for jj = 1:movie_num %movieごとに処理
            ref_movie_path = fullfile(movie_day_fold_path, movie_list{jj});
            % 現在の動画の記録された際のフレームレートを取得する(search_frame_rateの結果を使用する)
            now_frame_rate = 240; 
            % real_timeの動画を作る
            create_real_time_video(changed_fps, ref_movie_path, now_frame_rate, movie_extension)
        end
    end
end