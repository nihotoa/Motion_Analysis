function getspike_scope
global gsobj

fig = figure;
set(fig,'Name','GetSpike(Scope)',...
    'Numbertitle','Off',...
    'Pointer','arrow',...
    'Position',[810    102   613   393],...
    'Tag','gsscope',...
    'Toolbar','Figure');

h   = subplot(6,1,1:5);
set(h,'Tag','scope_axis');

gsobj.handles.gsscope     = fig;
gsobj.handles.scope       = h;

gsobj.handles.addbutton   = uicontrol('Unit','Normalized',...
    'Callback','tawindow(''add'')',...
    'Position',[0.75 0.93 0.06 0.05],...
    'String','+',...
    'Style','Pushbutton',...
    'Tag','addbutton');

gsobj.handles.exceptbutton	= uicontrol('Unit','Normalized',...
    'Callback','tawindow(''except'')',...
    'Position',[0.82 0.93 0.06 0.05],...
    'String','-',...
    'Style','Pushbutton',...
    'Tag','exceptbutton');

gsobj.handles.exceptbutton	= uicontrol('Unit','Normalized',...
    'Callback','tawindow(''delete'')',...
    'Position',[0.89 0.93 0.06 0.05],...
    'String','Del',...
    'Style','Pushbutton',...
    'Tag','delbutton');



gsobj.handles.replotbutton  = uicontrol('Unit','Normalized',...
    'Callback','getspike(''scope_plot'')',...
    'Position',[0.10 0.05 0.08 0.1],...
    'String','Replot',...
    'Style','Pushbutton',...
    'Tag','replotbutton');

gsobj.handles.alignbutton	= uicontrol('Unit','Normalized',...
    'Callback','getspike(''align'')',...
    'Position',[0.22 0.05 0.08 0.1],...
    'String','Align',...
    'Style','Pushbutton',...
    'Tag','alignbutton');

gsobj.handles.rb_localmax   = uicontrol('Unit','Normalized',...
    'Callback','set(findobj(gcf,''Tag'',''rb_localmin''),''Value'',0)',...
    'Position',[0.31 0.10 0.13 0.05],...
    'String','Local Max',...
    'Style','RadioButton',...
    'Tag','rb_localmax',...
    'Value',1);

gsobj.handles.rb_localmin	= uicontrol('Unit','Normalized',...
    'Callback','set(findobj(gcf,''Tag'',''rb_localmax''),''Value'',0)',...
    'Position',[0.31 0.05 0.13 0.05],...
    'String','Local Min',...
    'Style','RadioButton',...
    'Tag','rb_localmin',...
    'Value',0);

gsobj.handles.alignbutton	= uicontrol('Unit','Normalized',...
    'Callback','getspike(''msdfilter'')',...
    'Position',[0.48 0.05 0.08 0.1],...
    'String','Filt',...
    'Style','Pushbutton',...
    'Tag','refbutton');

gsobj.handles.alignbutton	= uicontrol('Unit','Normalized',...
    'Callback','getspike(''pca'')',...
    'Position',[0.60 0.05 0.08 0.1],...
    'String','PCA',...
    'Style','Pushbutton',...
    'Tag','pcabutton');

gsobj.handles.shiftbutton   = uicontrol('Unit','Normalized',...
    'Callback','getspike(''shift'')',...
    'Position',[0.72 0.05 0.08 0.1],...
    'String','Shift',...
    'Style','Pushbutton',...
    'Tag','shiftbutton');

gsobj.handles.shift	= uicontrol('Unit','Normalized',...
    'Callback','',...
    'Position',[0.82 0.05 0.08 0.1],...
    'String','0',...
    'Style','Edit',...
    'Tag','shift');

% 
% h   = uicontrol('Unit','Normalized',...
%     'Callback','',...
%     'Position',[0.80 0.1 0.07 0.05],...
%     'String','V',...
%     'Style','RadioButton',...
%     'Tag','RB_Falling',...
%     'Value',0);