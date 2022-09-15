function onpsfsize(object, event)
% function that responds to changes in PSF size

	global params h_mainfig;
	
	userdata = get(h_mainfig, 'userdata');
	
	psf_size = str2double(get(userdata.h_psfsize, 'String'));
	
	if psf_size < 1
		psf_size = 1;
	end
	
	psf_size = round(psf_size);
	set(userdata.h_psfsize, 'String', sprintf('%i', psf_size));