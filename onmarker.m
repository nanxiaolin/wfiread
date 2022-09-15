function onmarker(object, event)
%
% function that adds currently selected particle as a marker
% remember that marker is always from frame 1 to end of movie
% so that when pstart and pend changes there is no need to redefine markers
%
% marker parameter saved as:
%	[x y sigx sigy intensity]
% the markers array is a n x 5 x frames matrix
%   where n is the number of markers

    global h_mainfig;
    userdata = get(h_mainfig, 'userdata');
    
    pstart = str2double(get(userdata.h_palmstart, 'String'));
    pend   = str2double(get(userdata.h_palmend, 'String'));
    %frameskip = str2num(get(userdata.h_frameskip, 'String'));
    %fit_frames = pstart : frameskip : pend;
    %frames = numel(fit_frames);
    %pend = fit_frames(frames);
    
	frames = pend - pstart + 1;

	% retrieve parameters of current particle from starting to ending frames
    [pos, sigx, sigy, ints] = ontrack(0, 0);

	userdata.markernum = userdata.markernum + 1;

    if userdata.markernum == 1
        set(userdata.h_markerdel, 'enable', 'on');

		% initialize the userdata.markers matrix - at least 2 markers 
		userdata.markers = zeros(1, frames, 5);
	end

	userdata.markers(userdata.markernum, 1:frames, 1:5) = [pos(:, 1) pos(:, 2) sigx sigy ints];

    % calculate the average marker_pos for convenience in other function calls (such as makecord)
	mean_pos = zeros(frames, 2);
	for i = 1 : userdata.markernum
		x = userdata.markers(i, 1:frames, 1);	x = x';
		y = userdata.markers(i, 1:frames, 2);	y = y';
	
		mean_pos(:, 1) = mean_pos(:, 1) + x - x(1);
		mean_pos(:, 2) = mean_pos(:, 2) + y - y(1);
	end
	userdata.markerpos = mean_pos / userdata.markernum;
	
    % draw a cross on the particle
    figure(h_mainfig); hold on;
	draw_frame = userdata.currentframe - pstart + 1;
	if draw_frame < 1
		draw_frame = 1;
	end
    userdata.markerhandles(userdata.markernum) = plot(pos(draw_frame, 1), pos(draw_frame, 2), 'g+', 'LineWidth', 2, 'MarkerSize', 6);

	% also box the particle with the same color as the displacement trajectory
    color = rand(1,3);
    figure(h_mainfig); hold on; plot(pos(draw_frame, 1), pos(draw_frame, 2), 's', 'LineWidth', 2, 'MarkerSize', 18, 'MarkerEdgeColor', color);

	% calculate the stdx and stdy for the added marker
    pos(:, 1) = pos(:, 1) - userdata.markerpos(1 : frames, 1);
    pos(:, 2) = pos(:, 2) - userdata.markerpos(1 : frames, 2);

	fluctx = std(pos(1:frames, 1));
	flucty = std(pos(1:frames, 2));
	mesg = sprintf('Particle at (%d, %d) added as a fiducial marker. Std_X = %.2f; Std_Y = %.2f (unit: pixel)', uint16(pos(1, 1)), uint16(pos(1, 2)), fluctx, flucty);
    showmsg(h_mainfig, 'message', mesg);

	% also show the displacement of the current marker after adding it to the marker pool
    displ = displace(pos);
    f = pstart: pend;
    figure(userdata.figdisplace); set(userdata.figdisplace, 'numbertitle', 'off', 'name', 'Displacement Trajectory');
    hold on; plot(f, displ, 'Color', color);
    xlabel('Frame No.');    ylabel('Displacement (pixel)');
    xlim([pstart max(pend, pstart + 1)]);       ylim([0 max(1, max(max(ylim), max(displ)))]);
    grid on; box on;

    % if there are more than one fiducial marker - enable the 'make coord file' button
    %if userdata.markernum > 1
	set(userdata.h_makecoord, 'enable', 'on');
	%end
	
	% we need to disable the palm start and ending frames
	set(userdata.h_palmstart, 'enable', 'off');
	set(userdata.h_palmend, 'enable', 'off');

    set(h_mainfig, 'userdata', userdata);
return
