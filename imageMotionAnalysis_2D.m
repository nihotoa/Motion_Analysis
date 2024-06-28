%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[analysis workflow]
1. analysisPackageによって動画を切り出し、Motion_analysis/Seseki_movieにその動画を移す
2.このコードのextract_image(任意の1フレームを各トライアル動画から持ってくる関数), proces_image(overlya, montageの作成)をtrueにして実行
3.anaconda 環境でdeeplabcutの環境に変更して(必要なライブラリがインストールされているため),annotationProgram.pyによってannotation
4.joint_angle_calculation(アノテーションによってえられたキーポイント情報から, 関節角度を計算)
5.plotDailyJointAngles(フェーズごとの関節角度の遷移とその回帰結果をプロット)
6.perform_anovaによって、比較対象のフェーズの関節角度を一元配置分散分析

[改善点]
post_first_elapsed_dateが20になっているので、変更する
path設定が汚すぎ
save_dataのautoの階層構造がデータによって違う
向き => 日付 => フレーム前   で統一する
(データ参照のpathが変わりそうでめんどいから保留してる)
anovaの図のセーブ設定を変える

[注意点] 
annotationのプログラムはpythonで作った
動画の入っているフォルダ(GU)Iで選択するフォルダ)の名前は['サル名' + '_movie']にしてください (例)'Seseki_movie'
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
% please select the analysis which you want to perform
extract_image = true;
process_image = false; 
joint_angle_calculation = false;
plotDailyJointAngles = true;
perform_anova = false;
plot_anova_heatmap = false;

% common parameters
extract_image_type = 'manual'; % 'manual' / 'auto'
diff_end_frame = 20; % reference timing (N frames before 'food touch') 
video_type = '.avi'; % extention of reference movie

% extract_image parameter
trial_num = 20; % the number of  images you want to extract (if you want to pick up image for all trial, please set 'NaN')
image_type = '.png'; % Extension of the image to be saved.

%process_image parameter
montage_numToPick = 9; % Number of images to be displayed as montage.
image_row_num = 3; % row of motage (col is automatically decided as this parameter)
overlay_numToPick = NaN; % Number of images used for overlay. if you want to use all trial images, please set 'NaN'

% plotDailyjointAngles parameters
phase_date_list = {'20200117', '20200212', '20200226', '20200305', '20200310', '20200324'}; % Specific dates for each phase.
linear_regression_plot = true; % whether you want to draw reqression function which is estimated lineaer regression
estimate_order = 1; % order of polynomial regression

% anova parameters
group_type = 'designated_group'; % 'pre_post' / 'designated_group' 'pre_post' => 1way anova between 'pre' and 'post' 
designated_group = {[1], [2]}; %  (if group_type == 'designated_group'), Specify the phases belonging to each group in a cell array.
significant_level = 0.01; % Specify the phases belonging to each group in a cell array.

%% code section
% generates the data necessary for general motion analysis.
disp('Please select the folder containing movie folder for all date');
common_movie_path = uigetdir();
if not(common_movie_path)
    disp('User pressed cancel');
    return;
end
path_elements = split(common_movie_path, '/');
monkey_name = strrep(path_elements{end}, '_movie', '');

if common_movie_path == 0
    error('user pressed cancel.');
end

% get the information of movie directory name
disp('Please select movie folder which you want to perform analysis')
movie_fold_names = uiselect(dirdir(common_movie_path),1,'Please select folders which contains the data you want to analyze');
if isempty(movie_fold_names)
    disp('User pressed cancel');
    return;
end
day_folders = extract_num_part(movie_fold_names);

% setting path (to refer data and save data)
switch extract_image_type
    case 'manual'
        common_save_figure_fold_path = fullfile(pwd, 'save_figure', monkey_name,  'specific_images', 'manual');
        common_save_data_fold_path = fullfile(pwd, 'save_data', monkey_name,  'manual', 'diff_end_frame');
        common_coordination_data_path = fullfile(pwd, 'save_data', monkey_name,  'manual', 'coordination_data');
        common_joint_angle_path = fullfile(pwd, 'save_data', monkey_name,  'manual', 'joint_angle');   
        common_save_transition_figure_fold_path = fullfile(pwd, 'save_figure', monkey_name,  'transition_joint_angle', 'manual');
        common_anova_result_figure_path = fullfile(pwd, 'save_figure', monkey_name,  'anova', 'manual');
    case 'auto'
        common_save_figure_fold_path = fullfile(pwd, 'save_figure', monkey_name,  'specific_images', 'auto', ['diff_end_' num2str(diff_end_frame) '_frame']);
        common_coordination_data_path = fullfile(pwd, 'save_data', monkey_name,  'auto', 'coordination_data', ['diff_end_' num2str(diff_end_frame) '_frame']);
        common_joint_angle_path = fullfile(pwd, 'save_data', monkey_name,  'auto', 'joint_angle', ['diff_end_' num2str(diff_end_frame) '_frame']);    
        common_save_transition_figure_fold_path = fullfile(pwd, 'save_figure', monkey_name,  'transition_joint_angle', 'auto', ['diff_end_' num2str(diff_end_frame) '_frame']);
        common_anova_result_figure_path = fullfile(pwd, 'save_figure', monkey_name,  'anova', 'auto', ['diff_end_' num2str(diff_end_frame) '_frame']);
