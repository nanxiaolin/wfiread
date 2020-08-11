function closefigs(object, event)
% when wfireader exits, close all related figures
    
    %close all;
    
    global h_mainfig;
    userdata = get(h_mainfig, 'userdata');
    
    opened = get(0, 'Children');
    
    if find(opened == userdata.figdisplace)
        close(userdata.figdisplace);
    end
    
    if find(opened == userdata.fig3d)
        close(userdata.fig3d);
    end
    
    if find(opened == userdata.figpalm)
        close(userdata.figpalm);
    end
    
    if find(opened == userdata.figlowres)
        close(userdata.figlowres);
    end
    
    if find(opened == userdata.figintensity)
        close(userdata.figintensity);
    end
    
    if find(opened == userdata.figposition)
        close(userdata.figposition);
    end
    
    close(h_mainfig);
    clear global 'h_mainfig';
    clear global 'imgdata';
   
   
    