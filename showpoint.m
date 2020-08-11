function showpoint(object, event)
%
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    
    ah = userdata.h_axis;
	cp = get(ah, 'CurrentPoint');
	xl = xlim(ah);	yl = ylim(ah);

	xinit = round(cp(1, 1)); yinit = round(cp(1, 2));

	if xinit < xl(1) || xinit > xl(2) || yinit < yl(1) || yinit > yl(2)
        showmsg(h_mainfig, 'edcursorpos', '');
        showmsg(h_mainfig, 'edintensity', '');
        set(h_mainfig, 'Pointer', 'arrow');
		return;
    else
        intensity = ongetframe(0, [xinit yinit]);
        mesg = sprintf('(%d, %d)', xinit, yinit);
        showmsg(h_mainfig, 'edcursorpos', mesg);
        showmsg(h_mainfig, 'edintensity', sprintf('%6d', intensity(1)));
        set(h_mainfig, 'Pointer', 'crosshair');
    end
