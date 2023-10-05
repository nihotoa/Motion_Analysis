function [] = each_plot(joint_angle_data_list, target_joint, ref_day, plot_range, trial_ratio_threshold)
% make figures
 fig_str = struct();
 fig_str.stack = figure('Position',[100 100 1200 600]);
 fig_str.std = figure('Position',[0 0 1200 600]);
 fig_name_list = {'stack', 'std'};

 trimmed_aligned_all_trial_data = struct();
 for ii = 1:length(target_joint) % main(focused) data
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
     
     % Shift 'main_joint' data to align at minimum joint angle
     shift_amount_list = zeros(plot_trial_count, 1);
     [trimmed_aligned_all_trial_data,save_stack_data,x,shift_amount_list] = align_data(trial_num, joint_angle_data_list,target_joint, ii, max_frame_length,plot_range, trimmed_aligned_all_trial_data, shift_amount_list, 'main');
     % Shift 'sub_joint' data to align at minimum joint angle of main_joint
     for kk = 1:length(target_joint)
         if kk == ii %if kk(sub_idx) is ii(main_idx) -> continue
             continue
         else
             [trimmed_aligned_all_trial_data,save_stack_data,x] = align_data(trial_num, joint_angle_data_list,target_joint, ii, max_frame_length,plot_range, trimmed_aligned_all_trial_data, shift_amount_list,'sub',kk);
         end
     end

     % plot figure
     for jj = 1:length(fig_name_list) %'stack'/std''
         for kk = 1:length(target_joint) %main & sub
             fig_type = fig_name_list{jj};
             eval(['figure(fig_str.' fig_type ')'])
             subplot(length(target_joint),length(target_joint), length(target_joint)*(kk-1)+ii);
             ref_data = eval(['trimmed_aligned_all_trial_data.main_' target_joint{ii} '.' target_joint{kk}]);
             switch fig_type
                 case 'stack'
                     for ll = 1:plot_trial_count
                         plot(x, ref_data(ll, :))
                         hold on;
                     end
                 case 'std'
                     mean_data = nanmean(ref_data);
                     eval(['save_std_data.' target_joint{ii} ' = nanmean(ref_data);']) 
                     std_data = nanstd(ref_data);
                     if exist('trial_ratio_threshold') % contain 'trial_ratio_threshold'
                         % if the number of trials in not enough,  make it a
                         % NaN value
                         min_trial_num = round(plot_trial_count * trial_ratio_threshold);
                         each_frame_trials = sum(~isnan(ref_data));
                         mean_data(find(each_frame_trials < min_trial_num)) = NaN;
                         std_data(find(each_frame_trials < min_trial_num)) = NaN;
                         eval(['save_std_data.' target_joint{ii} ' = mean_data;'])
                     end
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
            additional_str = '';
            if ii==kk %if ref_data is the data from focused_angle
                additional_str = '(main)';
                xline(0,'red' ,'LineWidth',1.5)
            end
            title([target_joint{kk} ' joint angle' additional_str], 'FontSize',15)
            hold off
         end
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
     switch fig_type
         case 'stack'
            save(fullfile(save_data_fold_path, ['trimmed_joint_angle_data(' fig_type ').mat']), 'trimmed_joint_angle_data', 'target_joint');
         case 'std'
             if exist('trial_ratio_threshold')
                 save(fullfile(save_data_fold_path, ['trimmed_joint_angle_data(' fig_type ')_ratio_above_' num2str(trial_ratio_threshold) '.mat']), 'trimmed_joint_angle_data', 'target_joint');
             else
                 save(fullfile(save_data_fold_path, ['trimmed_joint_angle_data(' fig_type ').mat']), 'trimmed_joint_angle_data', 'target_joint');
             end
     end
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

     add_str = '';
     if and(strcmp(fig_type, 'std'), exist('trial_ratio_threshold'))
         add_str = ['_ratio_above_' num2str(trial_ratio_threshold)];
     end
     saveas(gcf, fullfile(save_fig_fold_path, ref_day, ['joint_angle_figure(' fig_type ')' add_str '.fig']))
     saveas(gcf, fullfile(save_fig_fold_path, ref_day, ['joint_angle_figure(' fig_type ')' add_str '.png']))
end
 close all;
end

%% define local function
function [trimmed_aligned_all_trial_data,save_stack_data,x,shift_amount_list] = align_data(trial_num, joint_angle_data_list,target_joint, ii, max_frame_length,plot_range, trimmed_aligned_all_trial_data, shift_amount_list, data_type,kk)
 switch data_type
     case 'main'
         main_idx = ii;
         sub_idx = ii;
     case 'sub'
         main_idx = ii;
         sub_idx = kk;
 end
 all_trial_data = NaN(trial_num, 1000); % the reason for setting the number to 1000 is meaningless.(any large number will do)
 trial_names = fieldnames(joint_angle_data_list);
 %メインのデータを格納していく
 for jj = 1:trial_num
     trial_name = trial_names{jj};
     plot_data = eval(['joint_angle_data_list.' trial_name '.' target_joint{sub_idx} ';']);
     all_trial_data(jj, 1:length(plot_data)) = plot_data;
 end

 % align all trials at the frame of the minimum angle
 % mainのデータを最小値をとる場所でalignする
 aligned_all_trial_data = NaN(trial_num, 1000);
 %↓ここはmainとsubで異なる(shift_amountを計算するところと格納するところ)
 for jj = 1:trial_num
     switch data_type
         case 'main'
             [~, min_idx] = min(all_trial_data(jj,:));
             shift_amount = round(max_frame_length / 2) - min_idx;
             shift_amount_list(jj) = shift_amount;
             aligned_all_trial_data(jj, :) = circshift(all_trial_data(jj, :), [0, shift_amount]);
         case 'sub'
             shift_amount = shift_amount_list(jj);
             aligned_all_trial_data(jj, :) = circshift(all_trial_data(jj, :), [0, shift_amount]);
     end
 end

 % trim data by following plot_range
 min_value_idx = max_frame_length / 2 ;
 start_idx = (min_value_idx+plot_range(1))+1;
 end_idx = min_value_idx+plot_range(2);
 eval(['trimmed_aligned_all_trial_data.main_' target_joint{main_idx} '.' target_joint{sub_idx} ' = aligned_all_trial_data(:, start_idx:end_idx);']); %plot用のデータ
 eval(['save_stack_data.main_' target_joint{main_idx} '.' target_joint{sub_idx} ' = aligned_all_trial_data(:, start_idx:end_idx);']); %セーブ用のデータ 
 x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1));
end


