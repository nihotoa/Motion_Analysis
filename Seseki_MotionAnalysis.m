%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]

[role of this code]
Performs all processing related to Seseki behavior analysis
(this code perform various analysis with focusing on minimum angle timing of MP & Wrist joint)

[caution!!]
> this code is created for Seseki movie analaysis. So, this code may not be compatible with other analyses.
> The functions used in this code are stored in the following location
  path: Motion_analysis/code/Seseki_analysis_package

[saved basic_data location]

[procedure]
pre: nothing
post: coming soon...

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
conduct_joint_angle_analysis = 0;
likelyhood_threshold = 0.9;
plot_each_days_joint_angle = 0;
plot_range = [-30, 30]; %window size of plot(used plot_each & plot_all)
nanmean_type = 'stricted'; %'absolute'/'stricted' (whether you want to use 'nanmean' or not)
trial_ratio_threshold = 0.6; %(if nanmean_type=="stricted") %at least, How many trials are necessary to plot
plot_all_days_joint_angle = 0; 
save_data_location = 'save_data';
save_figure_loacation = 'save_figure';
calc_max_min_angle = 0;
pick_up_image = 0; % angleが最小となる時のimageをとってくる(静止画をセーブフォルダにしまうだけ)
video_type = '.avi'; % 読み込み対象の動画の拡張子
process_image = 1; %画像解析を行う(pick_up_imageで使用した画像を並べる & 重ね合わせる)
image_type = '.png';
flactuation_detection = 0; %関節角度の軌跡の微分値から関節角度が変動するタイミングを検知してそのフレーム数とID(どの関節がどの方向にを著したもの)を出力する(各トライアルにおける変動するタイミングを記録するだけ)
%% code section
%% generates the data necessary for general motion analysis.
disp('Please select the folder containing Seseki movie (Motion_analysis -> seseki_movie)')
movie_fold_full_path = uigetdir();
if movie_fold_full_path == 0
    error('user pressed cancel.');
end
movie_fold_path = strrep(movie_fold_full_path, fullfile(pwd, '/'), '');
each_fold_names = dir(movie_fold_path);

% Extract only the names of the directories you need
each_fold_names = extract_element_fold(each_fold_names, monkey_name);
day_folders = extract_num_part(each_fold_names);

% Store the data needed for analysis in 'basic_data' (type:struct)
basic_data = struct();  % make struct type variable (to store basic_data)
for ii = 1:length(day_folders)
    % Get csv file name
    csv_list = dir([movie_fold_path '/' each_fold_names{ii} '/' '*.csv']);
    csv_file_names = {csv_list.name}';
    % get each trial basic_data & processing these basic_data
    trial_num = length(csv_file_names);
    for jj = 1:trial_num
        load_file_path = fullfile(pwd, movie_fold_path, each_fold_names{ii}, csv_file_names{jj});
        csv_contents = readcell(load_file_path, 'Range', [2,2]);
        num_parts = regexp(csv_file_names{jj}, '\d+', 'match');
        if jj == 1
            basic_data.body_parts = unique({csv_contents{1, :}}, 'stable');
            basic_data.data_type = unique({csv_contents{2, :}}, 'stable');
            % num_partsの中で, '01'のindex番号をref_trial_idxに代入する
            ref_trial_idx = find(cellfun(@(x) isequal(x, '01'), num_parts));
        end
        ref_trial = num_parts{ref_trial_idx};
        eval(['basic_data.' monkey_name day_folders{ii} '.trial' ref_trial ' = cell2mat(csv_contents(3:end, :));']);
    end
end

%% conduct joint angle analysis
if conduct_joint_angle_analysis
    % prepare input data of 'calc_joint_angle'
    input_data = struct;
    input_data.body_parts = basic_data.body_parts; 
    input_data.data_type = basic_data.data_type;

    for ii = 1:length(day_folders)
        % Store the result data in 'joint_angle_data_list'(This is generated separately for each day)
        joint_angle_data_list = struct();
        trial_num = numel(fieldnames(eval(['basic_data.' monkey_name day_folders{ii}])));

        for jj = 1:trial_num
            use_data = eval(['basic_data.' monkey_name day_folders{ii} '.' 'trial' sprintf('%02d', jj)]);
            input_data.coodination_data = use_data;
            if isempty(input_data.coodination_data)  % If there is no video content
                continue;
            end
            [target_joint, joint_angle_data] = calc_joint_angle(input_data, likelyhood_threshold);
            eval(['joint_angle_data_list.trial' num2str(jj) ' = joint_angle_data;']) 
        end

        % save data
        specific_name = 'joint_angle';
        save_fold_path = fullfile(pwd, save_data_location, specific_name);
        if not(exist(fullfile(save_fold_path, day_folders{ii})))
            mkdir(fullfile(save_fold_path, day_folders{ii}))
        end
        save(fullfile(save_fold_path, day_folders{ii}, 'joint_angle_data.mat'), "joint_angle_data_list", 'target_joint' )
    end
