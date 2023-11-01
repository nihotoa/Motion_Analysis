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
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Ni';
real_name = 'Nibali'; % monkey's full name
project_name = '3D_motion_analysis';
max_camera_num = 4; % number of cameras
timing_num = 4;
extract_timing_frame = 1; % chach the specific frame rate of  the trimmed video(resolution is integer)
search_frame_rate = 1; % search for the frame rate of recoded movie
EMG_sampleRate = 1375;%[Hz]
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

% this analysis requires EMG timing data & trimmed videos.
if extract_timing_frame
    save_data_common_path = fullfile(pwd, 'save_data', project_name, real_name, 'timing_frame_list');
    if not(exist(save_data_common_path))
        mkdir(save_data_common_path)
    end
    for ii = 1:length(day_folders)
        each_day_frame_struct = struct();
        ref_struct =eval(['movie_files_name_struct.' monkey_name day_folders{ii}]);
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
            eval(['each_day_frame_struct.camera' num2str(ref_camera_num) ' = output_array;'])
        end
        movie_name_list = ref_struct;
        timing_frame_list = each_day_frame_struct;
        % save(各日毎に) => セーブをしっかり作る
        save(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list.mat']), 'timing_frame_list', 'movie_name_list')
    end
end

%% Please do 'extract_timing_frame' firstly 
%{
改善点:
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
        load(fullfile(save_data_common_path, [day_folders{ii} '_timing_frame_list.mat']), 'timing_frame_list', 'movie_name_list')
        % 筋電と動画の対応づけが合っていると仮定して話しを進める
        for jj = 1:camera_id %カメラごとに，フレームレートを求める(念の為)
            [trial_num,~] = size(timing_frame_list.(['camera' num2str(jj)]));
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