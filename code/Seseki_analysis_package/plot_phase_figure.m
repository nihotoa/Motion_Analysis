function [] = plot_phase_figure(ref_term_data, target_joint_num, elapsed_date_list, post_first_elapsed_date, target_joint, plus_direction, align_type, nanmean_type, calc_type_name, compare_phase_name)
% base setting
[row_num, col_num] = size(ref_term_data);
figure('Position',[0 0 1200 600]);

% make figure
for row_id = 1:row_num
    for col_id = 1:col_num
        ref_joint_data = ref_term_data{row_id, col_id};
        max_value = max(ref_joint_data);
        subplot_idx = target_joint_num * (row_id-1) + col_id;
        subplot(row_num, col_num, subplot_idx)
        
        % plot 
        hold on
        plot(elapsed_date_list, ref_joint_data, LineWidth=1.2);
        hold on;
        plot(elapsed_date_list, ref_joint_data, 'o');
    
        % decoration
        xlim([elapsed_date_list(1) elapsed_date_list(end)]);
        xlabel('elapsed date from TT[day]')
        grid on;

        % make square to hide blanc term
        if max_value > 0
            ylim_value =  max_value + (max_value * 0.1);
            square_coordination = [0 0, post_first_elapsed_date - 1, ylim_value];
            ylim_range = [0 ylim_value];
        else
            ylim_value = -90; % ほんとは計算でやるべき
            square_coordination = [0 ylim_value, post_first_elapsed_date - 1, -1 * ylim_value];
            ylim_range = [ylim_value 0];
        end

        rectangle('Position', square_coordination, 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
        ylim(ylim_range);
        additional_string = '';
        if row_id == col_id
            additional_string = ' (main)';
        end
        title([target_joint{row_id} ' joint angle' additional_string], 'FontSize',15)
        hold off;
        hold off;
    end
end

if exist('compare_phase_name', 'var')
    sgtitle([calc_type_name ' (', plus_direction '-plus, ' align_type '-align, ' compare_phase_name ')'], 'Interpreter', 'none', fontsize=20)
else
    sgtitle([calc_type_name ' (', plus_direction '-plus, ' align_type '-align)'], 'Interpreter', 'none', fontsize=20)
end

% save
switch nanmean_type
    case 'true'
        figure_file_name = [calc_type_name ' of joint angle(nanmean)'];
    case 'false'
      figure_file_name = [calc_type_name ' of joint angle'];  
end

save_figure_fold_path = fullfile(pwd, 'save_figure', calc_type_name, 'all_days', [plus_direction '-plus'], align_type);
if exist('compare_phase_name', 'var')
    save_figure_fold_path = fullfile(save_figure_fold_path, align_type); 
end
makefold(save_figure_fold_path)
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.png']))
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.fig']))
close all;
end