end

for day_id = 1:length(day_folders)
    % get movie information
    ref_movie_fold_path = fullfile(common_movie_path, movie_fold_names{day_id});
    ref_movie_file_list = dirEx(ref_movie_fold_path, [], video_type);
    if isnan(trial_num)
        trial_num = length(ref_movie_file_list);
    end

    %% extract specific images for each trial by GUI opearation
    if extract_image == 1
        % path setting
        save_figure_fold_path = fullfile(common_save_figure_fold_path, day_folders{day_id});
        makefold(save_figure_fold_path);
        if strcmp(extract_image_type, 'manual')
            save_data_folder_path = fullfile(common_save_data_fold_path, day_folders{day_id});
            makefold(save_data_folder_path);
            diff_end_frame_list = zeros(trial_num, 1);
        end

        for trial_id = 1:trial_num
            save_figure_name = ['trial' sprintf('%03d', trial_id)];
            ref_trial_movie_path = fullfile(ref_movie_fold_path, ref_movie_file_list(trial_id).name);
            
            switch extract_image_type
                case 'manual'
                    % operate each image by GUI operation & save_figure
                    diff_end_frame = videoGUIOperator(ref_trial_movie_path, save_figure_fold_path, save_figure_name, image_type);
                    diff_end_frame_list(trial_id) = diff_end_frame;
                case 'auto'
                    auto_save_image(ref_trial_movie_path, diff_end_frame, save_figure_fold_path, save_figure_name, image_type)
            end
        end

        % save diff_end_frame(if you exract image as manual operation)
        if strcmp(extract_image_type, 'manual')
            % save_diff_end_frame
            save(fullfile(save_data_folder_path, 'diff_end_frame.mat'), "diff_end_frame_list");
        end
    end
    
    %% create montage & overlay figure with using images extracted by analysis of one previous section
    if process_image == 1
        save_figure_fold_path = fullfile(common_save_figure_fold_path, day_folders{day_id});
        candidate_images = getfileName(save_figure_fold_path, ['trial*' image_type]); %作成した図を読み込まないように接頭語のtrialを追加する

        % create montage figure
        image_num = length(candidate_images);
        randomIntegers = sort(datasample(1:image_num, montage_numToPick, 'Replace', false));
        image_col_num = ceil(montage_numToPick / image_row_num);
        plot_images = cell(image_row_num, image_col_num); 
        for image_id = 1:montage_numToPick
            plot_images{image_id} = imread(fullfile(save_figure_fold_path,candidate_images{randomIntegers(image_id)}));
        end
        % montageを表示
        montage(plot_images, 'Size', [image_row_num, image_col_num]); 
        switch extract_image_type
            case 'manual'
                title([day_folders{day_id} '-manual'], 'FontSize',22)
            case 'auto'
                title([day_folders{day_id} '-(diff_end_frame=' num2str(diff_end_frame) ')'], 'Interpreter', 'none', 'FontSize', 22)
        end
        montage_fig = gcf;

        % create overlay figure
        if isnan(overlay_numToPick)
            overlay_numToPick = image_num;
        end
        randomIntegers = sort(datasample(1:image_num, overlay_numToPick, 'Replace', false));
        image_data = imread(fullfile(save_figure_fold_path,candidate_images{randomIntegers(1)}));
        result = im2double(image_data);
        for image_id = 2:overlay_numToPick
            image_file_path = fullfile(save_figure_fold_path,candidate_images{randomIntegers(image_id)});
            image_data = imread(image_file_path);
            result = result + im2double(image_data); 
        end        
        
        % average
        average_images = result / overlay_numToPick;

        % display overlay figure
        overlay_figure = figure();
        imshow(average_images);
        set(overlay_figure, 'Position', [100, 100, 1200, 1000]);

        switch extract_image_type
            case 'manual'
                title([day_folders{day_id} '-manual(' num2str(overlay_numToPick) ' trial)'], 'FontSize',22)
            case 'auto'
                title([day_folders{day_id} '-(diff_end_frame=' num2str(diff_end_frame) ')_(' num2str(overlay_numToPick) ' trial)'], 'Interpreter', 'none', 'FontSize', 22)
        end
        

        % fsave figure
        figure(montage_fig);
        saveas(gcf, fullfile(save_figure_fold_path, 'arranged_pick_up_images.png'))
        figure(overlay_figure)
        saveas(gcf, fullfile(save_figure_fold_path, 'overlayed_pick_up_images.png'))
        close all;
    end
    
    %% calc joint angle
    if joint_angle_calculation == 1 
        % calcurate joint angle for each days
        ref_coordination_data_path = fullfile(common_coordination_data_path, day_folders{day_id}, 'coordination_data_list.csv');
        data_table = readtable(ref_coordination_data_path);
        col_name_list = data_table.Properties.VariableNames;

        % get input_data.body_parts list & input_data.data_type list
        input_data = struct();
        input_data.body_parts = {};
        input_data.data_type = {};
        for col_id = 1:length(col_name_list)
            col_name = col_name_list{col_id};
            elements = split(col_name, '_');
            input_data.body_parts{end+1} = elements{1};
            input_data.data_type{end+1} = elements{2};
        end
        input_data.body_parts = unique(input_data.body_parts, 'stable');
        input_data.data_type = unique(input_data.data_type, 'stable');
        input_data.coordination_data = table2array(data_table);
        
        % calc_joint_angle
        [target_joint, joint_angle_data_list] = calc_joint_angle_manual(input_data);

        % save joint angle data
        joint_angle_data_save_fold_path = fullfile(common_joint_angle_path, day_folders{day_id});
        makefold(joint_angle_data_save_fold_path);
        save(fullfile(joint_angle_data_save_fold_path, 'joint_angle_data.mat'), 'target_joint', 'joint_angle_data_list')
    end
