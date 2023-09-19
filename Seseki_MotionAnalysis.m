%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]

[role of this code]
Performs all processing related to Seseki behavior analysis

[causion!!]
> this code is created for Seseki movie analaysis. So, his code may not be compatible with other analyses.
> The functions used in this code are stored in the following location
  path: Motion_analysis/code/Seseki_analysis_package
[saved data location]


[procedure]
pre: nothing
post: coming soon...
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% set param
monkey_name = 'Se'; 

%% code section
disp('Please select the folder containing Seseki movie data')
movie_fold_path = uigetdir();
movie_fold_full_path = fullfile(pwd, movie_fold_path);
each_fold_names = dir(movie_fold_path);

% Extract only the names of the directories you need
each_fold_names = extract_element_fold(each_fold_names, monkey_name);

% Perform analysis on data for each date
for ii = 1:length(each_fold_names)
    % Get csv file name
    csv_list = dir([movie_fold_path '/' each_fold_names{ii} '/' '*.csv']);
    csv_file_names = {csv_list.name}';
    
end
