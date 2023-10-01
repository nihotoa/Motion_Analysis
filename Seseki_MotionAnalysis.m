%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]

[role of this code]
Performs all processing related to Seseki behavior analysis

[caution!!]
> this code is created for Seseki movie analaysis. So, his code may not be compatible with other analyses.
> The functions used in this code are stored in the following location
  path: Motion_analysis/code/Seseki_analysis_package

[saved basic_data location]

[procedure]
pre: nothing
post: coming soon...

改善点:
each_plotの中で，save_foldのpathに必要な変数を定義しているの，こっちの大元の関数で変数定義する様に変更する

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Se'; 
conduct_joint_angle_analysis = 0;
likelyhood_threshold = 0.9;
plot_each_days_joint_angle = 0;
plot_range = [-30, 30];
plot_all_days_joint_angle = 1; 
save_data_location = 'save_data';
save_figure_loacation = 'save_figure';
calc_max_min_angle = 1;

%% code section
%% generates the data necessary for general motion analysis.
disp('Please select the folder containing Seseki movie basic_data')
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
% causion!!: Please conduct oint_angle_analysis first
if plot_each_days_joint_angle
    joint_angle_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    for ii =1:length(day_folders)
        joint_angle_data_path = fullfile(joint_angle_data_location,day_folders{ii}, 'joint_angle_data.mat');
        load(joint_angle_data_path, 'joint_angle_data_list', 'target_joint')
        % plot figure & save plot data
        each_plot(joint_angle_data_list, target_joint, day_folders{ii}, plot_range)
    end
end

%% plot the angle data of all days
if plot_all_days_joint_angle
    common_load_data_location = fullfile(pwd, save_data_location, 'trimmed_joint_angle',  [num2str(plot_range(1)) '_to_' num2str(plot_range(2)) '(frames)']);
    figure('Position',[0 0 600 800]);
    for ii = 1:length(day_folders)
        load(fullfile(common_load_data_location, day_folders{ii}, 'trimmed_joint_angle_data(std).mat'), 'target_joint', 'trimmed_joint_angle_data');
        color_value = [ii/length(day_folders), 0, 0];
        for jj = 1:length(target_joint)
            subplot(length(target_joint), 1, jj)
            hold on
            % decorate
            if ii == 1
                grid on;
                xlabel('elapsed time(frame)', 'FontSize',15);
                ylabel('joint angle(degree)', 'FontSize', 15);
                title([target_joint{ii} ' joint angle'], 'FontSize',15)
            end
            plot_data = eval(['trimmed_joint_angle_data.' target_joint{jj}]);
            x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1));
            plot(x, plot_data, 'Color',color_value, 'LineWidth',1.4, 'DisplayName', day_folders{ii});
            hold off
            if ii==length(day_folders) && jj==length(target_joint)
                legend()
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
    saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle.png'))
    saveas(gcf, fullfile(save_figure_fold_path, 'all_day_joint_angle.fig'))
    close all;
end

%% 
if calc_max_min_angle
    common_load_data_location = fullfile(pwd, save_data_location, 'joint_angle');
    output_data1 = zeros(length(day_folders), 4); % MP
    output_data2 = zeros(length(day_folders), 4); % Wrist
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
            max_mean = mean(max_data_list);
            max_std = std(max_data_list);
            min_mean = mean(min_data_list);
            min_std = std(min_data_list);
            eval(['output_data' num2str(jj) '(ii ,1) = max_mean;'])
            eval(['output_data' num2str(jj) '(ii ,2) = min_mean;'])
            eval(['output_data' num2str(jj) '(ii ,3) = max_std;'])
            eval(['output_data' num2str(jj) '(ii ,4) = min_std;'])
        end
    end
    % create table & extract table
    row_names = day_folders;
    col_names = {'max_angle[degree]', 'min_angle[degree]', 'max_angle_std', 'min_angle_std'};
    for ii = 1:length(target_joint)
        ref_output = eval(['output_data' num2str(ii)]);
        output_table = array2table(ref_output, 'RowNames', row_names, 'VariableNames', col_names);
        % Excelファイルの保存パスを指定
        excelFileName = [target_joint{ii}  '_joint_angle_data.xlsx'];
        % テーブルをExcelファイルに書き込む
        writetable(output_table, excelFileName, 'Sheet', 'Sheet1', 'WriteRowNames',true);  % 'Sheet1'はシート名を指定します
    end
end




