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
each_plotが冗長すぎる
each_plotを書き換えたため,allplotでloadするデータの構造が変わっている -> それに応じたコードを書く
pick_up_imageもminimumなのかmaximumなのかはっきりさせる
Sesekiだけではなく、他のサルでも同様の解析ができるようにディレクトリの構造から作り替える
process_imageの保存先の変更
plot_all_days_joint_angleのcmpの色を変える

備考:
plot_each_days_joint_angleまで改訂済み
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Se'; 
real_name = 'Seseki';

% please select the analysis which you want to perform
conduct_joint_angle_analysis = 0;
plot_each_days_joint_angle = 0;
plot_all_days_joint_angle = 1; 
calc_max_min_angle = 0; % max,minの時の関節角度をcsvファイルにまとめて出力する
pick_up_image = 0; % 各関節について、angleが最小となる時の画像の情報を抽出する
process_image = 0; %画像解析を行う(pick_up_imageで使用した画像を並べる & 重ね合わせる)
flactuation_detection = 0; %関節角度の軌跡の微分値から関節角度が変動するタイミングを検知してそのフレーム数とID(どの関節がどの方向にを著したもの)を出力する(各トライアルにおける変動するタイミングを記録するだけ)

likelyhood_threshold = 0.9; % threshold of likelyhood for adopting coordinate values
plus_direction = 'extensor'; % 'flexor'/'extensor'

align_type = 'maximum'; % where should you want to align 0 ('minimum' / 'maximum')
plot_range = [-30, 30]; % window size of plot(used plot_each & plot_all)
nanmean_type = 'true'; %('true'/'false') 'true' => plot nanmean values regardless of 'trial_ratio_threshold', 'false' => replace value into NaN if not satisfied with 'trial_ratio_threshold'
trial_ratio_threshold = 0.6; %(if nanmean_type=="false") %at least, How many trials are necessary to plot

numToPick = 1;
image_row_num = 1;

video_type = '.avi'; % 読み込み対象の動画の拡張子
image_type = '.png'; % 読み込み対象の画像の拡張子

%% code section
% generates the data necessary for general motion analysis.
disp('Please select the folder containing Seseki movie (Motion_analysis -> seseki_movie)')
movie_fold_full_path = uigetdir();
if movie_fold_full_path == 0
    error('user pressed cancel.');
end
movie_fold_names = dir(movie_fold_full_path);

% Extract only the names of the directories you need(EMG_analysis_latestのcodeの中に使えそうな関数があるかも)
movie_fold_names = extract_element_fold(movie_fold_names, monkey_name);
day_folders = extract_num_part(movie_fold_names);

% Store the data needed for analysis in 'basic_data' (type:struct)
basic_data = struct();  % make struct type variable (to store basic_data)
for day_id = 1:length(day_folders)
    % Get csv file name
    ref_movie_fold_path = fullfile(movie_fold_full_path, movie_fold_names{day_id});
    csv_list = dir(fullfile(ref_movie_fold_path, '*.csv'));
    csv_file_names = {csv_list.name}';

    % get each trial basic_data & processing these basic_data
    trial_num = length(csv_file_names);

    for trial_id = 1:trial_num
        ref_trial_file_path = fullfile(ref_movie_fold_path, csv_file_names{trial_id});

        % import the contents of csv file
        csv_contents = readcell(ref_trial_file_path, 'Range', [2,2]);
        num_parts = regexp(csv_file_names{trial_id}, '\d+', 'match');
        if trial_id == 1
            basic_data.body_parts = unique(csv_contents(1, :), 'stable');
            basic_data.data_type = unique(csv_contents(2, :), 'stable');
            % extract idx which is correspond to trial_num from 'num_parts';
            ref_trial_idx = find(cellfun(@(x) isequal(x, '01'), num_parts));
        end
        ref_trial = num_parts{ref_trial_idx};
        basic_data.([monkey_name day_folders{day_id}]).(['trial' ref_trial]) = cell2mat(csv_contents(3:end, :));
    end
end

