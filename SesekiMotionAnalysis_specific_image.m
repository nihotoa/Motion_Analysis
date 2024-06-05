%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[改善点]
post_first_elapsed_dateが20になっているので、変更する
path設定が汚すぎ
save_dataのautoの階層構造がデータによって違う
向き => 日付 => フレーム前   で統一する
(データ参照のpathが変わりそうでめんどいから保留してる)

[注意点] 
annotationのプログラムはpythonで作った
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Se'; 
real_name = 'Seseki';

% please select the analysis which you want to perform
extract_image = false;
process_image = false; 
joint_angle_calculation = false;
create_joint_angle_diagram = true;

extract_image_type = 'manual'; % 'manual' / 'auto'
diff_end_frame = 60;
plus_direction = 'extensor';
video_type = '.avi'; % 読み込み対象の動画の拡張子
trial_num = 20; % if you want to pick up image for all trial, please set 'NaN'
image_type = '.png';
montage_numToPick = 9;
image_row_num = 3;
overlay_numToPick = NaN; % if you want to use all trial images, please set 'NaN'

%% code section
% generates the data necessary for general motion analysis.
disp('Please select the folder containing Seseki movie (Motion_analysis -> seseki_movie)')
common_movie_path = uigetdir();
if common_movie_path == 0
    error('user pressed cancel.');
end

% get the information of movie directory name
disp('Please select movie folder which you want to perform analysis')
movie_fold_names = uiselect(dirdir(common_movie_path),1,'Please select folders which contains the data you want to analyze');
day_folders = extract_num_part(movie_fold_names);

% setting path (to refer data and save data)
switch extract_image_type
    case 'manual'
        common_save_figure_fold_path = fullfile(pwd, 'save_figure', 'specific_images', 'manual');
        common_save_data_fold_path = fullfile(pwd, 'save_data', 'manual', 'diff_end_frame');
        common_coordination_data_path = fullfile(pwd, 'save_data', 'manual', 'coordination_data');
        common_joint_angle_path = fullfile(pwd, 'save_data', 'manual', 'joint_angle', [plus_direction '-plus']);   
        common_save_transition_figure_fold_path = fullfile(pwd, 'save_figure', 'transition_joint_angle', [plus_direction '-plus'], 'manual');
    case 'auto'
        common_save_figure_fold_path = fullfile(pwd, 'save_figure', 'specific_images', 'auto', ['diff_end_' num2str(diff_end_frame) '_frame']);
        common_coordination_data_path = fullfile(pwd, 'save_data', 'auto', 'coordination_data', ['diff_end_' num2str(diff_end_frame) '_frame']);
        common_joint_angle_path = fullfile(pwd, 'save_data', 'auto', 'joint_angle', [plus_direction '-plus'], ['diff_end_' num2str(diff_end_frame) '_frame']);    
        common_save_transition_figure_fold_path = fullfile(pwd, 'save_figure', 'transition_joint_angle', [plus_direction '-plus'], 'auto', ['diff_end_' num2str(diff_end_frame) '_frame']);
end

