function onmainaxis(object, event)

    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    h = findobj(h_mainfig, 'tag', 'chkaxison');
    value = get(h, 'Value');
    
    if value
        figure(h_mainfig); axis on;
        set(findobj(h_mainfig, 'tag', 'chkgridon'), 'enable', 'on');
        userdata.axison = 1;
    else
        figure(h_mainfig); axis off;
        set(findobj(h_mainfig, 'tag', 'chkgridon'), 'enable', 'off');
        userdata.axison = 0;
    end
    
    set(h_mainfig, 'userdata', userdata);