%% conduct joint angle analysis
if conduct_joint_angle_analysis == 1
    % prepare input data of 'calc_joint_angle'
    input_data = struct;
    input_data.body_parts = basic_data.body_parts; 
    input_data.data_type = basic_data.data_type;

    for day_id = 1:length(day_folders)
        % Store the result data in 'joint_angle_data_list'(This is generated separately for each day)
        joint_angle_data_list = struct();
        trial_num = numel(fieldnames(basic_data.([monkey_name day_folders{day_id}])));

        for trial_id = 1:trial_num
            ref_trial_data = basic_data.([monkey_name day_folders{day_id}]).(['trial' sprintf('%02d', trial_id)]);
            input_data.coodination_data = ref_trial_data;
            if isempty(input_data.coodination_data)  % If there is no video content
                continue;
            end
            % calc joint angle
            [target_joint, joint_angle_data] = calc_joint_angle(input_data, likelyhood_threshold, plus_direction);
            joint_angle_data_list.(['trial' num2str(trial_id)]) = joint_angle_data;
        end

        % save data
        save_fold_path = fullfile(pwd, 'save_data', 'joint_angle', [plus_direction '-plus'] , day_folders{day_id});
        makefold(save_fold_path)
        save(fullfile(save_fold_path, 'joint_angle_data.mat'), "joint_angle_data_list", 'target_joint' )
    end
end

