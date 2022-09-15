function checkzoom(~,~)
% function that checks the current zoom level and make sure it does go beyond 1
	
	global h_mainfig;

	userdata = get(h_mainfig, 'userdata');
	
	ax = xlim;
	ay = ylim;
	
	if ax(1)<1 
		ax(1) = 1;
	end

	if ax(2) > userdata.width
		ax(2) = userdata.width;
	end
	
	if ay(1) < 1
		ay(1) = 1;
	end

	if 	ay(2) > userdata.height
		ay(2) = userdata.height;
	end
	
	% check the image ratio
	img_ratio = userdata.height / userdata.width;
	win_ratio = (ay(2) - ay(1)) /(ax(2) - ax(1));
	
	if win_ratio > img_ratio	% zoom window is taller
		ay(2) = ay(1) + img_ratio * (ax(2) - ax(1));
	else
		ax(2) = ax(1) + (ay(2) - ay(1)) / img_ratio;
	end
	
	xlim(ax); ylim(ay);
	
	% if there are markers on display, then update the markers by running 'findparticles' 
	if userdata.h_particlecenters ~= -1
		findparticles(1);
	end
	
