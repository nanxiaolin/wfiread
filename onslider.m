function onslider(object, event)
% function that handles slider scrolling
    global h_mainfig;
    
    warning off;
	userdata = get(gcf, 'userdata');
    
    value = get(object, 'Value');
	frame = uint32(value) + 1;

	if frame == 0
		frame = 1;
	elseif frame > userdata.frames
		frame = userdata.frames;
	end

 	showframe(frame);

