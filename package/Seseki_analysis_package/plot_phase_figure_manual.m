%{
%}
function [] = plot_phase_figure_manual(ref_term_data, target_joint, elapsed_date_list, phase_elapsed_date_list, post_first_elapsed_date, extract_image_type, save_figure_fold_path, diff_end_frame, linear_regression_plot, estimate_order)
% grouping by whether or not it belogs to 'phase_elapsed_date_list'
[not_phase_elapsed_date_list, not_phase_id] = setdiff(elapsed_date_list, phase_elapsed_date_list);
phase_id = setdiff(1:length(elapsed_date_list), not_phase_id);

target_joint_num = length(target_joint);
figure('Position',[100 100 600 300 * target_joint_num]);

% make figure
for target_joint_id = 1:target_joint_num
    ref_joint_data = ref_term_data.(target_joint{target_joint_id});
    subplot(target_joint_num, 1, target_joint_id)

    % plot 
    hold on
    %{
    plot(elapsed_date_list, ref_joint_data.mean, 'Color', 'blue', 'LineWidth',1.2);
    hold on;
    errorbar(elapsed_date_list, ref_joint_data.mean, ref_joint_data.std, 'o', 'Color', 'blue', 'LineWidth',1.2)
    %}
    errorbar(elapsed_date_list, ref_joint_data.mean, ref_joint_data.std, 'Color', 'blue', 'LineWidth',1.2)
    hold on;
    plot(phase_elapsed_date_list, ref_joint_data.mean(phase_id), 'o', 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'red', 'LineWidth',1.2)
    xline(phase_elapsed_date_list, '--', 'Color', 'red', 'LineWidth',1.2)
    plot(not_phase_elapsed_date_list, ref_joint_data.mean(not_phase_id), 'o', 'MarkerFaceColor', 'blue', 'MarkerEdgeColor', 'blue', 'LineWidth',1.2)
    % estimate and draw regression function
    if linear_regression_plot == 1
        % prepare explanatory variable & response variable
        y_data = transpose(ref_joint_data.mean);
        offset_elapsed_data_list = elapsed_date_list - elapsed_date_list(1);
        function_string_list = {'x: elapsed date from Phase A', 'y: joint angle', ''};
        colors = {'green',  'magenta', 'cyan', 'red'};

        %perform polynominal regression by following estimate order
        for order_reg_func_idx = 1:estimate_order
            % parepare matrix
            x_data = zeros(length(y_data), order_reg_func_idx+1);
            x_data(:, 1) = 1;
            
            for order_idx = 1:order_reg_func_idx
                x_data(:, order_idx+1) = transpose(power(offset_elapsed_data_list, order_idx));
            end
            estimated_param = pinv(x_data) * y_data;
            string_element = {};
            for param_id = 1:length(estimated_param)
                param_value = round(estimated_param(param_id), 2);
                if param_id==1
                    string_element{end+1} = [num2str(param_value)];
                elseif param_id == 2
                    string_element{end+1} = [num2str(param_value) 'x'];
                else
                    string_element{end+1} = [num2str(param_value) 'x^' num2str(param_id-1)];
                end
            end
            estimated_y = x_data * estimated_param;
            
            % plot estimated function
            use_color_idx = mod(order_reg_func_idx-1, length(colors)) + 1;
            plot(elapsed_date_list, estimated_y, 'LineWidth',1.2, 'Color', colors{use_color_idx});
            
            ref_string = strjoin(string_element(end:-1:1), '+');
            ref_string = strrep(ref_string, '+-', '-');

            function_string_list{end+1} = ['y=' ref_string];
        end
    end

    % decoration
    xlim([elapsed_date_list(1) elapsed_date_list(end)]);
    xlabel('elapsed date from TT[day]')
    grid on;
    
    max_value = max(ref_joint_data.mean + ref_joint_data.std);
    min_value = min(ref_joint_data.mean- ref_joint_data.std);
    upper_lim = ceil(max_value / 10) * 10;  
    lower_lim = floor(min_value / 10) * 10;
    
    % make square to hide blank term
    square_coordination = [0 lower_lim, post_first_elapsed_date - 1, (upper_lim-lower_lim)];
    rectangle('Position', square_coordination, 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
    ylim([lower_lim upper_lim]);
    title([target_joint{target_joint_id} ' joint angle'], 'FontSize',15)

    % add text to explain estimated function
    x_criterion = elapsed_date_list(4); % phase D

    % ハードコーディング
    if target_joint_id== 1
        y_criterion = lower_lim + 14;
    elseif target_joint_id==2
        y_criterion = upper_lim - 5;
    end
    for line_idx = 1:length(function_string_list)
        if line_idx >= 4
            % explanation of function
            use_color_idx = mod(line_idx - 4, length(colors)) + 1;
            text(x_criterion, y_criterion - (line_idx-1)*3, function_string_list{line_idx}, 'Color', colors{use_color_idx})
        else
            % explanation of x-axis, y-axis or blank
            text(x_criterion, y_criterion - (line_idx-1)*3, function_string_list{line_idx})
        end
    end
    hold off;
    hold off;
end

switch extract_image_type
    case 'manual'
        sgtitle(['manual timing joint angle' ' (extensor-plus)'], 'Interpreter', 'none', fontsize=20)
    case 'auto'
        sgtitle(['diff_end_' num2str(diff_end_frame) '_frame timing joint angle' ' (extensor-plus)'], 'Interpreter', 'none', fontsize=20)
end

% save
figure_file_name = 'transition of joint angle';
makefold(save_figure_fold_path)
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.png']))
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.fig']))
close all;

end