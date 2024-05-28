%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
・冗長

[注意点]
・flex-plusのminとextensor-plusのmaxはy軸対象であり、同じ情報を示していることに留意する

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = each_plot(joint_angle_data_list, target_joint, ref_day, plot_range, align_type, plus_direction, trial_ratio_threshold)
% make figures
 fig_str = struct();
 fig_str.stack = figure('Position',[100 100 1200 600]);
 fig_str.mean = figure('Position',[0 0 1200 600]);
 fig_name_list = {'stack', 'mean'};

 % make empty structure
 trimmed_aligned_all_trial_data = struct();
 frame_idx_list = struct();
 target_joint_num = length(target_joint);

 for main_joint_idx = 1:target_joint_num 
     trial_num = numel(fieldnames(joint_angle_data_list));
     plot_trial_count = 0; %how many trials be plotted (some trial file are gabbage file and therefore don't have joint angle)
     max_frame_length = 0; % this is used to align  
     % search the maximum frames of all trials & plot_trial_count
     for trial_id = 1:trial_num
         try
            plot_data = joint_angle_data_list.(['trial' num2str(trial_id)]).(target_joint{main_joint_idx});
            plot_trial_count = plot_trial_count+1;
            if length(plot_data) > max_frame_length
                max_frame_length = length(plot_data);
            end
         catch
            continue
         end
     end
     
     % Shift 'main_joint' data to align at minimum (or maximum)joint angle
     shift_amount_list = zeros(plot_trial_count, 1);
     if not(exist('save_stack_data', 'var'))
         save_stack_data = struct();
     end
     [trimmed_aligned_all_trial_data,shift_amount_list,x,save_stack_data, extremum_value_idx_list] = align_data(trial_num, joint_angle_data_list, target_joint, main_joint_idx, max_frame_length, align_type, plot_range, trimmed_aligned_all_trial_data, shift_amount_list, 'main', save_stack_data);
     frame_idx_list.([target_joint{main_joint_idx} '_main']) = extremum_value_idx_list;

     % Shift 'sub_joint' data to align at minimum(or maximum) joint angle of main_joint
     for sub_joint_idx = 1:target_joint_num
         if sub_joint_idx == main_joint_idx %if sub_joint_idx(shifted_joint_data_idx) is main_joint_idx(main_idx) -> continue
             continue
         else
             [trimmed_aligned_all_trial_data, shift_amount_list, x,save_stack_data] = align_data(trial_num, joint_angle_data_list,target_joint, main_joint_idx, max_frame_length, align_type, plot_range, trimmed_aligned_all_trial_data, shift_amount_list,'sub',save_stack_data, sub_joint_idx);
         end
     end

     % plot figure
     for fig_name_id = 1:length(fig_name_list) %'stack'/mean''
         for sub_joint_idx = 1:target_joint_num %main & sub
             fig_type = fig_name_list{fig_name_id};

             figure(fig_str.(fig_type));
             row_id = sub_joint_idx;
             col_id = main_joint_idx;
             subplot(target_joint_num, target_joint_num, target_joint_num*(row_id - 1) + col_id);
             ref_joint_data = trimmed_aligned_all_trial_data.(['main_' target_joint{main_joint_idx}]).(target_joint{sub_joint_idx});
             switch fig_type
                 case 'stack'
                     for ll = 1:plot_trial_count
                         plot(x, ref_joint_data(ll, :))
                         hold on;
                     end
                 case 'mean'
                     mean_data = nanmean(ref_joint_data);
                     std_data = nanstd(ref_joint_data);
                     % change value to 'NaN' if not satisfied with 'trial_ration_threshold'
                     if exist('trial_ratio_threshold', 'var') % contain 'trial_ratio_threshold'
                         trial_num_threshold = round(plot_trial_count * trial_ratio_threshold);
                         each_frame_trials = sum(~isnan(ref_joint_data));
                         mean_data(each_frame_trials < trial_num_threshold) = NaN;
                         std_data(each_frame_trials < trial_num_threshold) = NaN;
                     end
                     save_mean_data.(['main_' target_joint{main_joint_idx}]).(target_joint{sub_joint_idx}) = mean_data;
                     % decoration(plot backgrouond accoring to std value)
                     ar1=area(x, transpose([mean_data - std_data; std_data + std_data]));
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
            if main_joint_idx==sub_joint_idx %if ref_joint_data is the data from focused_angle
                additional_str = '(main)';
                xline(0,'red' ,'LineWidth',1.5)
            end
            title([target_joint{sub_joint_idx} ' joint angle' additional_str], 'FontSize',15)
            hold off
         end
     end
 end

 % sgtitle
 for fig_name_id = 1:length(fig_name_list)
    figure(fig_str.(fig_name_list{fig_name_id}));
    sgtitle([plus_direction '-plus, ' align_type '-align, ' ref_day], fontsize=20)
 end

 %% save data & figure
 common_save_data_fold_path = fullfile(pwd, 'save_data');

% save joint angle data
save_data_fold_path = fullfile(common_save_data_fold_path, 'trimmed_joint_angle',  [plus_direction '-plus'], align_type, [num2str(plot_range(1)) '_to_' num2str(plot_range(2)) '(frames)']);
for fig_idx = 1:length(fig_name_list)
     fig_type = fig_name_list{fig_idx};
     eval(['trimmed_joint_angle_data = save_' fig_type '_data;'])
     save_file_name = 'trimmed_joint_angle_data.mat';
     if strcmp(fig_type, 'mean')
        if exist('trial_num_threshold', 'var')
            save_file_name =  ['trimmed_joint_angle_data(ratio_threshold=' num2str(trial_ratio_threshold) ').mat'];
        else
            fig_type = 'nanmean';
        end
     end
     final_version_path = fullfile(save_data_fold_path, fig_type, ref_day);
     makefold(final_version_path);
     save(fullfile(final_version_path, save_file_name), 'trimmed_joint_angle_data', 'target_joint')
end

% save_minimum(or maximum)_angle_idx
save_data_fold_path = fullfile(common_save_data_fold_path, 'frame_idx', [plus_direction '-plus'], align_type, ref_day);
makefold(save_data_fold_path)
save(fullfile(save_data_fold_path, 'frame_idx_list'), 'frame_idx_list', 'target_joint')

 % save figure
save_fig_fold_path = fullfile(pwd, 'save_figure', 'joint_angle', 'each_days', [plus_direction '-plus'], align_type);
for fig_idx = 1:length(fig_name_list)
     fig_type = fig_name_list{fig_idx};
     figure(fig_str.(fig_type))
     add_str = '';
      if strcmp(fig_type, 'mean')
          if exist('trial_ratio_threshold', 'var')
              add_str = ['_ratio_above_' num2str(trial_ratio_threshold)];
          else
              fig_type = 'nanmean';
          end
     end
     makefold(fullfile(save_fig_fold_path, fig_type, ref_day));
     saveas(gcf, fullfile(save_fig_fold_path, fig_type, ref_day, ['joint_angle_figure' add_str '.fig']))
     saveas(gcf, fullfile(save_fig_fold_path, fig_type, ref_day, ['joint_angle_figure' add_str '.png']))
end
close all;
end

%% define local function
function [trimmed_aligned_all_trial_data, shift_amount_list, x, save_stack_data, extremum_value_idx_list] = align_data(trial_num, joint_angle_data_list,target_joint, main_joint_idx, max_frame_length, align_type, plot_range, trimmed_aligned_all_trial_data, shift_amount_list, data_type, save_stack_data, sub_joint_idx)
 switch data_type
     case 'main'
         main_idx = main_joint_idx;
         shifted_joint_data_idx = main_joint_idx;
     case 'sub'
         main_idx = main_joint_idx;
         shifted_joint_data_idx = sub_joint_idx;
 end

 all_trial_data = NaN(trial_num, 1000); % the reason for setting the number to 1000 is meaningless.(any large number will be ok)
 trial_names = fieldnames(joint_angle_data_list);
 % store the joint angle data of each trial(left aligned)
 for trial_id = 1:trial_num
     trial_name = trial_names{trial_id};
     plot_data = joint_angle_data_list.(trial_name).(target_joint{shifted_joint_data_idx});
     all_trial_data(trial_id, 1:length(plot_data)) = plot_data;
 end

 % align all trials at the frame of the minimum(or maximum) angle
 aligned_all_trial_data = NaN(trial_num, 1000);
 %↓ここはmainとsubで異なる(shift_amountを計算するところと格納するところ)
 extremum_value_idx_list = zeros(trial_num,1);
 for trial_id = 1:trial_num
     switch data_type
         case 'main'
             switch align_type
                 case 'minimum'
                    [~, ref_idx] = min(all_trial_data(trial_id,:));
                 case 'maximum'
                     [~, ref_idx] = max(all_trial_data(trial_id,:));
             end
             extremum_value_idx_list(trial_id) = ref_idx;
             shift_amount = round(max_frame_length / 2) - ref_idx;
             shift_amount_list(trial_id) = shift_amount;
         case 'sub'
             shift_amount = shift_amount_list(trial_id);
     end
     aligned_all_trial_data(trial_id, :) = circshift(all_trial_data(trial_id, :), [0, shift_amount]);
 end

 % trim data by following plot_range
 extremum_value_idx = max_frame_length / 2 ;
 start_idx = (extremum_value_idx+plot_range(1))+1;
 end_idx = extremum_value_idx+plot_range(2);
 trimmed_aligned_all_trial_data.(['main_' target_joint{main_idx}]).(target_joint{shifted_joint_data_idx}) = aligned_all_trial_data(:, start_idx:end_idx);
 save_stack_data.(['main_' target_joint{main_idx}]).(target_joint{shifted_joint_data_idx}) = aligned_all_trial_data(:, start_idx:end_idx);
 x = linspace(plot_range(1), plot_range(2), plot_range(2)-plot_range(1));
end


