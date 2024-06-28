%{
指定したpathの動画を読み込み、GUI操作で所望の処理を実現するための関数
%}

function [diff_end_frame] = videoGUIOperator(ref_trial_movie_path, save_figure_fold_path, save_figure_name, image_type)
    % create video object
    disp("Move to the frame you want to cut out and press 'Enter'")
    disp('←: previous frame , →: next frame')
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
        switch event.Keyc
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