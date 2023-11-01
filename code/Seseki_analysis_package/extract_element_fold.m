%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
Leave only the necessary folder names (which contains a monkey's name as a prefix)
[detail]
if the folder name prefix contains 'Se' (ex. Se1710516~) => assigned as output(latest_each_fold_names)
if the folder name prefix does not contains 'se' (ex. movie_fold) => not assigend as output(latest_each_fold_names)

input: each_fold_names(data_type => struct (data output by dir function)), monkey_name(data_type => char (ex. 'Se'))
output: data type -> cell (which contains name of directory)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [latest_each_fold_names] = extract_element_fold(each_fold_names, monkey_name)
count = 1;
for ii = 1:length(each_fold_names)
    if and(each_fold_names(ii).isdir, startsWith(each_fold_names(ii).name, monkey_name))
        latest_each_fold_names{count} = each_fold_names(ii).name;
        count = count+1;
    end
end
end

