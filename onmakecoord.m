function onmakecoord(object, event)
%
% function that produces a coordinate matrix for the entire
% movie and save it to a file with the same name as main data file

	global h_mainfig params;

	userdata = get(h_mainfig, 'userdata');
	%frames = userdata.frames;

	% get the filename for export from the user
	[~, name, ext] = fileparts(userdata.file);
	
	% generate a pre-set name for the output .cor file
    fullname = fullfile(userdata.pref_dir, userdata.file);
	temp = dir(fullname);
	name = [datestr(temp.datenum, 'yyyy.mm.dd') '_' name];
	
	pref_file = fullfile(userdata.exp_dir, name);
	% prompt users to choose the filename with a pre-set name
	extension = {'*.cor', 'Particle Coordinates File (*.cor)'};
    	[filename, pathname, ind] = uiputfile(extension, 'Choose a filename for the coordinates', pref_file);

	userdata.exp_dir = pathname;

    	if filename == 0
        	return;
    	end

	if ind == 1
		ext = '.cor';
	end
	
	filename = [filename ext];
    	fullname = fullfile(pathname, filename);

	% read the starting and ending frames
	pstart = str2num(get(userdata.h_palmstart, 'String'));
    pend   = str2num(get(userdata.h_palmend, 'String'));
    frameskip = str2num(get(userdata.h_frameskip, 'String')) + 1;
    fit_frames = pstart : frameskip : pend;
    frames = numel(fit_frames);
    pend = fit_frames(frames);

  % prepare a few parameters for findparticles to use without accessing controls repeatly
	params.startx = userdata.selection(1);
	params.starty = userdata.selection(2);
	params.endx   = userdata.selection(3);
	params.endy   = userdata.selection(4);

	params.factor = str2num(get(userdata.h_threshold, 'String'));
	params.sig_min = str2num(get(userdata.h_sigmamin, 'String'));
	params.sig_max = str2num(get(userdata.h_sigmamax, 'String'));

	params.meth = get(userdata.h_mnuPF, 'value');
	params.sm_area = str2num(get(userdata.h_smootharea, 'String'));
      
    
	% define the maximum number of particles
    numObject = findparticles(0, pstart);
    maxparticles = 1.5 * (pend - pstart + 1) * numObject;

	if pstart < 1
		pstart = 1;
	end
		
	if pend > userdata.frames
		pend = userdata.frames;
    end

	% prepare a matrix that holds all information; format of matrix:
    	% frame number, x, y, amplitude, sigma_x, sigma_y, BK_noise, goodness
    	% the first row is different from others:
    	% startx, starty, endx, endy, frames, num_fiducials, reserved, reserved
        
	tempcoords = zeros(maxparticles, 8);
	pf = get(userdata.h_mnuPF, 'value');
	if pf == 1
		pf_method = 'NMS';  % non-maximal suppression
	elseif pf == 2
		pf_method = 'SIT';	% simple intensity threshold
	end

	gf = get(userdata.h_mnuGF, 'value');
	if gf == 1
		gf_method = 'LSF';	% least square fitting
	elseif gf == 2
		gf_method = 'MLE';  	% maximum likelihood estimation
	end
	

	% smooth the markerpos data - removes fast fluctuations in marker position data.
	mp = zeros(frames, 2);
	if userdata.markernum > 0    
	    mp(:, 1) = medfilt1(userdata.markerpos(1 : frames, 1), 2);
    	mp(:, 2) = medfilt1(userdata.markerpos(1 : frames, 2), 2);
	end

	numparticles = 1;

	% populate the first row with file information
	if userdata.h_selrect ~= -1			% no selection; full image
		tempcoords(1, 1:4) = userdata.selection(1:4);
	    startx = userdata.selection(1);
		starty = userdata.selection(2);
	else
		tempcoords(1, 1) = 1;					
		tempcoords(1, 2) = 1;
		tempcoords(1, 3) = userdata.width;		
		tempcoords(1, 4) = userdata.height;  
		startx = 1;
		starty = 1;
	end
	
	tempcoords(1, 5) = frames;
	tempcoords(1, 6) = userdata.markernum;
	
	stopped = 0;
	set(userdata.h_makecoord, 'string', 'STOP', 'callback', @stop_pressed);
	
	
    fit_stack_set = 0;
	
	% now start to extract particle coordinate info
	for j = 1 : frames
        
        i = fit_frames(j);
		if stopped == 1
			stop_makecoord;
			return
		end
	
		[numObject, ~, sx, sy, fit_boxes] = findparticles(0, i);		
        
        if numObject == 0
            continue;
        end        
        
        if fit_stack_set == 0    % need to setup the fitting stack
            showmsg(h_mainfig, 'message', 'Preparing matrices for particle coordinates ...');
            pause(0.001);
            [fit_height, fit_width, ~] = size(fit_boxes);
            fit_stack = zeros(fit_height, fit_width, maxparticles);
            fit_stack_set = 1;
            showmsg(h_mainfig, 'message', 'Preparing matrices for particle coordinates ... Done.');
            pause(0.001);
        end          
            
        % apply stage and offset corrections
        tempcoords(numparticles+1:numparticles+numObject, 1) = i;
        tempcoords(numparticles+1:numparticles+numObject, 2) = -mp(j, 1) + sx(1:numObject) -1 - params.startx;
        tempcoords(numparticles+1:numparticles+numObject, 3) = -mp(j, 2) + sy(1:numObject) -1 - params.starty;
        %[i -mp(i, 1) -mp(i, 2) 0 0 0 0 0]; % intensity(j) sigmax(j) sigmay(j) noise(j) finess(j)];		

        % add the fit_box to the fit_stack
        fit_stack(:, :, numparticles : numparticles+numObject-1) = fit_boxes(:, :, 1:numObject); 
        
        numparticles = numparticles + numObject;

		if(i==pstart || i==pend || mod(j, 10)==0)
			tmsg = sprintf('Generating lists of particle for frame %d (of %d frames) with total %d particles', j, frames, numparticles-1);
			showmsg(h_mainfig, 'message', tmsg);
			pause(0.001);
		end
    end
    
    stacks = fit_stack(1:fit_height, 1:fit_width, 1:numparticles-1);
    %save('stacks.mat', 'stacks', '-MAT');
    %save('params.mat', 'params', '-MAT');
	
    % now need to fit all the fit_boxes and make adjustments to the
    % coordinates
    
    step_size = (numparticles-1);
    if step_size <=1000
        step_size = 1000;
    end
    steps = ceil((numparticles-1)/step_size);

    for i=1:steps
        if stopped == 1
			stop_makecoord;
			return
		end
        
        start_part = (i-1)*step_size + 1;
        
        %if start_part == 1 % do not overwrite the first row - that's where the information about the stacks are stored
        %    start_part =2
        %end
        end_part = start_part + step_size -1;
        if end_part > numparticles-1
            end_part = numparticles-1;
        end
        %end_part
        output = fitgaussc(stacks(:, :, start_part:end_part), (end_part - start_part + 1), 1e-3, 20)';
        
        % output parameter order: b, a, y0, x0, sigy, sigx, goodness,
        % bk_rms, iterations
        
        % save the coords 
        tempcoords(start_part+1 : end_part+1, 2) = tempcoords(start_part+1: end_part+1, 2) + output(1:(end_part - start_part +1), 4) + startx - 1; % x
        tempcoords(start_part+1 : end_part+1, 3) = tempcoords(start_part+1: end_part+1, 3) + output(1:(end_part - start_part +1), 3) + starty - 1; % y
        tempcoords(start_part+1 : end_part+1, 4) = output(1:(end_part - start_part +1), 2); % intensity
        tempcoords(start_part+1 : end_part+1, 5) = output(1:(end_part - start_part +1), 6); % sigx
        tempcoords(start_part+1 : end_part+1, 6) = output(1:(end_part - start_part +1), 5); % sigy
        tempcoords(start_part+1 : end_part+1, 7) = output(1:(end_part - start_part +1), 8); % bk_rms
        tempcoords(start_part+1 : end_part+1, 8) = output(1:(end_part - start_part +1), 7); % goodness
        
        msg = sprintf('Extracting centroids for %d particles (%.1f %% finished).', numparticles-1, 100.0*end_part/(numparticles-1));
        showmsg(h_mainfig, 'message', msg);
        pause(0.001);
    end
    
    clear mex;
    clear('output');
    
    %numparticles
    % need to filter out all those bad fittings  
    msg = sprintf('Examining particle coordinates ...');
    showmsg(h_mainfig, 'message', msg);
    pause(0.001);
    temp_1st = tempcoords(1, :);    % record the first line
    tempcoords = tempcoords(2:numparticles, :);
    r = find(tempcoords(:, 7) > 0); % this filters out all bad fittings
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 2) > params.startx); 
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 2) < params.endx);
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 3) > params.starty);
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 3) < params.endy);
    
    % filter per sigma range
    
    
    coords = [temp_1st; tempcoords(r, :)];
    msg = sprintf('Examining particle coordinates ... Done. %d particles saved (%d discarded)', numel(r), numparticles - numel(r)-1);
    showmsg(h_mainfig, 'message', msg);
    pause(0.001);

	% save parameters to the designated file
	
    showmsg(h_mainfig, 'message', 'Saving the coordinate files ... ');
	save(fullname, 'coords', '-MAT');
    %pause(0.5);
    %save('stacks.mat', 'stacks', '-MAT');
    %showmsg(h_mainfig, 'message', 'Saving the coordinate files ... Done');

	% save the marker information
	if(userdata.markernum > 0)
		fiducials = userdata.markers;
	else
		fiducials = [];
	end
	save(fullname, 'fiducials', '-MAT', '-APPEND');

	% save other information to the file
	save(fullname, 'pf_method', 'gf_method', 'fullname', '-MAT', '-APPEND');

	set(h_mainfig, 'userdata', userdata);
	
	% show a few messages to notify user that tracking is done.
	showmsg(h_mainfig, 'message', sprintf('Coord extraction finished (%d frames; %d Particle)s. Data saved to %s.', frames, numel(r), fullname));
	msgbox('Coordinate extraction has successfully finished. Click OK to continue.', 'Task Finished.', 'modal');
	
	% clear variables
   	set(userdata.h_makecoord, 'string', 'Make Coord File', 'callback', @onmakecoord);
 	clear;

	function stop_pressed(event, obj)
		stopped = 1;
	end

	function stop_makecoord
    	set(userdata.h_makecoord, 'string', 'Make Coord File', 'callback', @onmakecoord);
    	showmsg(h_mainfig, 'message', 'Coordinate extraction stopped.');
    	clear;
	end
end

	
