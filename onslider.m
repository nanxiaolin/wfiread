function onslider(object, event)
% function that handles slider scrolling
    global h_mainfig;
    
    warning off;
	userdata = get(h_mainfig, 'userdata');
    
    value = get(object, 'Value');
	frame = value + 1;

	if frame == 0
		frame = 1.0;
	elseif frame > userdata.frames
		frame = userdata.frames;
	end

 	showframe(frame);