%% plot the angle data of each days
% caution!!: Please conduct joint_angle_analysis first
if plot_each_days_joint_angle == 1
    joint_angle_data_location = fullfile(pwd, 'save_data', 'joint_angle', [plus_direction '-plus']);
    for day_id =1:length(day_folders)
        ref_date_joint_angle_data_path = fullfile(joint_angle_data_location, day_folders{day_id}, 'joint_angle_data.mat');
        load(ref_date_joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % plot figure & save plot data
        switch nanmean_type
            case 'true'
                each_plot(joint_angle_data_list, target_joint, day_folders{day_id}, plot_range, align_type, plus_direction);
            case 'false'
                each_plot(joint_angle_data_list, target_joint, day_folders{day_id}, plot_range, align_type, plus_direction, trial_ratio_threshold);
        end
    end
end

%% plot the angle data of all days
%{
caution!!:Please conduct plot_each_joint_angle firstly
eachと同じように2*2の図を作る
strictedでloadしたデータに2*2が反映されていない(main_MPがない) -> eachのsave sectionを確認
=>save_stack_dataとsave_stdデータがうまく設定されていないのが原因(関数への入出力引数をうまく調整する or trimmed_aligned_all_trial_dataを渡す)
%}
if plot_all_days_joint_angle == 1
    % setting of path for loading joint angle data
    common_load_data_location = fullfile(pwd, 'save_data', 'trimmed_joint_angle', [plus_direction '-plus'], align_type, [num2str(plot_range(1)) '_to_' num2str(plot_range(2)) '(frames)']);
    day_num = length(day_folders);

    % setting of figure & colormap & empty array (to store area and displacement)
    calc_value_struct = struct();
    figure('Position',[0 0 1200 600]);
    cmp = zeros(day_num, 3);
    cmp(1, 3) = 1; % blue for 'phase A'
    post_Rcolor =linspace(80, 255, day_num-1)';
    cmp(2:end, 1) = post_Rcolor / 255;

    % plot mean value of joint angle of each date
    for day_id = 1:length(day_folders)
        % load mean value of joint angle
        switch nanmean_type
            case 'true'
                load(fullfile(common_load_data_location, 'nanmean', day_folders{day_id},  'trimmed_joint_angle_data.mat'), 'target_joint', 'trimmed_joint_angle_data');
            case 'false'
                load(fullfile(common_load_data_location, 'mean', day_folders{day_id},  ['trimmed_joint_angle_data(ratio_threshold=' num2str(trial_ratio_threshold) ').mat']), 'target_joint', 'trimmed_joint_angle_data');
        end
        
        if day_id == 1
            target_joint_num = length(target_joint);

            % add field to store data
            calc_value_struct.area.vs_left = repmat({zeros(1, day_num)}, target_joint_num, target_joint_num);
            calc_value_struct.area.vs_right = repmat({zeros(1, day_num)}, target_joint_num, target_joint_num);
            calc_value_struct.displacement.vs_left = repmat({zeros(1, day_num)}, target_joint_num, target_joint_num);
            calc_value_struct.displacement.vs_right = repmat({zeros(1, day_num)}, target_joint_num, target_joint_num);
            calc_value_struct.focus_timing_angle = repmat({zeros(1, day_num)}, target_joint_num, target_joint_num); 
        end
        
        % plot the joint angle of each joint of ref_day
        color_value = cmp(day_id,:);
        x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1)); % 厳密にはこれ違う

        for main_joint_idx = 1:target_joint_num %main_joint
            for sub_joint_idx = 1:target_joint_num %sub_joint
                % decide location of subplot
                row_idx = sub_joint_idx;
                col_idx = main_joint_idx;
                subplot_idx = target_joint_num*(row_idx-1) + col_idx;
                subplot(target_joint_num, target_joint_num, subplot_idx);
                hold on;

                % extarct target anglendata
                plot_data = trimmed_joint_angle_data.(['main_' target_joint{main_joint_idx}]).(target_joint{sub_joint_idx});
                
                % calc and store the value of displacement & area & angle of focus timing
                first_idx = 1; 
                last_idx =  length(plot_data);
                criterion_idx = last_idx/2;
     
                calc_value_struct.displacement.vs_left{row_idx, col_idx}(day_id) = abs(plot_data(criterion_idx) - plot_data(first_idx));
                calc_value_struct.displacement.vs_right{row_idx, col_idx}(day_id) = abs(plot_data(criterion_idx) - plot_data(last_idx));
                
                calc_value_struct.area.vs_left{row_idx, col_idx}(day_id) = abs(sum(plot_data(first_idx:criterion_idx) - plot_data(criterion_idx)));
                calc_value_struct.area.vs_right{row_idx, col_idx}(day_id) = abs(sum(plot_data(criterion_idx:last_idx) - plot_data(criterion_idx)));
                
                calc_value_struct.focus_timing_angle{row_idx, col_idx}(day_id) = plot_data(criterion_idx);
                % plot
                plot(x, plot_data, 'Color',color_value, 'LineWidth',1.4, 'DisplayName', day_folders{day_id});
                hold on

                % decorate
                if day_id == 1
                    xlim(plot_range);
                    grid on;
                    xlabel('elapsed time(frame)', 'FontSize',15);
                    ylabel('joint angle(degree)', 'FontSize', 15);
                    additional_string = '';
                    if main_joint_idx == sub_joint_idx
                        additional_string = ' (main)';
                    end
                    title([target_joint{sub_joint_idx} ' joint angle' additional_string], 'FontSize',15)
                end
                hold off

                % attach legend
                if day_id==length(day_folders) && main_joint_idx==target_joint_num
                    h = legend();
                    set(h, 'Location', 'eastoutside');
                    set(h, 'Position', [0.91, 0.91, 0.05, 0.05])
                end
            end
        end
    end
    % attatch langend
    sgtitle([plus_direction '-plus, ' align_type '-align'], fontsize=20)

    % save
    switch nanmean_type
        case 'true'
            mean_type_string = 'nanmean';
            figure_file_name = 'all_day_joint_angle(nanmean)';
        case 'false'
            mean_type_string = 'mean';
            figure_file_name = 'all_day_joint_angle';
    end

    save_figure_fold_path = fullfile(pwd, 'save_figure', 'joint_angle', 'all_days', [plus_direction '-plus'], align_type, mean_type_string);   
    makefold(save_figure_fold_path)
    saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.png']))
    saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.fig']))
    close all;
    

    % plot value of displacement and area
    if strcmp(nanmean_type, 'true')
        calc_type = {'area', 'displacement', 'focus_timing_angle'};
        compair_phase_type = {'vs_left', 'vs_right'};
    
        % elapsed date list (for x-axis data)
        [elapsed_date_list] = makeElapsedDateList(day_folders, '200121');
        post_first_elapsed_date = elapsed_date_list(find(elapsed_date_list > 0, 1 ));
    
        for calc_type_id = 1:length(calc_type)
            calc_type_name = calc_type{calc_type_id};
            if strcmp(calc_type_name, 'focus_timing_angle')
                ref_term_data = calc_value_struct.(calc_type{calc_type_id});
                % plot figure
                plot_phase_figure(ref_term_data, target_joint_num, elapsed_date_list, post_first_elapsed_date, target_joint, plus_direction, align_type, nanmean_type, calc_type_name);
            else
                for compair_phase_id = 1:length(compair_phase_type)
                    ref_term_data = calc_value_struct.(calc_type{calc_type_id}).(compair_phase_type{compair_phase_id});
                    compare_phase_name = compair_phase_type{compair_phase_id};
                    % plot figure
                    plot_phase_figure(ref_term_data, target_joint_num, elapsed_date_list, post_first_elapsed_date, target_joint, plus_direction, align_type, nanmean_type, calc_type_name, compare_phase_name);
                end
            end
        end
    end

end

