%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
trialごとに切り出された動画に対してしか互換性がないことに注意.(レコーディング全体の動画に対しては互換性がない)
本当に動画の一番最初のフレームのLEDはLED offなのか(他の場合も考えられるのでは?)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [LED_on_frame, LED_off_frame, ref_x, ref_y] = extract_trial_LED_timing(videoObject,ref_x, ref_y)
    frame_count = 0;
    LED_RGB_list = zeros(videoObject.NumFrames,3);
    while hasFrame(videoObject)
        ref_image = readFrame(videoObject);
        % LEDの画像座標を取得する
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
    off_to_on_threshold = max(diff_sum_RGB_list) * 0.5;
    on_to_off_threshold = min(diff_sum_RGB_list) * 0.5;
    of_to_on_frame_candidate = find(diff_sum_RGB_list > off_to_on_threshold);
    on_to_off_frame_candidate = find(diff_sum_RGB_list < on_to_off_threshold);
    on_frame = eliminate_consective_num(of_to_on_frame_candidate) + 1;  %eliminate consective values;  
    off_frame = eliminate_consective_num(on_to_off_frame_candidate) + 1;   
    
    % ここに芋や手じゃないかを判断するコードを書いていく
    first_frame_idx = 1; %first_frameに使用する画像のindex
    %1. offの方が多い時(ex. 一番最初のフレームで,ローランドさんが餌をセットしているとき).
    %【問題点】 onとoffの数が合うまで処理を行うが, 芋手被りの時もこのif分が適用される可能性が大いにある
    % GUIがめんどくさいだけだからこのままでいいんじゃない?
    if length(on_frame) < length(off_frame)
        % offの中で,onの最小値よりも小さいものを消す(offがonより先に来ることはないから)
        on_min = min(on_frame);
        % Rolandさんの手が離れてLEDがoffになった瞬間の画像を取得
        first_frame_idx = max(off_frame(off_frame < on_min));
        % 正しいoff_frameの取得(サルの試行中のLED off)
        off_frame = off_frame(off_frame > on_min);
        if  length(off_frame) - length(on_frame) >= 1 %まだonとoffに違いがある場合
             % 1枚ずつ表示して手動で消す
            eliminate_list = [];
            eliminate_count = 1;
            for ii = 1:length(off_frame)
                ref_frame = extract_specific_image(videoObject, off_frame(ii)-1);
                while true
                    imshow(ref_frame);
                    input_string = input("LEDが光っていたら'Yes',そうでない場合は'No'を入力してください: ", 's');
                    close all;
                    if strcmp(input_string, 'Yes') || strcmp(input_string, 'No')
                        if  strcmp(input_string, 'No')
                            % その値を抜く
                            eliminate_list(eliminate_count) = off_frame(ii);
                            eliminate_count = eliminate_count + 1;  
                        end
                        break
                    else
                        disp('正しい文字を入力してください')
                        continue;
                    end
                end
            end
            %実際に要らないものを消す
            off_frame = setdiff(off_frame, eliminate_list);
        end
    end

    %2.手とLED offの区別
    pixel_length = 50;
    %  動画の一番最初のフレームのLED(LED off)周りのRGB値を持ってくる
    first_frame = extract_specific_image(videoObject, first_frame_idx);
    ref_part = first_frame([ref_y-pixel_length:ref_y+pixel_length], [ref_x-pixel_length:ref_x+pixel_length], :);
    calc_ref = double(ref_part);
    diff_threshold = 20; % 画像間の各ピクセルの輝度差の閾値
    not_matching_rate_threshold = 0.2; %間違っている割合の閾値
    eliminate_list = [];
    eliminate_count = 1;
    % offのframeを1枚ずつ確かめていく
    for ii = 1:length(off_frame)
        frame_num = off_frame(ii);
        ref_frame = extract_specific_image(videoObject, frame_num+1);
        competitive_part = ref_frame([ref_y-pixel_length:ref_y+pixel_length], [ref_x-pixel_length:ref_x+pixel_length], :);
        calc_competitive = double(competitive_part);
        % ref_partとcompetitive_partの比較
        difference = abs(calc_competitive - calc_ref);
        matching_pixels = all(difference <= diff_threshold, 3);
        not_matching_rate = length(find(matching_pixels==0)) / (size(matching_pixels, 1) * size(matching_pixels, 2)); %異なる割合
        % 手だった場合
        if  not_matching_rate > not_matching_rate_threshold
            eliminate_list(eliminate_count) = frame_num; %取り除きリストに入れる
            eliminate_count = eliminate_count + 1; 
        end
    end
    % フィルターに引っかかったものを弾く
    off_frame = setdiff(off_frame, eliminate_list);
    %ここまで

    % on_frameとoff_frameが1つずつであれば,成功なので,出力として返す,失敗の場合はからのリストで返す
    if length(on_frame) == 1 && length(off_frame) == 1 %'LED on' & 'LED off' are done once each in 1 trial
        LED_on_frame = on_frame;
        LED_off_frame = off_frame;
    else
        LED_on_frame = [];
        LED_off_frame = [];
    end
end

