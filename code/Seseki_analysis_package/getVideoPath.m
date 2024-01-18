%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[function]
to get the path of  the video that meets the input  argument conditions.

[input arguments]
ref_trial: double, enter the trial num
ref_day: string, enther the day information
subject_name: string, enter the full name of subject (ex.) Seseki
video_type: string, enter the extension of movie file you want to get
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function VideoPath = getVideoPath(ref_trial, ref_day, subject_name, video_type)
ref_dir_name = fullfile(pwd, [subject_name  '_Movie']);
movie_dir_names = getfileName(ref_dir_name, 'dir');
ref_movie_fold = movie_dir_names{find(contains(movie_dir_names, ref_day))};
movie_files_names = getfileName(fullfile(ref_dir_name, ref_movie_fold), video_type);
ref_file_name = movie_files_names{find(contains(movie_files_names, ['trial_' sprintf('%02d', ref_trial)]))};
VideoPath = fullfile(ref_dir_name, ref_movie_fold, ref_file_name);
end