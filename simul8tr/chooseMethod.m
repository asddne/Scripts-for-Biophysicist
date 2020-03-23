function choice = chooseMethod

    d = dialog('Units','normalized', ...
    'Position',[.4,.5,.2,.1],'Name','Please select one:');
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Position',[20 80 210 40],...
           'String','Choose which analysis to perform');
       
    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Position',[10 50 250 25],...
           'String',{'Image Correlation Spectroscopy (ICS) for <N>';'Temporal-ICS for speed and diffusion';'Spatio-Temporal-ICS for flow';'FCS'},...
           'Callback',@popup_callback);
       
    btn = uicontrol('Parent',d,...
           'Position',[89 20 70 25],...
           'String','Analyse!',...
           'Callback','delete(gcf)');
       
    choice = 'Image Correlation Spectroscopy (ICS) for <N>';
       
    % Wait for d to close before running to completion
    uiwait(d);
   
       function popup_callback(popup,event)
          idx = popup.Value;
          popup_items = popup.String;
          % This code uses dot notation to get properties.
          % Dot notation runs in R2014b and later.
          % For R2014a and earlier:
          % idx = get(popup,'Value');
          % popup_items = get(popup,'String');
          choice = char(popup_items(idx,:));
       end
end