end

%% create a diagram showing the transition of join angles
if plotDailyJointAngles == 1
    ref_term_data = struct();
    for day_id = 1:length(day_folders)
        ref_joint_angle_data_path = fullfile(common_joint_angle_path, day_folders{day_id}, 'joint_angle_data.mat');
        load(ref_joint_angle_data_path, 'target_joint', 'joint_angle_data_list')
    
        % find mean and std value of joint angle for each joint
        for target_id = 1:length(target_joint)
            if day_id == 1
                % preapare empty array to store joint angle data(mean and std data)
                ref_term_data.(target_joint{target_id}).mean = zeros(1, length(day_folders));
                ref_term_data.(target_joint{target_id}).std = zeros(1, length(day_folders));
            end
    
            ref_data = joint_angle_data_list.(target_joint{target_id});
            mean_value = mean(ref_data);
            std_value = std(ref_data);
            ref_term_data.(target_joint{target_id}).mean(day_id) = mean_value;
            ref_term_data.(target_joint{target_id}).std(day_id) = std_value;
        end
    end    

    % plot data
    elapsed_date_list = makeElapsedDateList(day_folders, '200121');
    post_first_elapsed_date = elapsed_date_list(find(elapsed_date_list > 0, 1 ));
    phase_elapsed_date_list = makeElapsedDateList(phase_date_list, '200121');
    
    % plot figure
    plot_phase_figure_manual(ref_term_data, target_joint, elapsed_date_list, phase_elapsed_date_list, post_first_elapsed_date, extract_image_type, common_save_transition_figure_fold_path, diff_end_frame, linear_regression_plot, estimate_order)
end

%% 
if perform_anova == 1
    % prepare ;labels
    phase_labels = makePhaseLabels(day_folders, phase_date_list);

    % prepare materials which is needed to perform anova
    [value_struct, group_label, target_joint] = anovaPreparation(day_folders, common_joint_angle_path, group_type, designated_group, phase_labels);

    % perform anova
    for target_joint_id = 1:length(target_joint)
        ref_data = value_struct.(target_joint{target_joint_id});
        [p, tbl] = anova1(ref_data, group_label);
        
        % decoration
        grid on;
        set(gca, "FontSize", 14);
        ylabel('joint angle[angle]', 'FontSize', 18);
        h = gca;
        title(['1-way anova (' target_joint{target_joint_id} '-joint)' newline ' p-value = ' num2str(p) '(<0.05)'], 'FontSize', 18);

        % save figure
        makefold(common_anova_result_figure_path);
        switch group_type
            case 'pre_post'
                saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(pre_post).png']));
                saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(pre_post).fig']));
            case 'designated_group'
                unique_name = strjoin(unique(group_label), '_vs_');
                saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(' unique_name ').png']));
                saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(' unique_name ').fig']));
        end
        close all;
    end
