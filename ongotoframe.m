function ongotoframe(obj, event)
% function that handles event of jumping to a particular frame
%

	global h_mainfig;
	
	h_CurrentFrame = findobj(h_mainfig, 'tag', 'edCurrentFrame');
	new_frame = str2num(get(h_CurrentFrame, 'String'));

	% showframe mode 1 = changing not by sliding the slider
	showframe(new_frame, 1);

return;

