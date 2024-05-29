%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]

[role of this code]
Performs all processing related to Seseki behavior analysis
(this code perform various analysis with focusing on each timing of Seseki)

[caution!!]
> this code is created for Seseki movie analaysis. So, this code may not be compatible with other analyses.
> The functions used in this code are stored in the following location
  path: Motion_analysis/code/Seseki_analysis_package

[saved basic_data location]

[procedure]
pre: nothing
post: coming soon...

注意点：
Seseki_MotionAnalysisとの違いは、各タイミング(lever1 on, leve1 off)付近のmotionを結果としてプロットしているところ。(EMG解析と同じ時系列で区切って解析)
ただし、各トライアルにおいける各タイミングの判断は目視で行なってmanualでexcelファイルに書き込んだフレーム数を使っているので、厳密性はかなり低い

改善点:
each_plotの中で，save_foldのpathに必要な変数を定義しているので，こっちの大元の関数で変数定義する様に変更する
each_plotを書き換えたため,allplotでloadするデータの構造が変わっている -> それに応じたコードを書く
each_plotにminimumにalignするかmaximumにalignするかのoptionを追加する(現状はminimumにalignされている)
pick_up_imageもminimumなのかmaximumなのかはっきりさせる
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Se'; 
real_name = 'Seseki';
save_data_location = 'save_data';
save_figure_loacation = 'save_figure';

conduct_joint_angle_analysis = 1;
manual_trim_window = [-15 15]; % Period to trim [%] (entire task range is taken as 100%)
likelyhood_threshold = 0.9;

plot_each_joint_angle = 1;
figure_type = 'mean'; % 'stack' / 'mean' 
add_std_background = 0;
trial_ratio_threshold = 0.6; %(if nanmean_type=="stricted") %at least, How many trials are necessary to plot
plot_timing_num = [1, 2, 3, 4];
timing_name = {'lever1 on', 'lever1 off', 'photo on', 'photo off'};

pick_up_each_timing_image = 0; % 各タイミングの静止画を動画から抽出して,構造体に保存する

process_image = 0; %画像解析を行う(pick_up_imageで使用した画像を並べる & 重ね合わせる)
image_type = '.png';

% plot_all_days_joint_angle = 0; 
% 
% calc_max_min_angle = 0;
% flactuation_detection = 0; %関節角度の軌跡の微分値から関節角度が変動するタイミングを検知してそのフレーム数とID(どの関節がどの方向に変化するかを現したもの)を出力する(各トライアルにおける変動するタイミングを記録するだけ)
%% code section
%% generates the data necessary for general motion analysis.
disp(['Please select all DLC csv file (ex.) ' real_name '_DLC_data/' monkey_name '~.csv'])
[DLC_csv_files_name, DLC_fold_path] = uigetfile(fullfile(pwd, [real_name '_DLC_data'], '*.csv'), 'MultiSelect','on');
if DLC_csv_files_name == 0
    error('user pressed cancel.');
elseif ischar(DLC_csv_files_name)
    DLC_csv_files_name = {DLC_csv_files_name};
end

% Extract only the names of the directories you need
day_folders = extract_num_part(DLC_csv_files_name);

% Store the data needed for analysis in 'basic_data' (type:struct)
basic_data = struct();  % make struct type variable (to store basic_data)
for ii = 1:length(day_folders)
    % Get csv file name
    ref_csv_file_name = DLC_csv_files_name{ii};
    % get each trial basic_data & processing these basic_data
    load_file_path = fullfile(DLC_fold_path, ref_csv_file_name);
    csv_contents = readcell(load_file_path, 'Range', [2,2]);
    num_parts = regexp(ref_csv_file_name, '\d+', 'match');
    basic_data.body_parts = unique({csv_contents{1, :}}, 'stable');
    basic_data.data_type = unique({csv_contents{2, :}}, 'stable');
    eval(['basic_data.' monkey_name day_folders{ii} ' = cell2mat(csv_contents(3:end, :));']);
end

%% conduct joint angle analysis
if conduct_joint_angle_analysis
    % prepare input data of 'calc_joint_angle'
    input_data = struct;
    input_data.body_parts = basic_data.body_parts; 
    input_data.data_type = basic_data.data_type;

    for ii = 1:length(day_folders)
        % Store the result data in 'joint_angle_data_list'(This is generated separately for each day)
        disp([day_folders{ii} 'のexcelファイルを選択してください'])
        [manual_trim_file_name, manual_trim_file_path] = uigetfile(fullfile(pwd, [real_name '_manual_trim_files'], '*.xlsx'));
        manual_trim_data = readmatrix(fullfile(manual_trim_file_path, manual_trim_file_name));
        joint_angle_data_list = struct();
            ref_data = eval(['basic_data.' monkey_name day_folders{ii}]);
            input_data.coodination_data = ref_data;
            if isempty(input_data.coodination_data)  % If there is no video content
                continue;
            end
            % calculate joint angle
            [target_joint, joint_angle_data] = calc_joint_angle(input_data, likelyhood_threshold);
            % trimming joint angle data by trial
            joint_angle_data_list = manual_trim_trial(target_joint, joint_angle_data, manual_trim_data, manual_trim_window);
        % save data
        specific_name = 'joint_angle';
        save_fold_path = fullfile(pwd, save_data_location, specific_name);
        if not(exist(fullfile(save_fold_path, day_folders{ii})))
            mkdir(fullfile(save_fold_path, day_folders{ii}))
        end
        save(fullfile(save_fold_path, day_folders{ii}, 'joint_angle_data(all_record).mat'), "joint_angle_data_list", 'target_joint' )
    end
