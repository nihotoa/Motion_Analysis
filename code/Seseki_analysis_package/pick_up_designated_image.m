%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
get the image at the pecified index in the Video

[input arguments]
Video: Video object, (you can get by using 'VideoReader')
frame_idx: double, enter the frame_idx to get the image
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output_image = pick_up_designated_image(Video, frame_idx)
% VideoReader オブジェクトを使用して指定のフレームを読み込み
Video.CurrentTime = (frame_idx - 1) / Video.FrameRate; % Get image of pick_up_frame_idx
specific_image = readFrame(Video); % Load image of specified frame

% store specific_image in output_images
output_image = specific_image;
end



