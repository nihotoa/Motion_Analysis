%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
calculate the joint angle with using inputed coodination data 
this function use image coordination data obtained from 'annotatedProgram.py'(python file)

[input & ouput]
input: input_data(type:string) -> this is created in
seseki_MotionAnalysis.m
output: target_joints(type:cell) output_data: contains calculated joint
angle data(type:double) -> (+) flexor, (-) extensor
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [target_joints, output_data] = calc_joint_angle_manual(input_data)
% unpack struct 
body_parts = input_data.body_parts;
target_joints = body_parts(2:end-1);
coordination_data = input_data.coordination_data;

%% calcurate  the angle of each joint
% Creating a data structure to store output information
output_data = struct();

for target_joint_idx = 2:length(body_parts)-1
    % extrart each joint angle data(only extract necessary joint angle (3 joint))
    prev_joint_x_idx = 2 * (target_joint_idx - 2) + 1;
    ref_joint_x_idx = 2 * (target_joint_idx - 1) + 1;
    next_joint_x_idx = 2 * (target_joint_idx) + 1;

    % obrain (x, y) coodinates from 3 points which is needed for calcurating joint angle
    prev_joint_data = coordination_data(:, prev_joint_x_idx:prev_joint_x_idx+1);
    ref_joint_data = coordination_data(:, ref_joint_x_idx:ref_joint_x_idx+1);
    next_joint_data = coordination_data(:, next_joint_x_idx:next_joint_x_idx+1);

    % create the vector
    next_to_ref_vector_list = ref_joint_data - next_joint_data;
    ref_to_prev_vector_list = prev_joint_data - ref_joint_data;

    % calcurate the joint angle from each frame
    [frame_num, ~] = size(coordination_data);
    output_data.(body_parts{target_joint_idx}) = zeros(frame_num, 1);

    for frame_idx = 1:frame_num
        next_to_ref_vector =  next_to_ref_vector_list(frame_idx, :);
        ref_to_prev_vector = ref_to_prev_vector_list(frame_idx, :);

        % find unit vector to simplify later calcuratioon
        next_to_ref_unit_vector = (next_to_ref_vector / norm(next_to_ref_vector));
        ref_to_prev_unit_vector = (ref_to_prev_vector / norm(ref_to_prev_vector));
        
        % assign x, y component of unit vector in each variable
        x_component = next_to_ref_unit_vector(1);
        y_component = next_to_ref_unit_vector(2);

        % find the angle of 'next_to_ref_unit_vector' with respect to x-axis of image coordination
        vs_x_angle = acos(x_component); 

        %% Determining the direction of rotation (Please note that the y-axis points downwards)
        % determine in which direction the unit vector of 'next_to_ref_vactor' shoud be rotated to make it a unit vector along the x axis([1, 0])
        if y_component < 0
            rotation_direction = 1;  % Turn in the + direction
        elseif y_component > 0
            rotation_direction = -1;  % Turn in the - direction
        end
        theta = rotation_direction * vs_x_angle; % unit is radian

        % rotate coordinates so that 'next_to_ref_vecotr' coincides with the unit vector in the x-axis direction [1 0]
        Rotation_matrix = [ cos(theta), -1*sin(theta);
                                       sin(theta), cos(theta)];                      
        rotated_ref_to_prev_unit_vector = Rotation_matrix * ref_to_prev_unit_vector';
        rotated_x_component = rotated_ref_to_prev_unit_vector(1);
        rotated_y_component = rotated_ref_to_prev_unit_vector(2);

        % calcurate joint angle with the x-axis (by degree)
        angle =  (acos(rotated_x_component)) * (180/pi); 
        if rotated_y_component > 0
            flag = -1;  % flexor(-)  
        elseif rotated_y_component < 0
            flag = 1; % extensor(+)
        end
        angle = flag * angle;  % Consider extension and flexion
        % store the calculated data
        output_data.(body_parts{target_joint_idx})(frame_idx) = angle;
    end
end
end