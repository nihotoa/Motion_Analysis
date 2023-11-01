%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
入力として,フォルダのpathを受け取り,そのフォルダの中にあるoutput_typeで指定された拡張子ファイルの名前をcell配列として出力する 
【注意】
ouput_typeの中身
ディレクトリの名前が欲しい場合 => output_type = 'dir'
そうでない場合 => 拡張子の.以下を記述する (例)aviファイルの場合 output_type = '.avi'
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [output_file_names] = getfileName(ref_dir_name, output_type)
switch output_type
    case 'dir'
        candidate_files = dir(ref_dir_name);
        counter = 1;
        for ii = 1:length(candidate_files)
            if candidate_files(ii).isdir && ~ismember(candidate_files(ii).name, {'.', '..'})
                output_file_names{counter} = candidate_files(ii).name;
                counter = counter + 1;
            end
        end
    otherwise
        output_files = dir(fullfile(ref_dir_name, ['*' output_type]));
        output_file_names = {output_files.name};
end
end