end

%% plot the angle data of each days
% caution!!: Please conduct joint_angle_analysis first
if plot_each_joint_angle
    joint_angle_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    for ii =1:length(day_folders)
        joint_angle_data_path = fullfile(joint_angle_data_location,day_folders{ii}, 'joint_angle_data(all_record).mat');
        load(joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % get param for iteration
        trial_num = numel(fieldnames(joint_angle_data_list));
        target_joint_num = length(target_joint);
        % plot figure
        plot_each_timing_angle(target_joint ,target_joint_num, joint_angle_data_list, trial_num, plot_timing_num, save_figure_loacation, figure_type, manual_trim_window, timing_name, trial_ratio_threshold, day_folders{ii}, add_std_background);
    end
end

if pick_up_each_timing_image
    for ii = 1:length(day_folders)
        disp([day_folders{ii} 'のexcelファイルを選択してください'])
        [manual_trim_file_name, manual_trim_file_path] = uigetfile(fullfile(pwd, [real_name '_manual_trim_files'], '*.xlsx'));
        manual_trim_data = readmatrix(fullfile(manual_trim_file_path, manual_trim_file_name));
        each_timing_idx_list = manual_trim_data(:, 1:end-1);
        [trial_num, timing_num] = size(each_timing_idx_list);
        all_images_struct = struct();
        % select movie
        disp([day_folders{ii} 'の動画ファイル(.MOV)を選択してください (ex.) Seseki_movie/Se200117_L_cam1.MOV'])
        [video_file_name, video_file_path] = uigetfile(fullfile(pwd, [real_name '_movie'], '.MOV'));
        % getVideoPath (from Seseki_movie -> ...)
        Video = VideoReader(fullfile(video_file_path, video_file_name));

        for jj = 1:timing_num
            all_images_struct.(['timing' num2str(jj)]) = cell(trial_num, 1);
            for kk = 1:trial_num
                frame_idx = each_timing_idx_list(kk, jj);
                output_image = pick_up_designated_image(Video, frame_idx);
                all_images_struct.(['timing' num2str(jj)]){kk} = output_image;
            end
        end
        % save data
        save_data_fold_path = fullfile(pwd, save_data_location, 'each_timing_images', real_name, day_folders{ii});
        if not(exist(save_data_fold_path))
            mkdir(save_data_fold_path)
        end
        save(fullfile(save_data_fold_path, [ 'each_timing_images_data.mat']), "all_images_struct", 'timing_num', 'trial_num', 'video_file_path', 'video_file_name');
    end
end

if process_image
    % プロットしたい日付のフォルダ内のeach_timing_images_data.matを選択してください
    [img_file_name, img_fold_name] = uigetfile(fullfile(pwd, save_data_location, 'each_timing_images', real_name));
    folder_elements = split(img_fold_name, '/');
    ref_day = folder_elements{end-1};
    % データのロード
    load(fullfile(img_fold_name, img_file_name), 'all_images_struct', 'timing_num', 'trial_num');
   for ii = 1:timing_num
        % 無作為に9枚の画像を選択する
        image_num = trial_num;    
        % 9つの整数を無作為に選ぶ
        numToPick = 9;
        randomIntegers = sort(datasample(1:image_num, numToPick, 'Replace', false));
        plot_images = cell(3,3); %9この画像を3*3で出力する
        for kk = 1:numToPick
            plot_images{kk} = all_images_struct.(['timing' num2str(ii)]){kk};
        end
        % montageを表示
        montage(plot_images, 'Size', [3, 3]); % 3行3列のグリッド
        title([ref_day '-' timing_name{ii}], 'FontSize',22)
        montage_fig = gcf;
        % 画像を順に重ね合わせる
        result = im2double(plot_images{1});
        for i = 2:numToPick
            result = result + im2double(plot_images{i}); 
        end        
        %画像の平均をとる
        average_images = result / numToPick;
        % 最終的な結果を表示または保存
        imfuse_figure = figure();
        imshow(average_images);
        set(imfuse_figure, 'Position', [100, 100, 1200, 1000]);
        title([ref_day '-' timing_name{ii}], 'FontSize',22)
        % figureのセーブ
        save_fig_fold = fullfile(pwd, save_figure_loacation, 'specific_images', real_name, 'each_trial', ref_day);
        if not(exist(save_fig_fold))    
            mkdir(save_fig_fold);
        end
        figure(montage_fig);
        saveas(gcf, fullfile(save_fig_fold, ['arranged_timing' num2str(ii) '_images.png']));
        saveas(gcf, fullfile(save_fig_fold, ['arranged_timing' num2str(ii) '_images.fig']));
        figure(imfuse_figure)
        saveas(gcf, fullfile(save_fig_fold, ['stacked_timing' num2str(ii) '_images.png']));
        saveas(gcf, fullfile(save_fig_fold, ['stacked_timing' num2str(ii) '_images.fig']));
        close all;
   end
end

