%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
calculate the joint angle with using inputed coodination data

[input & ouput]
input: input_data(type:string) -> this is created in
seseki_MotionAnalysis.m
output: target_joints(type:cell) output_data: contains calculated joint
angle data(type:double) -> (+) flexor, (-) extensor
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [target_joints, output_data] = calc_joint_angle(input_data, likelyhood_threshold)
body_parts = input_data.body_parts;
target_joints = body_parts(2:end-1);
coodination_data = input_data.coodination_data;

% Excluding low coodinate values of likelyhood
body_parts_num = length(body_parts);
for ii = 1: body_parts_num
    ref_likelyhood = coodination_data(:, 3*ii);
    for jj = 1:length(ref_likelyhood)
        if ref_likelyhood(jj) < likelyhood_threshold
            coodination_data(jj, 3*ii-2:3*ii-1) = NaN;
        end
    end
end

% Creating a data structure to store output information
output_data = struct();
% calculate angle of each joint
for ii = 2:length(body_parts)-1
    % extrart each joint angle data(only extract necessary joint angle (3 joint))
    prev_joint_x_col = 3*(ii-2)+1;
    ref_joint_x_col = 3*(ii-1)+1;
    next_joint_x_col = 3*(ii)+1;
    prev_joint_data = coodination_data(:, prev_joint_x_col:prev_joint_x_col+1);
    ref_joint_data = coodination_data(:, ref_joint_x_col:ref_joint_x_col+1);
    next_joint_data = coodination_data(:, next_joint_x_col:next_joint_x_col+1);

    % create the vector
    next_to_ref_vector_list = ref_joint_data - next_joint_data;
    ref_to_prev_vector_list = prev_joint_data - ref_joint_data;

    % Calculate angle for each frame
    [frame_num, ~] = size(coodination_data);
    eval(['output_data.' body_parts{ii} ' = zeros(' num2str(frame_num) ',1);']);
    for jj = 1:frame_num
        next_to_ref_vector =  next_to_ref_vector_list(jj, :);
        ref_to_prev_vector = ref_to_prev_vector_list(jj, :);
%         % calc
%         inner_product = dot(next_to_ref_vector, ref_to_prev_vector);
%         a_norm = norm(ref_to_prev_vector);
%         b_norm = norm(next_to_ref_vector);
%         angle = (acos(inner_product/(a_norm*b_norm))) * (180/pi);  % Convert from radians to degrees

        % calc angle and determine the rorate direction(flexor or extensor)
        x_unit_vector = [1 0];
        next_to_ref_unit_vector = (next_to_ref_vector / norm(next_to_ref_vector));
        ref_to_prev_unit_vector = (ref_to_prev_vector / norm(ref_to_prev_vector));
        vs_x_angle = acos(next_to_ref_unit_vector(1)); % For rotation of coordinates, express in radian

        %Determining the direction of rotation (Please note that the y-axis points downwards)
        if next_to_ref_unit_vector(2) < 0
            rotation_direction = 1;  % Turn in the + direction
        elseif next_to_ref_unit_vector(2) > 0
            rotation_direction = -1;  % Turn in the - direction
        end
        theta = rotation_direction * vs_x_angle;
        % rotate coordinates
        Rotation_matrix = [ cos(theta), -1*sin(theta);
                                       sin(theta), cos(theta)];                      

        rotated_ref_to_prev_unit_vector = Rotation_matrix * ref_to_prev_unit_vector';
        angle =  (acos(rotated_ref_to_prev_unit_vector(1))) * (180/pi); %to confirm whether angle is correct

        if rotated_ref_to_prev_unit_vector(2) > 0
                flag = 1;  % flexor(+)  
        elseif rotated_ref_to_prev_unit_vector(2) < 0
               flag = -1; %extensor(-)
        end
        angle = flag * angle;  % Consider extension and flexion
        % store the calculated data
        eval(['output_data.' body_parts{ii} '(' num2str(jj) ') = angle;'])
    end
end
end

