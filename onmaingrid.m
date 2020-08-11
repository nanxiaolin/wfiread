function onmaingrid(obj, event)
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    h = findobj(h_mainfig, 'tag', 'chkgridon');
    value = get(h, 'Value');
    
    if value
        figure(h_mainfig); grid on;
        userdata.gridon = 1;
    else
        figure(h_mainfig); grid off;
        userdata.gridon = 0;
    end
    
    set(h_mainfig, 'userdata', userdata);