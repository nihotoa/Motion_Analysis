%{
prepare necessary data array and label array for one-way anova
%}
function [value_struct, group_label, target_joint] = anovaPreparation(day_folders, common_joint_angle_path, group_type, designated_group, phase_labels)
if strcmp(group_type, 'designated_group')
    group_name_list = cell(length(designated_group), 1);
    for group_idx = 1:length(designated_group)
        phase_id_vector = designated_group{group_idx};
        if length(phase_id_vector) == 1
            group_name_list{group_idx} = phase_labels{phase_id_vector};
        else
            applicable_phase_name_list = phase_labels(phase_id_vector);
            unique_name_list = strrep(applicable_phase_name_list, 'Phase ', '');
            use_name_pairs = unique_name_list([1,length(unique_name_list)]);
            group_name_list{group_idx} = ['Phase ' strjoin(use_name_pairs, '_to_')];
        end
    end
end

value_struct = struct();
[elapsed_date_list] = makeElapsedDateList(day_folders, '200121');
for day_id = 1:length(day_folders)
    ref_joint_angle_data_path = fullfile(common_joint_angle_path, day_folders{day_id}, 'joint_angle_data.mat');
    load(ref_joint_angle_data_path, 'target_joint', 'joint_angle_data_list')
    for target_joint_id = 1:length(target_joint)
        if day_id==1
            % prepare empty array
            value_struct.(target_joint{target_joint_id}) = {};
            if target_joint_id == 1
                group_label = {};
            end
        end

        ref_data = joint_angle_data_list.(target_joint{target_joint_id});
        trial_num = length(ref_data);
        
        % assingn data & label
        if target_joint_id == 1
            assigned_date_flag = false;
            switch group_type
                case 'pre_post'
                    % assign data
                    value_struct.(target_joint{target_joint_id}){end+1, 1} = ref_data;
                    assigned_date_flag = true;

                    % assing label
                    if elapsed_date_list(day_id) < 0
                        group_label{day_id} = repmat({'pre'}, trial_num, 1);
                    else
                        group_label{day_id} = repmat({'post'}, trial_num, 1);
                    end
                case 'designated_group'
                    for group_id = 1:length(designated_group)
                        if ismember(day_id, designated_group{group_id})
                            assigned_group_id = group_id;
                            assigned_date_flag = true;
                            break;
                        end
                    end
                    if assigned_date_flag == 1
                        group_label{end+1} = repmat({group_name_list{assigned_group_id}}, trial_num, 1);
                        % assign data
                        value_struct.(target_joint{target_joint_id}){end+1, 1} = ref_data;
                    end
            end
        else
            if assigned_date_flag == 1
                value_struct.(target_joint{target_joint_id}){end+1, 1} = ref_data;
            end
        end

        % perform cell2mat
        if day_id == length(day_folders)
            value_struct.(target_joint{target_joint_id}) = cell2mat(value_struct.(target_joint{target_joint_id}));
            if target_joint_id == 1
                group_label = vertcat(group_label{:});
            end
        end
    end
end
end