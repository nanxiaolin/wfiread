function oncolormap(object, event)
% function that handles change in colormap choice
    global h_mainfig params;
    
    userdata = get(h_mainfig, 'userdata');
    choice = get(userdata.h_colormap, 'Value');
    figure(h_mainfig);

    switch choice
       case 1
          colormap('Gray');
          params.colormap = 'gray';
       case 2
          colormap('Bone');
          params.colormap = 'bone';
        case 3
          colormap('Hot');
          params.colormap = 'hot';
    end

return
