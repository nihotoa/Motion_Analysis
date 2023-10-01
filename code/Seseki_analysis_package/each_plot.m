function [] = each_plot(joint_angle_data_list, target_joint, ref_day, plot_range)
% make figures
 fig_str = struct();
 fig_str.stack = figure('Position',[0 0 600 600]);
 fig_str.std = figure('Position',[0 0 600 600]);
 fig_name_list = {'stack', 'std'};

 for ii = 1:length(target_joint)
     trial_num = numel(fieldnames(joint_angle_data_list));
     plot_trial_count = 0; %how many trials be plotted (some trial doesn't contains contents)
     max_frame_length = 0;
     % search the maximum frames of all trials & plot_trial_count
     for jj = 1:trial_num
         try
            plot_data = eval(['joint_angle_data_list.trial' num2str(jj) '.' target_joint{ii} ';']);
            plot_trial_count = plot_trial_count+1;
            if length(plot_data) > max_frame_length
                max_frame_length = length(plot_data);
            end
         catch
            continue
         end
     end

     all_trial_data = NaN(trial_num, 1000); % the reason for setting the number to 1000 is meaningless.(any large number will do)
     trial_names = fieldnames(joint_angle_data_list);
     for jj = 1:trial_num
         trial_name = trial_names{jj};
         plot_data = eval(['joint_angle_data_list.' trial_name '.' target_joint{ii} ';']);
         all_trial_data(jj, 1:length(plot_data)) = plot_data;
     end

     % align all trials at the frame of the minimum angle
     min_values = min(all_trial_data, [], 2);
     aligned_all_trial_data = NaN(trial_num, 1000);
     for jj = 1:trial_num
         [~, min_idx] = min(all_trial_data(jj,:));
         shift_amount = round(max_frame_length / 2) - min_idx;
         aligned_all_trial_data(jj, :) = circshift(all_trial_data(jj, :), [0, shift_amount]);
     end
    
     % trim data by following plot_range
     min_value_idx = max_frame_length / 2 ;
     start_idx = (min_value_idx+plot_range(1))+1;
     end_idx = min_value_idx+plot_range(2);
     trimmed_aligned_all_trial_data = aligned_all_trial_data(:, start_idx:end_idx);
     eval(['save_stack_data.' target_joint{ii} ' = aligned_all_trial_data(:, start_idx:end_idx);']);
     x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1));
    
     % plot figure
     for jj = 1:length(fig_name_list)
         fig_type = fig_name_list{jj};
         eval(['figure(fig_str.' fig_type ')'])
         subplot(length(target_joint),1, ii);
         switch fig_type
             case 'stack'
                 for kk = 1:plot_trial_count
                     plot(x, trimmed_aligned_all_trial_data(kk, :))
                     hold on;
                 end
             case 'std'
                 mean_data = nanmean(trimmed_aligned_all_trial_data);
                 eval(['save_std_data.' target_joint{ii} ' = nanmean(trimmed_aligned_all_trial_data);'])
                 std_data = nanstd(trimmed_aligned_all_trial_data);
                 ar1=area(x, transpose([mean_data-std_data;std_data+std_data]));
                 set(ar1(1),'FaceColor','None','LineStyle',':','EdgeColor','r')
                 set(ar1(2),'FaceColor','r','FaceAlpha',0.2,'LineStyle',':','EdgeColor','r') 
                 hold on;
                 plot(x, mean_data, 'LineWidth',1.5, 'Color','b')
         end
        % decoration
        grid on;
        xlabel('elapsed time(frame)', 'FontSize',15);
        ylabel('joint angle(degree)', 'FontSize', 15);
        title([target_joint{ii} ' joint angle'], 'FontSize',15)
        hold off
     end
 end

 %% save data & figure
% save data
save_data_location = 'save_data';
data_type = 'trimmed_joint_angle';
window_size = [num2str(plot_range(1)) '_to_' num2str(plot_range(2)) '(frames)'];
save_data_fold_path = fullfile(pwd, save_data_location, data_type, window_size, ref_day);
for ii = 1:length(fig_name_list)
     fig_type = fig_name_list{ii};
     if not(exist(save_data_fold_path))
         mkdir(save_data_fold_path);
     end
     eval(['trimmed_joint_angle_data = save_' fig_type '_data;'])
     save(fullfile(save_data_fold_path, ['trimmed_joint_angle_data(' fig_type ').mat']), 'trimmed_joint_angle_data', 'target_joint');
end

 % save figure
save_fig_fold = 'save_figure';
analysis_type = 'joint_angle';
specific_name = 'each_days';
save_fig_fold_path = fullfile(pwd, save_fig_fold, analysis_type, specific_name);
for ii = 1:length(fig_name_list)
     fig_type = fig_name_list{ii};
     eval(['figure(fig_str.' fig_type ')'])
     if not(exist(fullfile(save_fig_fold_path, ref_day)))
        mkdir(fullfile(save_fig_fold_path, ref_day));
    end
     saveas(gcf, fullfile(save_fig_fold_path, ref_day, ['joint_angle_figure(' fig_type ').fig']))
     saveas(gcf, fullfile(save_fig_fold_path, ref_day, ['joint_angle_figure(' fig_type ').png']))
end
 close all;
end

% MPの最小値で合わせる
% wristも最小値で合わせる

