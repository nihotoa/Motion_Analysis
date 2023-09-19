%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
Leave only the necessary folder names
input: data type -> struct (aata output by dir function)
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

