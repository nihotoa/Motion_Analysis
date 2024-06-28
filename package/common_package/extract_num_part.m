%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
Returns only the numeric part of the input string
(ex.)Se170516.mat -> 170516

[input argument]
input_item['char' or 'cell']: charor cell array which have char as element
(ex.)
char -> 'Se170516.mat'
cell array -> {'Se170516.mat', 'Se170517.mat'}

[output_argument]
output_item['char' or 'cell']: number part of input argument .

[caustion!!]
If there are two or more number parts, extract only the first number part
(ex.)Se170516_0001.mat ->170516
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [output_item] = extract_num_part(input_item)
if ischar(input_item)
    output_item = regexp(input_item, '\d+', 'match');
elseif iscell(input_item)
    output_item = cell(length(input_item), 1);
    for ii = 1:length(input_item)
        temp =  regexp(input_item{ii}, '\d+', 'match');
        output_item{ii} = temp{1};
    end
end
end

