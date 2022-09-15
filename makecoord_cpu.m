function makecoord_cpu_lv
%
% function that produces a coordinate matrix for the entire
% movie and save it to a file with the same name as main data file
% 
% Update on 02/20/2020. Xiaolin Nan (OHSU)
%  1. adapted the original makecoord_cpu to handle large vidoes
%  2. changed the workflow for the fitting process to minimize the memory
%     use by intermediate variables (e.g. fitstack) so most of the memory
%     can be used for storing particle coordinates.
% Format of the tempcoords matrix
%   [frame number, x, y, amplitude, sigma_x, sigma_y, BK_noise, goodness]
%   
%   the first row is different from others:
%   startx, starty, endx, endy, frames, num_fiducials, reserved, reserved


	global h_mainfig params;

	userdata = get(h_mainfig, 'userdata');
	%frames = userdata.frames;
	
	% prepare a few parameters for findparticles to use without accessing controls repeatly
	params.startx = userdata.selection(1);
	params.starty = userdata.selection(2);
	params.endx   = userdata.selection(3);
	params.endy   = userdata.selection(4);
	
	% check the width and height of the input field of view
	if (params.endx - params.startx + 1 < 15) || (params.endy - params.starty + 1 < 15)
		errordlg('Current selection box too small (<15 pixels). Please pick a larger region or right click to use full FOV.', 'Make Coord Error');
		return;
	end

	% get the filename for export from the user
	[~, name, ext] = fileparts(userdata.file);
	
	% generate a pre-set name for the output .cor file
    tiffullname = fullfile(userdata.pref_dir, userdata.file);
	temp = dir(tiffullname);
	
	if isempty(regexp(name, '^\d{2,4}.\d{1,2}.\d{1,2}', 'match'))
		name = [datestr(temp.datenum, 'yyyy.mm.dd') '_' name];
	end
	
	pref_file = fullfile(userdata.pref_dir, name);
	
	% the following removes the annoying _MMStack_Pos0 ... part from the file names
	f = cell2mat(regexp(pref_file, '_MMStack_Pos\d\w*.ome', 'match'));
	
	if ~isempty(f)
		f_pos = findstr(pref_file, f);
		pref_file(f_pos : f_pos+length(f)-1) = [];
	end
	
	% prompt users to choose the filename with a pre-set name
	extension = {'*.cor', 'Particle Coordinates File (*.cor)'};
    	[corfilename, corfilepath, ind] = uiputfile(extension, 'Choose a filename for the coordinates', pref_file);

	%userdata.exp_dir = pathname;

    if corfilename == 0
        showmsg(h_mainfig, 'message', 'Coordinate extraction cancelled by user.');
    	return;
    end

	if ind == 1
		ext = '.cor';
	end
	
	if isempty(regexp(corfilename, '.cor','match'))
		corfilename = [corfilename ext];
	end
    corfullname = fullfile(corfilepath, corfilename);
		
	% read the starting and ending frames
	pstart = str2double(get(userdata.h_palmstart, 'String'));
    pend   = str2double(get(userdata.h_palmend, 'String'));
    %frameskip = str2double(get(userdata.h_frameskip, 'String')) + 1;
    % check for the inputs
    if pstart < 1
		pstart = 1;
	end
		
	if pend > max(userdata.actualframes)
		pend = max(userdata.actualframes);
    end
    fit_frames = pstart : pend;
    numframes = numel(fit_frames);
    %pend = fit_frames(frames);

	params.factor = str2double(get(userdata.h_threshold, 'String'));
	params.sig_min = str2double(get(userdata.h_sigmamin, 'String'));
	params.sig_max = str2double(get(userdata.h_sigmamax, 'String'));
	params.psf_size = str2double(get(userdata.h_psfsize, 'String'));
	params.meth = get(userdata.h_mnuPF, 'value');
	params.contrast_factor = str2double(get(userdata.h_contrastfactor, 'String'));
	
% smooth the markerpos data - removes fast fluctuations in marker position data.
	mp = zeros(numframes, 2);
	if userdata.markernum > 0    
	    mp(:, 1) = medfilt1(userdata.markerpos(:, 1), 2);
    	mp(:, 2) = medfilt1(userdata.markerpos(:, 2), 2);
	end	
      
