%{
最小値なのか最大値なのか
%}

function output_images = pick_up_specific_image(joint_angle_data_list, target_joint, ref_day, subject_name, video_type)
trial_num = numel(fieldnames(joint_angle_data_list));
% create structure array
output_images = struct();
frame_idx_data_path = fullfile(pwd, 'save_data', 'frame_idx', 'minimum', ref_day);
load(fullfile(frame_idx_data_path, 'frame_idx_list.mat'), 'frame_idx_list')
plot_count = 0;
% store the data
for ii = 1:trial_num
    try % If joint_angle_data_list is not read, continue.
        ref_trial_data = eval(['joint_angle_data_list.trial' num2str(ii)]);
        plot_count = plot_count+1;
        % getVideoPath (from Seseki_movie -> ...)
        VideoPath = getVideoPath(ii, ref_day, subject_name, video_type);
        Video = VideoReader(VideoPath);
        % load
        for jj = 1:length(target_joint) %main joint
            % get the number of frame to pick up
            pick_up_frame_idx = eval(['frame_idx_list.' target_joint{jj} '_main(plot_count);']);
            % VideoReader オブジェクトを使用して指定のフレームを読み込み
            Video.CurrentTime = (pick_up_frame_idx - 1) / Video.FrameRate; % Get image of pick_up_frame_idx
            specific_image = readFrame(Video); % Load image of specified frame
            % store specific_image in output_images
            eval(['output_images.main_' target_joint{jj} '{ii} = specific_image;'])
        end
    catch
        continue;
    end
end
end

%% define local function
function VideoPath = getVideoPath(ref_trial, ref_day, subject_name, video_type)
ref_dir_name = fullfile(pwd, [subject_name  '_Movie']);
movie_dir_names = getfileName(ref_dir_name, 'dir');
ref_movie_fold = movie_dir_names{find(contains(movie_dir_names, ref_day))};
movie_files_names = getfileName(fullfile(ref_dir_name, ref_movie_fold), video_type);
ref_file_name = movie_files_names{find(contains(movie_files_names, ['trial_' sprintf('%02d', ref_trial)]))};
VideoPath = fullfile(ref_dir_name, ref_movie_fold, ref_file_name);
end

