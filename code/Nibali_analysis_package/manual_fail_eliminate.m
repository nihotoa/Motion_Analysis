%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
extract_LED_timingの中で使われている
threshold判定だけでは心もとないので,manualで最終確認するためにつくった関数
入力引数
videoObject => data type: VideoReader, VideoReder関数で読み込まれた動画ファイル
off_frame => data type: double, 数値が入った配列
on_frame => 
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [on_frame, off_frame] = manual_fail_eliminate(videoObject, on_frame, off_frame)
% いずれかのタイミングが2つ以上あったら手動で取り除く
if length(on_frame) >= 2 || length(off_frame) >= 2
    % offの中で,onの最小値よりも小さいものを消す(offがonより先に来ることはないから)
    on_min = min(on_frame);
    off_frame = off_frame(off_frame > on_min); % onの一番最初より前にあるoffは全て除外する

    % 1枚ずつ表示して手動で消す
    LED_on_off_list = {'off_frame', 'on_frame'};
    for ii = 1:2 %onとoff
        ref_LED_timing = eval(LED_on_off_list{ii}); %onかoffの変数を代入する
        eliminate_list = [];
        eliminate_count = 1;
        plus_sign = 1;
        if ii == 1 %offを参照する
            plus_sign = -1;
        end
        for jj = 1:length(ref_LED_timing)
            if length(ref_LED_timing) == 1
                continue
            end
            %表示する画像を取ってくる
            ref_frame = extract_specific_image(videoObject, ref_LED_timing(jj)+(plus_sign));
            while true
                imshow(ref_frame);
                input_string = input("LEDが光っていたらa,そうでない場合はd, 処理を中断したい場合はqを押してください: ", 's');
                close all;
                if strcmp(input_string, 'a') || strcmp(input_string, 'd') || strcmp(input_string, 'q') 
                    if  strcmp(input_string, 'd')
                        % その値を抜く
                        eliminate_list(eliminate_count) = ref_LED_timing(jj);
                        eliminate_count = eliminate_count + 1;  
                    elseif strcmp(input_string, 'q')
                        disp('コマンドウィンドウにdbquitと入力してください')
                        keyboard;
                    end
                    break
                else
                    disp('正しい文字を入力してください')
                    continue;
                end
            end
        end
        %実際に要らないものを消す
        ref_LED_timing = setdiff(ref_LED_timing, eliminate_list);
        %元の変数に格納する
        eval([LED_on_off_list{ii} ' = ref_LED_timing;'])
    end
end
end