%%  calcurate max & min angle of each joint
% caution!!:Please conduct conduct_joint_angle_analysis firstly
if calc_max_min_angle == 1
    common_load_data_location = fullfile(pwd, 'save_data', 'joint_angle');

    % prepare empty array
    output_data = struct();
    for joint_idx = 1:length(target_joint)
        output_data.([target_joint{joint_idx}]) = zeros(length(day_folders), 5);
    end

    % store max & minimum joint angle of each joint
    for ii = 1:length(day_folders)
        load_data_path = fullfile(common_load_data_location, day_folders{ii}, 'joint_angle_data.mat');
        load(load_data_path, 'joint_angle_data_list', 'target_joint');
        trial_names = fieldnames(joint_angle_data_list);
        trial_num = length(trial_names);
        for jj = 1:length(target_joint)
            max_data_list = zeros(trial_num, 1);
            min_data_list = zeros(trial_num, 1);
            for kk = 1:trial_num
                ref_data = joint_angle_data_list.(trial_names{kk}).(target_joint{jj});
                max_data_list(kk) = max(ref_data);
                min_data_list(kk) = min(ref_data);
            end
            % calcuration
            max_mean = round(mean(max_data_list),1);
            max_std = round(std(max_data_list),1);
            min_mean = round(mean(min_data_list),1);
            min_std =round( std(min_data_list),1);
            diff = round(max_mean-min_mean ,1);

            output_data.(target_joint{jj})(ii, 1) = max_mean;
            output_data.(target_joint{jj})(ii, 2) = min_mean;
            output_data.(target_joint{jj})(ii, 3) = max_std;
            output_data.(target_joint{jj})(ii, 4) = min_std;
            output_data.(target_joint{jj})(ii, 5) = diff;
        end
    end
    % create table & extract table
    row_names = day_folders;
    col_names = {'max_angle[degree]', 'min_angle[degree]', 'max_angle_std', 'min_angle_std', 'diff_max_min'};
    for ii = 1:length(target_joint)
        ref_output = output_data.(target_joint{ii});
        output_table = array2table(ref_output, 'RowNames', row_names, 'VariableNames', col_names);
        % Excelファイルの保存パスを指定
        excelFileName = [target_joint{ii}  '_joint_angle_data.xlsx'];
        % テーブルをExcelファイルに書き込む
        writetable(output_table, excelFileName, 'Sheet', 'Sheet1', 'WriteRowNames',true);  % 'Sheet1'はシート名を指定します
    end
end


%% 
% Please do 'conduct_joint_angle_analysis' first
if pick_up_image == 1
    for ii = 1:length(day_folders)
        joint_angle_data_path = fullfile(pwd, 'save_data', 'joint_angle', [plus_direction '-plus'], day_folders{ii}, 'joint_angle_data.mat');
        load(joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % pick up images & save thse images in save_data
        output_images = pick_up_specific_image(joint_angle_data_list, target_joint, day_folders{ii}, real_name, video_type, plus_direction, align_type);
        % save specific figure
        for jj = 1:length(target_joint) %main joint
            save_figure_fold_path = fullfile(pwd, 'save_figure', 'specific_images', 'minimum', target_joint{jj}, day_folders{ii});
            if not(exist(save_figure_fold_path, "dir"))
                mkdir(save_figure_fold_path)
            end

            ref_images = output_images.(['main_' target_joint{jj}]);
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
if process_image == 1
    % load 'target_joint'
    joint_angle_data_location = fullfile(pwd, 'save_data', 'joint_angle', [plus_direction '-plus']);
    joint_angle_data_path = fullfile(joint_angle_data_location,day_folders{1}, 'joint_angle_data.mat');
    load(joint_angle_data_path, 'target_joint')
    % get images names
    common_path = fullfile(pwd, 'save_figure', 'specific_images', 'minimum');
    for ii = 1:length(target_joint)
        for jj = 1:length(day_folders)
            file_path = fullfile(common_path, target_joint{ii}, day_folders{jj});
            output_file_names = getfileName(file_path, ['trial*' image_type]); %作成した図を読み込まないように接頭語のtrialを追加する
            % 無作為に9枚の画像を選択する
            % 1から122までの整数を生成
            image_num = length(output_file_names);
            % numToPick個の整数を無作為に選ぶ
            randomIntegers = sort(datasample(1:image_num, numToPick, 'Replace', false));
            %画像をimage_row_num * ceil(numToPick/image_row_num)で出力する
            image_col_num = ceil(numToPick / image_row_num);
            plot_images = cell(image_row_num, image_col_num); 
            for kk = 1:numToPick
                plot_images{kk} = imread(fullfile(file_path,output_file_names{randomIntegers(kk)}));
            end
            % montageを表示
            montage(plot_images, 'Size', [image_row_num, image_col_num]); % 3行3列のグリッド
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



