function ongotoframe(obj, event)
% function that handles event of jumping to a particular frame
%

	global h_mainfig;
	
	h_CurrentFrame = findobj(h_mainfig, 'tag', 'edCurrentFrame');
	new_frame = str2double(get(h_CurrentFrame, 'String'));
	
	userdata = get(h_mainfig, 'userdata');
	if new_frame > userdata.frames
		set(h_CurrentFrame, 'String', sprintf('%d', userdata.frames));
		new_frame = userdata.frames;
	end

	% showframe mode 1 = changing not by sliding the slider
	showframe(new_frame, 1);

return;

