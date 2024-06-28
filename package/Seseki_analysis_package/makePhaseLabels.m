%{
make labels for naming each phase data
%}
function [phase_labels] = makePhaseLabels(day_folders, phase_date_list)
day_num = length(day_folders);
phase_labels = cell(day_num, 1);
elapsed_date_list = makeElapsedDateList(day_folders, '200121');
phase_elapsed_date_list = makeElapsedDateList(phase_date_list, '200121');
[~, no_phase_idx_list] = setdiff(elapsed_date_list, phase_elapsed_date_list);
phase_idx_list = setdiff(1:day_num, no_phase_idx_list);
alphabet_count = 1;
for ii = 1:length(phase_idx_list)
    phase_idx = phase_idx_list(ii);
    phase_labels{phase_idx} = ['Phase ' char('A' + (alphabet_count - 1))];
    alphabet_count = alphabet_count + 1;
end
no_phase_count = 1;
for ii = 1:length(no_phase_idx_list)
    no_phase_idx = no_phase_idx_list(ii);
    % 文字リテラルだから改善した方がいい
    phase_labels{no_phase_idx} = ['Phase EtoF-' num2str(no_phase_count)];
    no_phase_count = no_phase_count + 1;
end
end