end

if plot_anova_heatmap == 1
    % データの作成
    heatmap_struct = struct();
    background_color_struct = struct();
    customColormap = [1 1 1; 0 0 0; 1 0 0; 0 0 1]; % white, black, red, blue
    day_num = length(day_folders);
    %make labels
    phase_labels = makePhaseLabels(day_folders, phase_date_list);

    for day_id1 = 1:day_num
        for day_id2 = (day_id1+1):day_num
            designated_group = {day_id1, day_id2};
            % prepare materials which is needed to perform anova
            [value_struct, group_label, target_joint] = anovaPreparation(day_folders, common_joint_angle_path, 'designated_group', designated_group, phase_labels);

            % perform anova
            for target_joint_id = 1:length(target_joint)
                ref_data = value_struct.(target_joint{target_joint_id});
                [p, tbl] = anova1(ref_data, group_label, "off");
                if and(day_id1==1, day_id2==2)
                    heatmap_struct.(target_joint{target_joint_id}) = nan(day_num, day_num);
                    background_color_struct.(target_joint{target_joint_id}) = ones(day_num, day_num);
                end

                heatmap_struct.(target_joint{target_joint_id})(day_id1, day_id2) = p;
                % assign background color
                if (isnan(p)) || (p > significant_level)
                    % 有意差なし
                    background_color_struct.(target_joint{target_joint_id})(day_id1, day_id2) = 2;
                else
                    id1_data_idx = find(strcmp(group_label, phase_labels{day_id1}));
                    id2_data_idx = find(strcmp(group_label, phase_labels{day_id2}));
                    id1_data_mean = mean(ref_data(id1_data_idx));
                    id2_data_mean = mean(ref_data(id2_data_idx));
                    if id1_data_mean < id2_data_mean
                        % 有意差あり & 上昇
                        background_color_struct.(target_joint{target_joint_id})(day_id1, day_id2) = 3;
                    else
                        % 有意差あり & 減少
                        background_color_struct.(target_joint{target_joint_id})(day_id1, day_id2) = 4;
                    end
                end
            end
        end
    end

    %% plot heatmap
    % plot heatmap
    for target_joint_id = 1:length(target_joint)
        ref_heatmap_data = heatmap_struct.(target_joint{target_joint_id});
        ref_background_color = background_color_struct.(target_joint{target_joint_id});
        figure('position', [100, 100, 1200, 1200])
        colormap(customColormap);

        % 色のみをプロット
        imagesc(ref_background_color);
        colorbar off;
        axis equal tight;

        % 各マスの上にテキストを入れていく
        textStrings = num2str(ref_heatmap_data(:), '%.4f');
        textStrings = strtrim(cellstr(textStrings));
        [x, y] = meshgrid(1:size(ref_heatmap_data, 2), 1:size(ref_heatmap_data, 1));
        hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'Color', 'w');
        nanIndex_list = isnan(ref_heatmap_data(:));
        set(hStrings(nanIndex_list), 'Color', 'k');

        %decoration
        axis xy;
        xline((0.5:1:day_num-0.5))
        yline((0.5:1:day_num-0.5))
        xticks(1:day_num); yticks(1:day_num);
        xticklabels(phase_labels);
        yticklabels(phase_labels);
        xtickangle(90);
        set(gca, 'FontSize', 15)
        c = colorbar;
        c.Ticks = [1.4 2.15 2.9 3.65];
        c.TickLabels = {'NaN', 'n.s.', 'Sig.(increase)', 'Sig.(decrease)'};
        c.FontSize=20;
        title_str = sprintf(['anova result (' target_joint{target_joint_id} '-joint) (α=' num2str(significant_level) ')']);
        title(title_str, 'FontSize', 20)

        % save figure
        makefold(common_anova_result_figure_path);
        saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(all_combination_heatmap_a = ' num2str(significant_level) ').png']));
        saveas(gcf, fullfile(common_anova_result_figure_path, ['1way_anova_result(' target_joint{target_joint_id} ')(all_combination_heatmap_a = ' num2str(significant_level) ').fig']));
        close all;
    end
end