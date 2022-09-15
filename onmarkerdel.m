function onmarkerdel(object, event)
% function that clears all saved markers
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');

    for i = 1 : userdata.markernum
        delete(userdata.markerhandles(i));
    end

    userdata.markerhandles = -1;
    userdata.markernum = 0;
    userdata.markerpos = 0;
	userdata.markers = [];

    set(h_mainfig, 'userdata', userdata);
    set(userdata.h_markerdel, 'enable', 'off');
    %set(userdata.h_makecoord, 'enable', 'off');
    
   	% we need to enable the palm start and ending frames
	set(userdata.h_palmstart, 'enable', 'on');
	set(userdata.h_palmend, 'enable', 'on');

return
