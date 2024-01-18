%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
Sesekiの手動で記録した各タイミングのサンプル数と, DLCによって出力されたデータを用いて, 図のプロット
とセーブを行うための関数

[改善点]
各タイミングの0%の時の画像を持ってきてoverlayする(他の関数でもいいかも, この関数内でやる必要はない).
名前の付け方. (stackかmeanか,meanの場合はstdをつけるかどうか,  plot_timingの数, trialの数)
平均値のplot_dataとxをreturnすれば日毎のstackもできるので, それをやれって言われたらやる
subplot ではなくて, 個々の図の単位で保存するようにする
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = plot_each_timing_angle(target_joint ,target_joint_num, joint_angle_data_list, trial_num, plot_timing_num, save_figure_loacation, figure_type, manual_trim_window, timing_name, trial_ratio_threshold, ref_day, add_std_background)
% set string for file name which is saved as result
figure_type_str = ['_' figure_type];
std_background_str = '';
plot_timing_str = ['_' num2str(length(plot_timing_num)) 'timing'];
trial_num_str = ['_' num2str(trial_num) 'trial'];

% create figure
figure("position", [100, 100, 350 * length(plot_timing_num), 800]);
for ii = plot_timing_num
    for jj = 1:target_joint_num
        % make subplot
        subplot(target_joint_num, length(plot_timing_num), length(plot_timing_num) *(jj-1) + (ii - plot_timing_num(1))+1)
        hold on;
        plotted_data = cell(trial_num, 1);
        for kk = 1:trial_num
            ref_data = joint_angle_data_list.(['trial' num2str(kk)]).(['tim' num2str(ii)]).(target_joint{jj});
            if strcmp(figure_type, 'mean')
                ref_data = linear_completion(ref_data);
            end
            ref_data = transpose(ref_data);
            plotted_data{kk} = ref_data;
        end
        % plot_data
        switch figure_type
            case 'stack'
                for kk = 1:trial_num
                    ref_data = plotted_data{kk};
                    x = linspace(manual_trim_window(1), manual_trim_window(2), length(ref_data));
                    plot(x, ref_data, 'LineWidth', 1.2)
                end
            case 'mean'
                % calc average length
                length_list = cellfun(@length, plotted_data);
                average_length = round(mean(length_list));
                x = linspace(manual_trim_window(1), manual_trim_window(2), average_length);
                mean_data_list = zeros(trial_num, average_length);
                for kk = 1: trial_num
                    ref_data = plotted_data{kk};
                    % resampling
                    ref_data = resample(ref_data, average_length, length(ref_data));
                    mean_data_list(kk, :) = ref_data;
                end
               % calc mean_data
               if exist('trial_ratio_threshold') % contain 'trial_ratio_threshold'
                   % if the number of trials in not enough,  make it a NaN value
                   min_trial_num = round(trial_num * trial_ratio_threshold);
                   each_frame_trials = sum(~isnan(mean_data_list));
                   mean_data_list(find(each_frame_trials < min_trial_num)) = NaN;
               end
               mean_data = nanmean(mean_data_list);
               if add_std_background
                   std_data = nanstd(mean_data_list);
                   ar1=area(x, transpose([mean_data-std_data;std_data+std_data]));
                   set(ar1(1),'FaceColor','None','LineStyle',':','EdgeColor','r')
                   set(ar1(2),'FaceColor','r','FaceAlpha',0.2,'LineStyle',':','EdgeColor','r') 
                   hold on;
                   std_background_str = '_stdBackground';
               end
               plot(x, mean_data, 'LineWidth',1.5, 'Color','b')
        end
        % decoration
        xlim([manual_trim_window(1) manual_trim_window(2)])
        grid on;
        title([timing_name{ii} ' ' target_joint{jj}], 'FontSize', 15)
        xlabel('task range[%]', 'FontSize', 15)
        ylabel('Joint Angle[degree]', 'FontSize', 15)
        xline(0, 'Color', 'red', LineWidth=1.5)
        % reverse the direction of Y-axis
        set(gca, 'YDir', 'reverse')
    end
end

% save data & figure
save_fold_path = fullfile(pwd, save_figure_loacation, 'joint_angle', 'each_days', ref_day);
if not(exist(save_fold_path))
    mkdir(save_fold_path);
end
saveas(gcf, fullfile(save_fold_path, ['each-timing-joint-angle' figure_type_str std_background_str plot_timing_str trial_num_str '.fig']));
saveas(gcf, fullfile(save_fold_path, ['each-timing-joint-angle' figure_type_str std_background_str plot_timing_str trial_num_str '.png']));
close all;
end

%% define local function
% 線形補完を行うための関数
function completed_array = linear_completion(ref_array)
    % NaNを線形補完
    x = 1:numel(ref_array);
    nanIdx = isnan(ref_array);
    % 線形補完を行う
    completed_array = interp1(x(~nanIdx), ref_array(~nanIdx), x, 'linear');
end
