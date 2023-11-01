%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
trialごとに切り出された動画に対してしか互換性がないことに注意.(レコーディング全体の動画に対しては互換性がない)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [LED_on_frame, LED_off_frame, ref_x, ref_y] = extract_trial_LED_timing(videoObject,ref_x, ref_y)
    frame_count = 0;
    LED_RGB_list = zeros(videoObject.NumFrames,3);
    while hasFrame(videoObject)
        ref_image = readFrame(videoObject);
        if isempty(ref_x) && isempty(ref_y)
            imshow(ref_image);
            set(gcf, 'Position', get(0, 'ScreenSize'))
            % select the location of LED
            title('Please select the location of LED');
            [ref_x, ref_y]  = ginput(1);
            ref_x = round(ref_x);
            ref_y = round(ref_y); 
            close all;
        end
        LED_RGB_list(frame_count+1,1:3) = ref_image(ref_y, ref_x, :); % Note that it is (ref_y,ref_x), not (ref_x,ref_y)
        frame_count = frame_count+1;
    end
    sum_RGB_list = sum(LED_RGB_list, 2);
    diff_sum_RGB_list= diff(sum_RGB_list);
    off_to_on_threshold = max(diff_sum_RGB_list) * 0.8;
    on_to_off_threshold = min(diff_sum_RGB_list) * 0.8;
    of_to_on_frame_candidate = find(diff_sum_RGB_list > off_to_on_threshold);
    on_to_off_frame_candidate = find(diff_sum_RGB_list < on_to_off_threshold);
    on_frame = eliminate_consective_num(of_to_on_frame_candidate) + 1;  %eliminate consective values;  
    off_frame = eliminate_consective_num(on_to_off_frame_candidate) + 1;   
    if length(on_frame) == 1 && length(off_frame) == 1 %'LED on' & 'LED off' are done once each in 1 trial
        LED_on_frame = on_frame;
        LED_off_frame = off_frame;
    else
        LED_on_frame = [];
        LED_off_frame = [];
    end
end

