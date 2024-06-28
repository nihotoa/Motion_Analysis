%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
calculate the joint angle with using inputed coodination data
this function use image coordination data obtained from DeepLabCut

[input & ouput]
input: input_data(type:string) -> this is created in
seseki_MotionAnalysis.m
output: target_joints(type:cell) output_data: contains calculated joint
angle data(type:double) -> (+) flexor, (-) extensor
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [target_joints, output_data] = calc_joint_angle(input_data, likelyhood_threshold, plus_direction)
body_parts = input_data.body_parts;
target_joints = body_parts(2:end-1);
coodination_data = input_data.coodination_data;

%% change value into 'NaN' if not satisfied with threshold
body_parts_num = length(body_parts);
for body_parts_idx = 1: body_parts_num
    ref_likelyhood = coodination_data(:, 3*body_parts_idx);
    for frame_idx = 1:length(ref_likelyhood)
        if ref_likelyhood(frame_idx) < likelyhood_threshold
            coodination_data(frame_idx, 3*body_parts_idx-2:3*body_parts_idx-1) = NaN;
        end
    end
end

%% calcurate  the angle of each joint
% Creating a data structure to store output information
output_data = struct();

for target_joint_idx = 2:length(body_parts)-1
    % extrart each joint angle data(only extract necessary joint angle (3 joint))
    prev_joint_x_idx = 3*(target_joint_idx-2)+1;
    ref_joint_x_idx = 3*(target_joint_idx-1)+1;
    next_joint_x_idx = 3*(target_joint_idx)+1;

    % obrain (x, y) coodinates from 3 points which is needed for calcurating joint angle
    prev_joint_data = coodination_data(:, prev_joint_x_idx:prev_joint_x_idx+1);
    ref_joint_data = coodination_data(:, ref_joint_x_idx:ref_joint_x_idx+1);
    next_joint_data = coodination_data(:, next_joint_x_idx:next_joint_x_idx+1);

    % create the vector
    next_to_ref_vector_list = ref_joint_data - next_joint_data;
    ref_to_prev_vector_list = prev_joint_data - ref_joint_data;

    % calcurate the joint angle from each frame
    [frame_num, ~] = size(coodination_data);
    output_data.(body_parts{target_joint_idx}) = zeros(frame_num, 1);

    for frame_idx = 1:frame_num
        next_to_ref_vector =  next_to_ref_vector_list(frame_idx, :);
        ref_to_prev_vector = ref_to_prev_vector_list(frame_idx, :);

        % calc angle and determine the rotate direction(flexor or extensor)
        next_to_ref_unit_vector = (next_to_ref_vector / norm(next_to_ref_vector));
        ref_to_prev_unit_vector = (ref_to_prev_vector / norm(ref_to_prev_vector));
        
        % assign x, y component of unit vector in each variable
        x_component = next_to_ref_unit_vector(1);
        y_component = next_to_ref_unit_vector(2);
        vs_x_angle = acos(x_component); % For rotation of coordinates, express in radian

        %% Determining the direction of rotation (Please note that the y-axis points downwards)

        % determine in which direction the unit vector of 'next_to_ref_vactor' shoud be rotated to make it a unit vector along the x axis([1, 0])
        if y_component < 0
            rotation_direction = 1;  % Turn in the + direction
        elseif y_component > 0
            rotation_direction = -1;  % Turn in the - direction
        elseif isnan(y_component) % In the case the value of marker point includes NaN value
            output_data.(body_parts{target_joint_idx})(frame_idx) = NaN;
            continue; 
        end

        theta = rotation_direction * vs_x_angle;
        % rotate coordinates
        Rotation_matrix = [ cos(theta), -1*sin(theta);
                                       sin(theta), cos(theta)];                      
        rotated_ref_to_prev_unit_vector = Rotation_matrix * ref_to_prev_unit_vector';

        rotated_x_component = rotated_ref_to_prev_unit_vector(1);
        rotated_y_component = rotated_ref_to_prev_unit_vector(2);
        angle =  (acos(rotated_x_component)) * (180/pi); %to confirm whether angle is correct

        if rotated_y_component > 0
            flag = 1;  % flexor(+)  
        elseif rotated_y_component < 0
            flag = -1; % extensor(-)
        end
        if strcmp(plus_direction, 'extensor')
            flag = -1 * flag;
        end
        angle = flag * angle;  % Consider extension and flexion
        % store the calculated data
        output_data.(body_parts{target_joint_idx})(frame_idx) = angle;
    end
end
end