end

%% plot the angle data of each days
% caution!!: Please conduct joint_angle_analysis first
if plot_each_days_joint_angle
    joint_angle_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    for ii =1:length(day_folders)
        joint_angle_data_path = fullfile(joint_angle_data_location,day_folders{ii}, 'joint_angle_data.mat');
        load(joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % plot figure & save plot data
        switch nanmean_type
            case 'absolute'
                each_plot(joint_angle_data_list, target_joint, day_folders{ii}, plot_range);
            case 'stricted'
                each_plot(joint_angle_data_list, target_joint, day_folders{ii}, plot_range, trial_ratio_threshold);
        end
        % each_plot(joint_angle_data_list, target_joint, day_folders{ii}, plot_range)
    end
end

%% plot the angle data of all days
% caution!!:Please conduct plot_each_joint_angle
% 使用するデータを,nanmean考慮にするのか,restrictにするのかで分ける
% eachと同じように2*2の図を作る
% strictedでloadしたデータに2*2が反映されていない(main_MPがない) -> eachのsave sectionを確認
% save_stack_dataとsave_stdデータがうまく設定されていないのが原因(関数への入出力引数をうまく調整する or trimmed_aligned_all_trial_dataを渡す)
if plot_all_days_joint_angle
    common_load_data_location = fullfile(pwd, save_data_location, 'trimmed_joint_angle',  [num2str(plot_range(1)) '_to_' num2str(plot_range(2)) '(frames)']);
    figure('Position',[0 0 1200 600]);
    % create color map
    cmp = colormap(jet(length(day_folders)));
    for ii = 1:length(day_folders)
        switch nanmean_type
            case 'absolute'
                load(fullfile(common_load_data_location, day_folders{ii},  ['trimmed_joint_angle_data(std).mat']), 'target_joint', 'trimmed_joint_angle_data');
            case 'stricted'
                load(fullfile(common_load_data_location, day_folders{ii},  ['trimmed_joint_angle_data(std)_ratio_above_' num2str(trial_ratio_threshold) '.mat']), 'target_joint', 'trimmed_joint_angle_data');
        end
        color_value = cmp(ii,:);
        for jj = 1:length(target_joint) %main_joint
            for kk = 1:length(target_joint) %sub_joint
                subplot(length(target_joint),length(target_joint), length(target_joint)*(kk-1)+jj);
                hold on
                % decorate
                if ii == 1
                    grid on;
                    xlabel('elapsed time(frame)', 'FontSize',15);
                    ylabel('joint angle(degree)', 'FontSize', 15);
                    additional_string = '';
                    if jj == kk
                        additional_string = ' (main)';
                    end
                    title([target_joint{kk} ' joint angle' additional_string], 'FontSize',15)
                end
                plot_data = eval(['trimmed_joint_angle_data.main_' target_joint{jj} '.' target_joint{kk}]);
                x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1));
                plot(x, plot_data, 'Color',color_value, 'LineWidth',1.4, 'DisplayName', day_folders{ii});
                hold off
                if ii==length(day_folders) && jj==length(target_joint)
                    legend()
                end
            end
        end
    end
    % save
    analysis_type = 'joint_angle';
    specific_name = 'all_days';
    save_figure_fold_path = fullfile(pwd, save_figure_loacation, analysis_type, specific_name);
    if not(exist(save_figure_fold_path))
        mkdir(save_figure_fold_path)
    end
    switch nanmean_type
        case 'stricted'
                    saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle(stricted).png'))
                    saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle(stricted).fig'))
        case 'absolute'
                saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle.png'))
                saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle.fig'))
    end 
    close all;
end