for day_id = 1:length(day_folders)
    % get movie information
    ref_movie_fold_path = fullfile(common_movie_path, movie_fold_names{day_id});
    ref_movie_file_list = dirEx(ref_movie_fold_path, [], video_type);
    if isnan(trial_num)
        trial_num = length(ref_movie_file_list);
    end

    %% extract specific images for each trial by GUI opearation
    if extract_image == 1
        % path setting
        save_figure_fold_path = fullfile(common_save_figure_fold_path, day_folders{day_id});
        makefold(save_figure_fold_path);
        if strcmp(extract_image_type, 'manual')
            save_data_folder_path = fullfile(common_save_data_fold_path, day_folders{day_id});
            makefold(save_data_folder_path);
            diff_end_frame_list = zeros(trial_num, 1);
        end

        for trial_id = 1:trial_num
            save_figure_name = ['trial' sprintf('%03d', trial_id)];
            ref_trial_movie_path = fullfile(ref_movie_fold_path, ref_movie_file_list(trial_id).name);
            
            switch extract_image_type
                case 'manual'
                    % operate each image by GUI operation & save_figure
                    diff_end_frame = avi_frame_by_frame_viewer(ref_trial_movie_path, save_figure_fold_path, save_figure_name, image_type);
                    diff_end_frame_list(trial_id) = diff_end_frame;
                case 'auto'
                    auto_save_image(ref_trial_movie_path, diff_end_frame, save_figure_fold_path, save_figure_name, image_type)
            end
        end

        % save diff_end_frame(if you exract image as manual operation)
        if strcmp(extract_image_type, 'manual')
            % save_diff_end_frame
            save(fullfile(save_data_folder_path, 'diff_end_frame.mat'), "diff_end_frame_list");
        end
    end
    
    %% create montage & overlay figure with using images extracted by analysis of one previous section
    if process_image == 1
        save_figure_fold_path = fullfile(common_save_figure_fold_path, day_folders{day_id});
        candidate_images = getfileName(save_figure_fold_path, ['trial*' image_type]); %作成した図を読み込まないように接頭語のtrialを追加する

        % create montage figure
        image_num = length(candidate_images);
        randomIntegers = sort(datasample(1:image_num, montage_numToPick, 'Replace', false));
        image_col_num = ceil(montage_numToPick / image_row_num);
        plot_images = cell(image_row_num, image_col_num); 
        for image_id = 1:montage_numToPick
            plot_images{image_id} = imread(fullfile(save_figure_fold_path,candidate_images{randomIntegers(image_id)}));
        end
        % montageを表示
        montage(plot_images, 'Size', [image_row_num, image_col_num]); 
        switch extract_image_type
            case 'manual'
                title([day_folders{day_id} '-manual'], 'FontSize',22)
            case 'auto'
                title([day_folders{day_id} '-(diff_end_frame=' num2str(diff_end_frame) ')'], 'Interpreter', 'none', 'FontSize', 22)
        end
        montage_fig = gcf;

        % create overlay figure
        if isnan(overlay_numToPick)
            overlay_numToPick = image_num;
        end
        randomIntegers = sort(datasample(1:image_num, overlay_numToPick, 'Replace', false));
        image_data = imread(fullfile(save_figure_fold_path,candidate_images{randomIntegers(1)}));
        result = im2double(image_data);
        for image_id = 2:overlay_numToPick
            image_file_path = fullfile(save_figure_fold_path,candidate_images{randomIntegers(image_id)});
            image_data = imread(image_file_path);
            result = result + im2double(image_data); 
        end        
        
        % average
        average_images = result / overlay_numToPick;

        % display overlay figure
        overlay_figure = figure();
        imshow(average_images);
        set(overlay_figure, 'Position', [100, 100, 1200, 1000]);

        switch extract_image_type
            case 'manual'
                title([day_folders{day_id} '-manual(' num2str(overlay_numToPick) ' trial)'], 'FontSize',22)
            case 'auto'
                title([day_folders{day_id} '-(diff_end_frame=' num2str(diff_end_frame) ')_(' num2str(overlay_numToPick) ' trial)'], 'Interpreter', 'none', 'FontSize', 22)
        end
        

        % fsave figure
        figure(montage_fig);
        saveas(gcf, fullfile(save_figure_fold_path, 'arranged_pick_up_images.png'))
        figure(overlay_figure)
        saveas(gcf, fullfile(save_figure_fold_path, 'overlayed_pick_up_images.png'))
        close all;
    end
    
    %% calc joint angle
    if joint_angle_calculation == 1 
        % calcurate joint angle for each days
        ref_coordination_data_path = fullfile(common_coordination_data_path, day_folders{day_id}, 'coordination_data_list.csv');
        data_table = readtable(ref_coordination_data_path);
        col_name_list = data_table.Properties.VariableNames;

        % get input_data.body_parts list & input_data.data_type list
        input_data = struct();
        input_data.body_parts = {};
        input_data.data_type = {};
        for col_id = 1:length(col_name_list)
            col_name = col_name_list{col_id};
            elements = split(col_name, '_');
            input_data.body_parts{end+1} = elements{1};
            input_data.data_type{end+1} = elements{2};
        end
        input_data.body_parts = unique(input_data.body_parts, 'stable');
        input_data.data_type = unique(input_data.data_type, 'stable');
        input_data.coordination_data = table2array(data_table);
        
        % calc_joint_angle
        [target_joint, joint_angle_data_list] = calc_joint_angle_manual(input_data, plus_direction);

        % save joint angle data
        joint_angle_data_save_fold_path = fullfile(common_joint_angle_path, day_folders{day_id});
        makefold(joint_angle_data_save_fold_path);
        save(fullfile(joint_angle_data_save_fold_path, 'joint_angle_data.mat'), 'target_joint', 'joint_angle_data_list')
    end
end

%% create a diagram showing the transition of join angles
if create_joint_angle_diagram == 1
    ref_term_data = struct();
    for day_id = 1:length(day_folders)
        ref_joint_angle_data_path = fullfile(common_joint_angle_path, day_folders{day_id}, 'joint_angle_data.mat');
        load(ref_joint_angle_data_path, 'target_joint', 'joint_angle_data_list')
    
        % find mean and std value of joint angle for each joint
        for target_id = 1:length(target_joint)
            if day_id == 1
                % preapare empty array to store joint angle data(mean and std data)
                ref_term_data.(target_joint{target_id}).mean = zeros(1, length(day_folders));
                ref_term_data.(target_joint{target_id}).std = zeros(1, length(day_folders));
            end
    
            ref_data = joint_angle_data_list.(target_joint{target_id});
            mean_value = mean(ref_data);
            std_value = std(ref_data);
            ref_term_data.(target_joint{target_id}).mean(day_id) = mean_value;
            ref_term_data.(target_joint{target_id}).std(day_id) = std_value;
        end
    end    

    % plot data
    [elapsed_date_list] = makeElapsedDateList(day_folders, '200121');