%% estimate the number of particles per frame by performing
	% findparticles on all the sampler frames - which should give a rather
	% accurate estimate on the total # of particles in the end
    msg = 'Preparing for particle identification and localization. Please wait ...';
    showmsg(h_mainfig, 'message', msg);   pause(0.02);
    numObject = 0; steps = floor(numframes / 100);
	if steps < 1
		steps = 1;
	end
	
	frame_count = 0;
    for f = pstart : steps : pend
        numObject = numObject + findparticles(0, f);
        frame_count = frame_count + 1;
    end
  
    est_particles = ceil(numObject * numframes / frame_count);
    msg = sprintf('Estimated total particle #: %d. Allocating memory for particle coordinates ...', est_particles);
    showmsg(h_mainfig, 'message', msg);
    pause(0.1);
	    
    % allow for 20% more particles than estimated
    maxparticles = ceil(1.2 * est_particles);

	% prepare a matrix that holds all information
	try
        tempcoords = zeros(maxparticles, 8, 'single');
    catch ME
        showmsg(h_mainfig, 'message', 'Something wrong with memory allocation (out of memory?). Try use fewer frames to generate the .cor file.');
        %rethrow(ME);
        return
    end
    
%% populate the first row with file information
	
    % use the default methods for particle 
    pf_method = 'NMS';  % non-maximal suppression
	gf_method = 'LSF';	% least square fitting
	temp_1st = zeros(1, 8, 'single');
   
	if userdata.h_selrect ~= -1			% no selection; full image
		temp_1st(1, 1:4) = userdata.selection(1:4);
	    startx = userdata.selection(1);
		starty = userdata.selection(2);
	else
		temp_1st(1, 1) = 1;					
		temp_1st(1, 2) = 1;
		temp_1st(1, 3) = userdata.width;		
		temp_1st(1, 4) = userdata.height;  
		startx = 1;
		starty = 1;
	end
	
	temp_1st(1, 5) = numframes; 
    
    % marker definition is disabled in the large video mode
    % code for the mp definition has been removed
	temp_1st(1, 6) = 0; % userdata.markernum
	
%% read, identify, and localize each particle  
    
    % note: due to the design of the findparticles (relying on ongetframe),
    % the following implementation directly calls smlocalize, which is 
    % the combined version of fp_nms and fitgauss 
    % img = fullimg(starty : endy, startx : endx);
    % [num_objects, centroids] = smlocalize(img, factor, sig_min, sig_max);
    % 
    % the program also makes direct calls to read the TIF stack instead of
    % going through the ongetframe function.
	
   
    % change the button
    set(userdata.h_makecoord, 'string', 'STOP', 'callback', @stop_pressed);
	
    
