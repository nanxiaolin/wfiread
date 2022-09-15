function startselection(object, event)
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
	if ishandle(userdata.h_selrect)
		delete(userdata.h_selrect);
        %userdata.h_selrect = -1;
        
        showmsg(h_mainfig, 'selstart', sprintf('(%d, %d)', xinit, yinit));
        mesg = sprintf('(%d, %d)', userdata.width, userdata.height);
        showmsg(h_mainfig, 'selend', mesg);
        
        % adjust the actual selection matrix
        userdata.selection = [round(xinit) round(yinit) userdata.width userdata.height];
        set(h_mainfig, 'userdata', userdata);
    end

	startx = xinit;   starty = yinit;
	rw = 1; rh = 1;

    userdata.h_selrect = rectangle('Position', [xinit yinit 1 1], 'LineStyle', '-', 'EdgeColor', [0.6, 0.1, 1]);
	set(h_mainfig, 'WindowButtonMotionFcn', @drawselection);
	set(h_mainfig, 'WindowButtonUpFcn', @endselection);

	% toggle the state of the 'Selection Button'
	% set(userdata.h_select, 'String', 'Selecting ...');

	function drawselection(object, event)
		cp = get(ah, 'CurrentPoint');
		
		if cp(1, 1) < xl(1)
			cp(1, 1) = xl(1);
		elseif cp(1, 1) > xl(2)
			cp(1, 1) = xl(2);
		end

		if cp(1, 2) < yl(1)
			cp(1, 2) = yl(1);
		elseif cp(1, 2) > yl(2)
			cp(1, 2) = yl(2);
		end


		if xinit < cp(1, 1)
			startx = xinit;
			rw = cp(1, 1) - xinit;
		else
			startx = cp(1, 1);
			rw = xinit - cp(1, 1);
		end

		if yinit < cp(1, 2)
			starty = yinit;
			rh = cp(1, 2) - yinit;
		else
			starty = cp(1, 2);
			rh = yinit - cp(1, 2);
		end
	
		if rw == 0
			rw = 1;
		end

		if rh == 0 
			rh = 1;
		end

		set(userdata.h_selrect, 'Position', [startx starty rw rh]);
        
        startx = round(startx);                 starty = round(starty);
        endx   = round(startx + rw - 1);        endy   = round(starty + rh - 1);
        mesg = sprintf('(%d, %d)', startx, starty);
        showmsg(h_mainfig, 'selstart', mesg);
        mesg = sprintf('(%d, %d)', endx, endy);
        showmsg(h_mainfig, 'selend', mesg);
	end

	function endselection(object, event)
		set(h_mainfig, 'WindowButtonMotionFcn', @showpoint);
		set(h_mainfig, 'WindowButtonUpFcn', '');
		%set(h_mainfig, 'WindowButtonDownFcn', @);		
		
		%set(userdata.h_select, 'String', 'Select');
		%disp(uint16([startx starty startx+rw starty+rh]));
		
        pos = get(userdata.h_selrect, 'Position');
        startx = round(pos(1));                     starty = round(pos(2));
        endx   = round(pos(1) + pos(3) - 1);        endy   = round(pos(2) + pos(4) - 1);
        mesg = sprintf('(%d, %d)', startx, starty);
        showmsg(h_mainfig, 'selstart', mesg);
        mesg = sprintf('(%d, %d)', endx, endy);
        showmsg(h_mainfig, 'selend', mesg);
        userdata.selection = [startx starty endx endy];
		params.startx = startx;
		params.endx = endx;
		params.starty = starty;
		params.endy = endy;
		
		set(userdata.h_plot, 'enable', 'on');
		set(userdata.h_fit, 'enable', 'on');
        set(userdata.h_track, 'enable', 'on');
        %set(userdata.h_marker, 'enable', 'on');
        %set(userdata.h_stats, 'enable', 'on');
        %set(userdata.h_zoomin, 'enable', 'on', 'String', '+', 'callback', @onzoomin);
        
        set(h_mainfig, 'userdata', userdata);
    end
end
