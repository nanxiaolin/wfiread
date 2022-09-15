function onzoom(object, event)
% function that handles the zoom function

	userdata = get(gcf, 'userdata');

	if object == 0	% external callback
		switch event
			case 'on'
				onpan(0, 'off');
				zoom on;
				
			case 'off'
				zoom off;
				set(userdata.h_zoom, 'value', 0);
		end
	
	else	% normal callback
		
		state = get(object, 'value');
		
		switch state
			case 1
				onpan(0, 'off');
				zoom on;
				
			case 0
				zoom off;
		end
	end 