%%  calcurate max & min angle of each joint
% caution!!:Please conduct conduct_joint_angle_analysis firstly
if calc_max_min_angle
    common_load_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    output_data1 = zeros(length(day_folders), 5); % MP
    output_data2 = zeros(length(day_folders), 5); % Wrist
    for ii = 1:length(day_folders)
        load_data_path = fullfile(common_load_data_location, day_folders{ii}, 'joint_angle_data.mat');
        load(load_data_path, 'joint_angle_data_list', 'target_joint');
        trial_names = fieldnames(joint_angle_data_list);
        trial_num = length(trial_names);
        for jj = 1:length(target_joint)
            max_data_list = zeros(trial_num, 1);
            min_data_list = zeros(trial_num, 1);
            for kk = 1:trial_num
                ref_data =  eval(['joint_angle_data_list.' trial_names{kk} '.' target_joint{jj}]);
                max_data_list(kk) = max(ref_data);
                min_data_list(kk) = min(ref_data);
            end
            % calcuration
            max_mean = round(mean(max_data_list),1);
            max_std = round(std(max_data_list),1);
            min_mean = round(mean(min_data_list),1);
            min_std =round( std(min_data_list),1);
            diff = round(max_mean-min_mean ,1);
            eval(['output_data' num2str(jj) '(ii ,1) = max_mean;'])
            eval(['output_data' num2str(jj) '(ii ,2) = min_mean;'])
            eval(['output_data' num2str(jj) '(ii ,3) = max_std;'])
            eval(['output_data' num2str(jj) '(ii ,4) = min_std;'])
            eval(['output_data' num2str(jj) '(ii ,5) = diff;'])
        end
    end
    % create table & extract table
    row_names = day_folders;
    col_names = {'max_angle[degree]', 'min_angle[degree]', 'max_angle_std', 'min_angle_std', 'diff_max_min'};
    for ii = 1:length(target_joint)
        ref_output = eval(['output_data' num2str(ii)]);
        output_table = array2table(ref_output, 'RowNames', row_names, 'VariableNames', col_names);
        % Excelファイルの保存パスを指定
        excelFileName = [target_joint{ii}  '_joint_angle_data.xlsx'];
        % テーブルをExcelファイルに書き込む
        writetable(output_table, excelFileName, 'Sheet', 'Sheet1', 'WriteRowNames',true);  % 'Sheet1'はシート名を指定します
    end
end


%% 
% Please do 'conduct_joint_angle_analysis' first
if pick_up_image
    for ii = 1:length(day_folders)
        joint_angle_data_path = fullfile(pwd, save_data_location, 'joint_angle', day_folders{ii}, 'joint_angle_data.mat');
        load(joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % pick up images & save thse images in save_data
        output_images = pick_up_specific_image(joint_angle_data_list, target_joint, day_folders{ii}, real_name, video_type);
        % save specific figure
        for jj = 1:length(target_joint) %main joint
            save_figure_fold_path = fullfile(pwd, 'save_figure', 'specific_images', 'minimum', target_joint{jj}, day_folders{ii});
            if not(exist(save_figure_fold_path))
                mkdir(save_figure_fold_path)
            end
            ref_images = eval(['output_images.main_' target_joint{jj}]);
            trial_num = length(ref_images);
            for kk = 1:trial_num
                ref_image = ref_images{kk};
                % save each figure
                try
                    imwrite(ref_image, fullfile(save_figure_fold_path, ['trial' sprintf('%02d', kk) '.png'])); 
                catch
                    % if ref_image is empty, continue.
                    continue
                end
            end
        end
    end
end

%% process images
% Please do 'pick_up_image' first
% プロトタイプだから結構手直し必要
%{
図はstackに入れる
minimumとmaximumの場合で場合分する
プロットする画像の枚数を定義(numToPickの定義)する部分はヘッダーの変数定義で行う
無作為に選ぶと,解析のたびに結果が変わってしまうので,対応を考える
%}
if process_image
    % load 'target_joint'
    joint_angle_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    joint_angle_data_path = fullfile(joint_angle_data_location,day_folders{1}, 'joint_angle_data.mat');
    load(joint_angle_data_path,'target_joint')
    % get images names
    common_path = fullfile(pwd, 'save_figure', 'specific_images', 'minimum');
    for ii = 1:length(target_joint)
        for jj = 1:length(day_folders)
            file_path = fullfile(common_path, target_joint{ii}, day_folders{jj});
            output_file_names = getfileName(file_path, ['trial*' image_type]); %作成した図を読み込まないように接頭語のtrialを追加する
            % 無作為に9枚の画像を選択する
            % 1から122までの整数を生成
            image_num = length(output_file_names);
            % 9つの整数を無作為に選ぶ
            numToPick = 9;
            randomIntegers = sort(datasample(1:image_num, numToPick, 'Replace', false));
            plot_images = cell(3,3); %9この画像を3*3で出力する
            for kk = 1:numToPick
                plot_images{kk} = imread(fullfile(file_path,output_file_names{randomIntegers(kk)}));
            end
            % montageを表示
            montage(plot_images, 'Size', [3, 3]); % 3行3列のグリッド
            title([day_folders{jj} '-' target_joint{ii} '-' 'minimum'], 'FontSize',22)
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
            title([day_folders{jj} '-' target_joint{ii} '-' 'minimum'], 'FontSize',22)
            % figureのセーブ
            figure(montage_fig);
            saveas(gcf, fullfile(file_path, 'arranged_pick_up_images.png'))
            figure(imfuse_figure)
            saveas(gcf, fullfile(file_path, 'stacked_pick_up_images.png'))
            close all;
        end
    end
end



