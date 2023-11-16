%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
指定した日付の,全てのトライアルの,各タイミングにおける経過フレーム数(各トライアルのスタートに対して)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output_array = extract_each_timing_frame(ref_files_name, timing_num, ref_day, real_name)
trial_num = numel(fieldnames(ref_files_name));
output_array = zeros(trial_num, timing_num);
common_file_path = fullfile(pwd, [real_name '_movie'], ref_day);
% find the image coordination of LED
ref_x = [];
ref_y = [];
for ii = 1:trial_num
    % loading data to use
    file_name= eval(['ref_files_name.trial' num2str(ii)]);
    load_file_path = fullfile(common_file_path, file_name);
    videoObject = VideoReader(load_file_path);
    all_frames = videoObject.Duration * videoObject.FrameRate;
    output_array(ii,1) = 1; % first frame
    output_array(ii,4) = all_frames;
    % extract frame of timing2 & timin3(LED on off)
    [LED_on_frame, LED_off_frame, ref_x, ref_y] = extract_trial_LED_timing(videoObject, ref_x, ref_y);
    % 失敗している場合は,NaNを返す
    if isempty(LED_on_frame) || isempty(LED_off_frame)
        output_array(ii, :) = NaN;
    else
        output_array(ii,2) = LED_on_frame;
        output_array(ii,3) = LED_off_frame;
    end
end
end

