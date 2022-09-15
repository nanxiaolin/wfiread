function onpan(object, event)
% function that handles the zoom function

	userdata = get(gcf, 'userdata');

	if object == 0	% external callback
		switch event
			case 'on'
				onzoom(0, 'off');
				pan on;
			case 'off'
				pan off;
				set(userdata.h_pan, 'value', 0);
		end
	
	else	% normal callback
		
		state = get(object, 'value');
		
		switch state
			case 1
				onzoom(0, 'off');
				pan on;
				
			case 0
				pan off;
		end
	end 