%% main loop for reading and analyzing the raw image frames
    stopped = 0;	
    counted_frames = 0;
	sig_min = params.sig_min;
	sig_max = params.sig_max;
	thresh = params.factor;
	contrast_factor = params.contrast_factor;
	max_iter = 20;
	err = 1e-3;
	nms_region = 2;
	mask_region = params.psf_size;
	%min_pix = 4;
	numObject = 0;		% numobjects per frame
    numparticles = 0;	% total number of objects
	endx = params.endx;
	endy = params.endy;
	est_particles = ceil(est_particles / 10000)/100;		% turn the estimate into Millions
	
	% re-load smlocalize
	clear smlocalize;
	tic
	
    for ifd = pstart : pend
        
 		if stopped == 1
			stop_makecoord;
			return
        end
        
        counted_frames = counted_frames + 1;
		%disp(counted_frames);
        
        % retrieve the image frame 
        img = ongetframe(ifd);

        [numObject, output] = smlocalize(img(starty:endy, startx:endx), nms_region, mask_region, thresh, contrast_factor, sig_min, sig_max, err, max_iter); 
			% smlocalize parameters: img, nms_region, mask_rgn, thresh_factor, min_pix, sig_min, sig_max, err, max_iter
			% the threshold 1 is equivalent to 3-4 RMS in the previous processing methods.
			% output is the coords' matrix;
			% fp_nms(img,params.factor, params.sig_min, params.sig_max, params.startx, params.starty);
						
			% output of smlocalize: 
			% numobj = number of actual objects identified as local max and passed fitting quality check
			% coords = 10 x N matrix (N usually > numobj) container matrix with the following format
			%	coords(1, :) = b;			background
			%	coords(2, :) = a;			fitting amplitude
			%	coords(3, :) = x0;			x position == note: x and y swapped before smlocalize returns to be compatible with
			%	coords(4, :) = y0;			y position == conventional notations where x (cols, slow) goes before y (rows, fast)
			%	coords(5, :) = sigx;		sigma in x == note: the same as above, with (sigx, sigy) swapped 
			%	coords(6, :) = sigy;		sigma in y == note above
			%	coords(7, :) = goodness;	goodness of fitting (the smaller the better)
			%	coords(8, :) = bk_rms;   	backgroun residual noise after fitting
			%	coords(9, :) = iter;		number of iterations before reaching the desired error
			%	coords(10, :)= local_rms;	local RMS computed using an area larger (currently 3x) than the mask_region in order to
			%								definitively call a particle out.
		
		% record the coords
		tempcoords(numparticles+1 : numparticles+numObject, 1) = ifd;												% frame number
		tempcoords(numparticles+1 : numparticles+numObject, 2) = output(3, 1:numObject) - mp(counted_frames, 1);	% x. 
		tempcoords(numparticles+1 : numparticles+numObject, 3) = output(4, 1:numObject) - mp(counted_frames, 2);	% y. 
		tempcoords(numparticles+1 : numparticles+numObject, 4) = output(2, 1:numObject);							% fitting amplitude
		tempcoords(numparticles+1 : numparticles+numObject, 5) = output(5, 1:numObject); 							% sig_x
		tempcoords(numparticles+1 : numparticles+numObject, 6) = output(6, 1:numObject);							% sig_y
		tempcoords(numparticles+1 : numparticles+numObject, 7) = output(8, 1:numObject);							% bk_rms
		tempcoords(numparticles+1 : numparticles+numObject, 8) = output(7, 1:numObject);							% goodness
		
		numparticles = numparticles + numObject;
		        
        if (counted_frames == 1 || (mod(counted_frames, 20) == 0) || (counted_frames == numframes))
			est_time = (toc / 60) * (numframes / counted_frames - 1);
            msg = sprintf('Coordinate extraction in progress. Processing frame %d (of %d frames) with %d particles (est. total particle: %.2f M; time left: %.1f min).', counted_frames, numframes, numparticles, est_particles, est_time);
            showmsg(h_mainfig, 'message', msg);
            pause(0.01);
        end
    end
    
    toc

	% filter out all those bad fittings  
    msg = sprintf('Examining particle coordinates ...');
    showmsg(h_mainfig, 'message', msg);
    pause(0.001);
	
	r = find(tempcoords(:, 7) > 0); % this throws out all the extra rows
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 2) > 0); 
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 2) < (endx - startx +1));
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 3) > 0);
    tempcoords = tempcoords(r, :);
    r = find(tempcoords(:, 3) < (endy - starty +1));
    coords = [temp_1st; tempcoords(r, :)];

    msg = sprintf('Examining particle coordinates ... Done. %d particles saved (%d discarded)', numel(r), numparticles - numel(r)-1);
    showmsg(h_mainfig, 'message', msg);
    pause(0.001);
  	
	% save other information to the file
 	save(corfullname, 'pf_method', 'gf_method', 'tiffullname', '-MAT', '-v7.3'); 
	
	% save the marker information
	if(userdata.markernum > 0)
		fiducials = userdata.markers;
	else
		fiducials = [];
	end
	save(corfullname, 'fiducials', '-MAT', '-APPEND');

	showmsg(h_mainfig, 'message', 'Saving the coordinate files ... ');
 	save(corfullname, 'coords', '-MAT', '-APPEND');
    pause(0.02);
    showmsg(h_mainfig, 'message', 'Saving the coordinate files ... Done');
	pause(0.02);
 	
	set(h_mainfig, 'userdata', userdata);
 	showmsg(h_mainfig, 'message', sprintf('Coord extraction finished. Data saved to %s.', corfullname));
 	%msgbox('Coordinate extraction has successfully finished. Click OK to continue.', 'Task Finished.', 'modal');
 	
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

	
