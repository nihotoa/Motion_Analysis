%{
[explanation of this func]:
eliminate '.' & '..' information from structure which is obained by 'dir' function

[input arguments]
folder_path: [char], path of folder (same input arguments of 'dir' function)
additional_name_list: [cell (row vector)], list of file name which you want to remove additional
                        (this is optional argument (you don't have to set this arguments))
extension_type:[char] If you want to extarct information only for a specific extension (ex. .avi), please specify it 

[output arguments]
dir_list: [struct], contents in the specified directory (same output arguments of 'dir' function)
%}

function [dir_list] = dirEx(folder_path, additional_name_list, extension_type)
% prepare excluded file list
excluded_name_list = {'.', '..'};
if exist("additional_name_list", "var")
    excluded_name_list = horzcat(excluded_name_list, additional_name_list);
end
if exist("extension_type", "var")
    dir_list = dir(fullfile(folder_path, ['*' extension_type]));
else
    dir_list = dir(folder_path);
end
dir_list = dir_list(~ismember({dir_list.name}, excluded_name_list));

% also exclude automatically generated files by macOS   (ex.) .DS_Store
dir_list = dir_list(~startsWith({dir_list.name}, {'.', '._'}));
end

