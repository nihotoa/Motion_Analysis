load('phase regress 071119');

XLim    = [-110 110];
XTick   = [-100 :12.5:100];
YLim    = [0 12];
YTick   = [0:2:12];


figure

h   =subplot(2,2,1);
bar(X,NBG)
set(h,'Box','on',...
    'TickDir','out',...
    'XLim',XLim,...
    'XTick',XTick,...
    'YLim',YLim,...
    'YTick',YTick);

h   =subplot(2,2,3);
bar(X,NBH)
set(h,'Box','on',...
    'TickDir','out',...
    'XLim',XLim,...
    'XTick',XTick,...
    'YLim',YLim,...
    'YTick',YTick);

h   =subplot(2,2,2);
bar(X,BBG)
set(h,'Box','on',...
    'TickDir','out',...
    'XLim',XLim,...
    'XTick',XTick,...
    'YLim',YLim,...
    'YTick',YTick);

h   =subplot(2,2,4);
bar(X,BBH)
set(h,'Box','on',...
    'TickDir','out',...
    'XLim',XLim,...
    'XTick',XTick,...
    'YLim',YLim,...
    'YTick',YTick);
