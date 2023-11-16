function [] = create_real_time_video(created_fps, movie_path, now_frame_rate, movie_extension)
% movieのプロパティを変更して,新しいプロパティの等倍速の動画を作るための関数
%{
created_fps: 作成する動画のフレームレート(等倍速なので再生時のフレームレートと一緒)
movie_path: 処理する動画のpath
now_frame_rate現在のフレームレート(再生時のフレームレートではなくて,記録されている時のフレームレート)
【課題点】
now_frame_rateをsearch_frame_rateの結果から取得するa
%}

% 動画を読み込んでオブジェクトを作る
VideoObject = VideoReader(movie_path);

% RealTime動画を作成
new_video_file_name = strrep(movie_path, movie_extension, '');
new_video_file_name = [new_video_file_name '_RealTime.mp4'];

% ビデオオブジェクトを作成
vidWriter = VideoWriter(new_video_file_name,  'MPEG-4');
vidWriter.FrameRate = created_fps;
% 動画の読み込みと書き込み
open(vidWriter);
%↓intervalを指定して，idxを作成し,extract_specific_imageを使ってそのidxの画像を読み込み，writeVideoする
interval = now_frame_rate / created_fps;
idx = 1;
while true
    frame = extract_specific_image(VideoObject, round(idx));
    writeVideo(vidWriter, frame);
    idx = idx + interval;
    if idx > VideoObject.NumFrames
        break
    end
end
close(vidWriter);
end

