function tprint
% A4�T�C�Y�̎��ɁAAnalysis�t�@�C�����ƂƂ��Ɉ��

% written by tt 2009/05/14
fig = gcf;

s   = get(fig,'UserData');
s   = get(get(s{:},'LinkedAnalyses'),'FullName');

set(fig,'PaperPositionMode','auto',...
    'PaperOrientation','Portrait',...
    'PaperType','A4');

h   = uicontrol(fig,'Unit','Pixel',...
    'BackgroundColor',get(fig,'Color'),...
    'Style','text',...
    'String',s,...
    'Position',[20 0 300 20],...
    'FontName','Arial',...
    'HorizontalAlignment','left');

print(fig,'-dwinc')

delete(h);