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