%         post_first_elapsed_date = elapsed_date_list(find(elapsed_date_list > 0, 1 ));
    post_first_elapsed_date = 20; % 暫定的
    % plot figure
    plot_phase_figure_manual(ref_term_data, target_joint, elapsed_date_list, post_first_elapsed_date, extract_image_type, plus_direction, common_save_transition_figure_fold_path, diff_end_frame)
end

%% define local function
%{
指定したpathの動画を読み込み、GUI操作で所望の処理を実現するための関数
%}

function [diff_end_frame] = avi_frame_by_frame_viewer(ref_trial_movie_path, save_figure_fold_path, save_figure_name, image_type)
    % create video object
    videoObj = VideoReader(ref_trial_movie_path);
    numFrames = videoObj.NumFrames;
    
    % get the image data of 1st frame
    currentFrame = 1;
    frame = read(videoObj, currentFrame);
    
    % display figure
    figure_size = [100, 100, size(frame, 2), size(frame, 1)];
    hFig = figure('Name', 'AVI Frame-by-Frame Viewer', 'KeyPressFcn', @keyPressCallback, 'Position', figure_size);
    hIm = imshow(frame, 'Border', 'tight');

    % change the size of figure
    set(hFig, 'Units', 'pixels', 'Position', figure_size);
    
    % create the callback function
    function keyPressCallback(~, event)
        switch event.Key
            case 'rightarrow'
                currentFrame = min(currentFrame+1, numFrames);
            case 'leftarrow'
                currentFrame = max(currentFrame-1, 1);

            % if pressed 'Enter' key
            case 'return'
                diff_end_frame = numFrames - currentFrame;
                % save image
                imwrite(frame, fullfile(save_figure_fold_path, [save_figure_name image_type]))
                close(hFig);
                return;
        end
        frame = read(videoObj, currentFrame);
        set(hIm, 'CData', frame);
        drawnow;
    end
    
    % wait until figure will be closed;
    waitfor(hFig);
end

%% 
%{
指定したpathの動画を読み込み, diff_end_frameに従って画像を自動で保存
%}

function [] = auto_save_image(ref_trial_movie_path, diff_end_frame, save_figure_fold_path, save_figure_name, image_type)
    % create video object
    videoObj = VideoReader(ref_trial_movie_path);
    numFrames = videoObj.NumFrames;
    
    % get the image data of 1st frame
    extract_image_frame = numFrames - diff_end_frame;
    stored_image = read(videoObj, extract_image_frame);
    imwrite(stored_image, fullfile(save_figure_fold_path, [save_figure_name image_type]))
end

%% 
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

function [target_joints, output_data] = calc_joint_angle_manual(input_data, plus_direction)
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

%% create a diagram showing the transition of joint angle
%{
%}
function [] = plot_phase_figure_manual(ref_term_data, target_joint, elapsed_date_list, post_first_elapsed_date, extract_image_type, plus_direction, save_figure_fold_path, diff_end_frame)
target_joint_num = length(target_joint);
figure('Position',[100 100 600 300 * target_joint_num]);

% make figure
for target_joint_id = 1:target_joint_num
    ref_joint_data = ref_term_data.(target_joint{target_joint_id});
    subplot(target_joint_num, 1, target_joint_id)

    % plot 
    hold on
    plot(elapsed_date_list, ref_joint_data.mean, 'Color', 'blue', 'LineWidth',1.2);
    hold on;
    errorbar(elapsed_date_list, ref_joint_data.mean, ref_joint_data.std, 'o', 'Color', 'blue', 'LineWidth',1.2)

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
    hold off;
    hold off;
end

switch extract_image_type
    case 'manual'
        sgtitle(['manual timing joint angle' ' (', plus_direction '-plus)'], 'Interpreter', 'none', fontsize=20)
    case 'auto'
        sgtitle(['diff_end_' num2str(diff_end_frame) '_frame timing joint angle' ' (', plus_direction '-plus)'], 'Interpreter', 'none', fontsize=20)
end

% save
figure_file_name = 'transition of joint angle';
makefold(save_figure_fold_path)
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.png']))
saveas(gcf, fullfile(save_figure_fold_path, [figure_file_name '.fig']))
close all;
end


