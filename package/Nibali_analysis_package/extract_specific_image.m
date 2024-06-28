%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
videoReaderオブジェクトから，特定の画像のテンソルだけを抽出する関数
% 入力引数:
VideoObject: videoReaderオブジェクト
frame_num: 抽出したい画像の動画上でのframe数(スタートからの経過フレーム数)
%出力:
 画像の輝度値情報(3次元テンソル)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ref_frame] = extract_specific_image(VideoObject, frame_num)
VideoObject.CurrentTime = (frame_num - 1) / VideoObject.FrameRate; %指定したフレームへジャンプする
ref_frame = readFrame(VideoObject);
end