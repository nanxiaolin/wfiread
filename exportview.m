function exportview()
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    
    set(h_mainfig, 'PaperPositionMode', 'auto');
    set(h_mainfig,'InvertHardcopy','off')
    print(h_mainfig, '-dmeta');
    
    showmsg(h_mainfig, 'message', 'Current view exported to system clipboard');

return