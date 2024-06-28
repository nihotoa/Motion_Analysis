function baseball
global t1
close all
tic

warning('off')

fig     = figure('NumberTitle','off',...
    'Name','BaseBall2008',...
    'Color',[0 0.5 0],...
    'KeyPressFcn',@keypress);
hfield  = subplot(3,3,[1:6]);

t   = uicontrol('Unit','normalize',...
    'BackgroundColor',[0 0 0],...
    'FontSize',20,...
    'ForegroundColor',[1 1 1],...
    'HorizontalAlignment','center',...
    'Style','text',...
    'String',{' ','Press Space Key'},...
    'Position',[0.25 0.35 0.5 0.2]);

uicontrol('Unit','Pixel',...
    'BackgroundColor',[0 0.5 0],...
    'FontSize',9,...
    'ForegroundColor',[1 1 1],...
    'HorizontalAlignment','left',...
    'Style','frame',...
    'Position',[50  50 150 80]);
uicontrol('Unit','Pixel',...
    'BackgroundColor',[0 0.5 0],...
    'FontSize',9,...
    'ForegroundColor',[1 1 1],...
    'HorizontalAlignment','left',...
    'Style','text',...
    'String',{'Batter:  K.Fukudome','Team  :  Chicago Cubs'},...
    'Position',[55  55 120 60]);
% h(3)    = subplot(3,3,7);
% h(4)    = subplot(3,3,7);
% h(5)    = subplot(3,3,7);
% h(3)    = uicontrol('Style','text',...
%     'Position',get(h(3),'Position'));
% h(4)    = uicontrol('Style','text',...
%     'Position',get(h(4),'Position'));
% h(5)    = uicontrol('Style','text',...
%     'Position',get(h(5),'Position'));

t1  = 0;
t2  = 0;

x   = [40:-1:21];
set(hfield,'Color',[0 0.5 0],...
    'Box','off',...
    'NextPlot','add',...
    'XColor',[0 0.5 0],...
    'YColor',[0 0.5 0],...
    'XTick',[],...
    'YTick',[],...
    'XLim',[10 70],...
    'YLim',[-20 20]);



hball   = plot(hfield,x(1),1,'o','Color','w','MarkerFaceColor','w','MarkerSize',3);
hbat    = plot(hfield,[21 20],[-2 2],'-','Color','w','Linewidth',2);

drawnow;

while(t1==0)
    pause(0.02)
   
end
delete(t)
t1  = 0;
tic

for ii =1:20
    
    set(hball,'XData',x(ii))
    if(t1~=0)
        set(hbat,'XData',[21 22])
    end
    drawnow;
    pause(0.02)

end
t2  = toc;

for ii =1:10  
    
    if(t1~=0)
        set(hbat,'XData',[21 22])
    end
    drawnow;
    pause(0.02)
end

rt  = (t1-t2)*1000;
disp(rt)

if abs(rt)<10
    s   = {' ','Home run!!'};
elseif abs(rt)<25
    s   = 'Two-base hit!!';
elseif abs(rt)<50
    s   = 'Hit!!';
else
    s   = {' ','Out...'};
end    


uicontrol('Unit','normalize',...
    'BackgroundColor',[0 0 0],...
    'FontSize',30,...
    'ForegroundColor',[1 1 1],...
    'HorizontalAlignment','center',...
    'Style','text',...
    'String',s,... {s,[num2str(rt),' (ms)']}
    'Position',[0.25 0.4 0.5 0.3]);

uicontrol('Unit','normalize',...
    'BackgroundColor',[0 0 0],...
    'FontSize',12,...
    'ForegroundColor',[1 1 1],...
    'HorizontalAlignment','center',...
    'Style','text',...
    'String',[num2str(rt),' (ms)'],...
    'Position',[0.25 0.3 0.5 0.1]);

warning('on')







function keypress(src,evnt)
global t1
if isempty(evnt.Modifier)
    switch evnt.Key
        case 'space'
            t1  = toc;
    end
end


   