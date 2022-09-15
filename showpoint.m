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
		if xinit < 1
			xinit = 1;
		end
		
		if yinit < 1
			yinit = 1;
		end
		
		if xinit > userdata.width
			xinit = userdata.width;
		end
		
		if yinit > userdata.height
			yinit = userdata.height;
		end
	
        intensity = ongetframe(0, [xinit yinit]);
        mesg = sprintf('(%d, %d)', xinit, yinit);
        showmsg(h_mainfig, 'edcursorpos', mesg);
        showmsg(h_mainfig, 'edintensity', sprintf('%6d', intensity));
        set(h_mainfig, 'Pointer', 'crosshair');
    end
