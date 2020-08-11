function clearselection
% clears the currently selected area and resets the view to full image
    global h_mainfig params;
    
    userdata = get(h_mainfig, 'userdata');
    
    ah = userdata.h_axis;
	cp = get(ah, 'CurrentPoint');
	xl = xlim(ah);	yl = ylim(ah);

	xinit = cp(1, 1); yinit = cp(1, 2);

	if xinit < xl(1) || xinit > xl(2) || yinit < yl(1) || yinit > yl(2)
		return;
    end
    
    % if previous selection is in place, remove it
	if userdata.h_selrect > 0
		delete(userdata.h_selrect);
        userdata.h_selrect = -1;
    end
    
    showmsg(h_mainfig, 'selstart', '(1, 1)');
    mesg = sprintf('(%d, %d)', userdata.width, userdata.height);
    showmsg(h_mainfig, 'selend', mesg);

    % adjust the actual selection matrix
    userdata.selection = [1 1 userdata.width userdata.height];
    params.startx = 1;		params.endx = userdata.width;
    params.starty = 1; 		params.endy = userdata.height;
    set(h_mainfig, 'userdata', userdata);

	% disable the 'fit' and 'track' buttons in case it is clicked by accident
	set(userdata.h_fit, 'Enable', 'off');
	set(userdata.h_track, 'Enable', 'off');
	set(userdata.h_marker, 'Enable', 'off');
