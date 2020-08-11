function [pos ints sigx sigy] = ontrack(object, event)
% function that tracks the 2-d position of particles in the selected frames
%
% change on 04/01/2010:
%  now uses the maximum pixel as the initial (x, y)
%  and adjusts the selection area according to x and y displacements

    global h_mainfig;
    userdata = get(h_mainfig, 'userdata');
	
    %if object ~= 0
    pstart = str2num(get(userdata.h_palmstart, 'String'));
    pend   = str2num(get(userdata.h_palmend, 'String'));
        
    frameskip = str2num(get(userdata.h_frameskip, 'String')) + 1;
    fit_frames = pstart : frameskip : pend;
    frames = numel(fit_frames);
    pend = fit_frames(frames); 
    %else
    %   pstart = 1;
    %    pend = userdata.frames;
    %end
    
    %frames = pend - pstart + 1;

	% prepare returning parameters
    pos = zeros(frames, 2);
	sigx = zeros(frames, 1);
	sigy = zeros(frames, 1);
	ints = zeros(frames, 1);

    mesg = 'Tracking particle ...';
    showmsg(h_mainfig, 'message', mesg);
	pause(0.01);
    color = rand(1, 3);

	% treat the first frame to get initial coordinates
	[img, xoff, yoff] = getselection(pstart);
	[x, y, sx, sy, a]= fitgauss(img, 1e-3);
    %output = fitgaussc(img, 1, 1e-4, 20);
    %x  = output(4);   y = output(3);
    %sx = output(6);  sy = output(5);
    %a = output(2);
    
    %
	pos(1, 1) = x + xoff -1;
	pos(1, 2) = y + yoff -1;
	sigx(1) = sx;
	sigy(1) = sy;
	ints(1) = a;
	%[width height] = size(img);

    for i = 2 : frames
        
        j = fit_frames(i);
        
		% determine the tracking region
		startx = floor(pos(i-1, 1) - 5);
		starty = floor(pos(i-1, 2) - 5);
        
		if startx < 1
			startx = 1;
		end

		if starty < 1
			starty = 1;
		end
		
		endx = ceil(pos(i-1, 1) + 5);
		endy = ceil(pos(i-1, 2) + 5);

		if endx > userdata.width
			endx = userdata.width;
		end

		if endy > userdata.height
			endy = userdata.height;
		end
		
		% retrieve a fitting area surrounding the previous centriod
		[img, xoff, yoff] = ongetframe(j, [startx starty endx endy]);

		% perform gaussian fitting
        [x, y, sx, sy, a] = fitgauss(img, 1e-4);
        
        %output = fitgaussc(img, 1, 1e-3, 20)
        %x = output(4);
        %y = output(3);
        %sx = output(6);
        %sy = output(5);
        %a = output(2);
        
      
		% adjust coordinates to whole image
		pos(i, 1) = x + xoff - 1;
		pos(i, 2) = y + yoff - 1;
		sigx(i) = sx;		sigy(i) = sy;		ints(i) = a;
		
		% make sure that the tracking does not go wrong dramatically
		distance = sqrt((pos(i, 1) - pos(i-1, 1))^2 + (pos(i, 2) - pos(i-1, 2))^2);
        
		if distance > 1
			pos(i, 1) = pos(i-1, 1);
			pos(i, 2) = pos(i-1, 2);
			sigx(i) = sigx(i-1);
			sigy(i) = sigy(i-1);
			ints(i) = ints(i-1);
		end
    end

	% adjust the coordinates relative to fiducial markers if the latter is defined
    if (userdata.markernum > 0) && (object ~= 0)
            %mean_correct(1:2) = mean(userdata.markerpos(:, i, 1:2), 1) - mean(userdata.markerpos(:, 1, 1:2), 1);
            pos(:, 1) = pos(:, 1) - userdata.markerpos(1 : frames, 1);
            pos(:, 2) = pos(:, 2) - userdata.markerpos(1 : frames, 2);
    end

    % enable 'marker def'
    set(userdata.h_marker, 'enable', 'on');

    % draw the particle
    k = userdata.currentframe; % - pstart + 1;
    if object ~= 0  % not from external call
        figure(h_mainfig); hold on; plot(pos(k - pstart + 1, 1), pos(k - pstart + 1, 2), 's', 'LineWidth', 2, 'MarkerSize', 18, 'MarkerEdgeColor', color);
    
        % draw the displacement trajecotry
        displ = displace(pos);
        %f = fit_frames;;
        figure(userdata.figdisplace); set(gcf, 'numbertitle', 'off', 'name', 'Displacement Trajectory');
        hold on; plot(fit_frames, displ, 'Color', color);
        xlabel('Frame No.');    ylabel('Displacement (pixel)');
        xlim([pstart max(pend, pstart + 1)]);       ylim([0 max(1, max(max(ylim), max(displ)))]);
        grid on; box on;

		fluctx = std(pos(1:frames, 1));
		flucty = std(pos(1:frames, 2));
        
		mesg = sprintf('Tracking particle ... done. Std_X = %.2f; Std_Y = %.2f (unit: pixel)', fluctx, flucty);
        % draw the position trajectory
        %figure(userdata.figposition); set(gcf, 'numbertitle', 'off', 'name', 'Position Trajectory');
        %hold on; plot(pos(:, 1)-pos(1, 1), pos(:, 2) - pos(1, 2), 'Color', color);
        %xlabel('X Position (pixel)');   ylabel('Y Position (pixel)');
        %xlim([-1 1]);        ylim([-1 1]);
        %axis equal; grid on;
	else
		mesg = 'Tracking particle ... done.';
    end
    
    showmsg(h_mainfig, 'message', mesg);
return
