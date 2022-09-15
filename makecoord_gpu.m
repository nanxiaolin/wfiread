function makecoord_gpu
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	global h_mainfig params;
	global imgdata;
	
	userdata = get(h_mainfig, 'userdata');
	[~, name, ext] = fileparts(userdata.file);
    fullname = fullfile(userdata.pref_dir, userdata.file);
	temp = dir(fullname);
	name = [datestr(temp.datenum, 'yyyy.mm.dd') '_' name];
	pref_file = fullfile(userdata.exp_dir, name);
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
	pstart = str2double(get(userdata.h_palmstart, 'String'));
    pend   = str2double(get(userdata.h_palmend, 'String'));
    frameskip = str2double(get(userdata.h_frameskip, 'String')) + 1;
    fit_frames = pstart : frameskip : pend;
    frames = numel(fit_frames);
    pend = fit_frames(frames);
	params.startx = userdata.selection(1);
	params.starty = userdata.selection(2);
	params.endx   = userdata.selection(3);
	params.endy   = userdata.selection(4);
	params.factor = str2double(get(userdata.h_threshold, 'String'));
	params.sig_min = str2double(get(userdata.h_sigmamin, 'String'));
	params.sig_max = str2double(get(userdata.h_sigmamax, 'String'));
	params.meth = get(userdata.h_mnuPF, 'value');
	params.sm_area = str2double(get(userdata.h_smootharea, 'String'));
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
    
    if pstart < 1
		pstart = 1;
	end
	if pend > userdata.frames
		pend = userdata.frames;
    end
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
tic;
	
	% define the maximum number of particles. Max Particles is set as 1.5*number found in first frame.
    % (used to preallocate memory for speed).  Please refer to the "notes_for_future.txt" file for a 
    % note about the portability of this section.
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    count = 0;
    max_found = 0;
    mean_found = 0;
    mf = ceil(frames / 1000) + 10;
    step = floor((pend-pstart)/mf);
    f = [pstart, step*(1:mf)];        
    for i = 1:mf+1
        count = findparticles(0, f(i));
        max_found = max([max_found; count]);
        mean_found = mean_found + (count/(mf+1));
    end
    maxparticles = ceil(1.5 * frames * mean_found);
    numP = ceil(userdata.width * userdata.height / 80);
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    % remove fast fluctuations in marker position data.
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	mp = zeros(frames, 2);
	if userdata.markernum > 0    
	    mp(:, 1) = medfilt1(userdata.markerpos( :, 1), 2);
    	mp(:, 2) = medfilt1(userdata.markerpos( :, 2), 2);
	end
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	% prepare a matrix that holds all information; format of matrix:
    % frame number, x, y, amplitude, sigma_x, sigma_y, BK_noise, goodness
    % the first row is different from others:
    % startx, starty, endx, endy, frames, num_fiducials, reserved, reserved
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	tempcoords = zeros(maxparticles, 8);
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	% populate the first row with file information
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    	
    % ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % particle finding segment (non-maximal suppression).
    % ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	% stopped = 0;
	% set(userdata.h_makecoord, 'string', 'STOP', 'callback', @stop_pressed);
	showmsg(h_mainfig, 'message', 'Preparing for particle finding using GPU...');
    pause(0.001);

	data = imgdata(fit_frames, params.startx : params.endx, params.starty : params.endy);
	data = permute(data,[2,3,1]);  % need to get rid of this by changing input order to Find.cu ~ it's slow.
	% if stopped == 1
	% 	stop_makecoord;
	% 	return
	% end
    warning('off', 'all');

    mask_rgn = 4;
    stream_width = 4096;
    min_pix = 7;
    chunk_size = stream_width;
    
    r = mod(frames,chunk_size);
    n = (frames-r)/(chunk_size);

    % preallocate memory for nms output 
    coord_stackX = zeros(maxparticles,1);
    coord_stackY = zeros(maxparticles,1);
    particlesPerFrame = zeros(frames,1);
    stacks = zeros(9, 9, maxparticles);
    if r>0
        m=1;
    else
        m=0;
    end
    count = 1;
	
	% gpu #1 = P4; #2 = C2075_1; #3 = C2075_2; note that in cuda code, the numbers start with 0
	gpu_id = 2;
	gpu = gpuDevice(gpu_id);
	
    for i=1:n+m
        showmsg(h_mainfig, 'message', sprintf('Identifying particles in frames using %s ... current progress: %.1f%%', gpu.Name, 100*(i-1)/(n+1)));
        pause(0.01);
        start = 1 + (i-1)*chunk_size;
        if i<=n
            fin = i*chunk_size;
            [x, y, ppf, mask] = ...
                nms_gpu(data(:,:,start:fin), chunk_size, params.factor, numP, stream_width, mask_rgn, gpu_id-1);
        else
            fin = frames;
            [x, y, ppf, mask] = ...
                nms_gpu(data(:,:,start:fin), r, params.factor, numP, stream_width, mask_rgn, gpu_id-1);
        end
		
		% handle error
		if isempty(x) || isempty(y) || isempty(ppf) || isempty(mask)	% something wrong during the particle finding on the GPU
			showmsg(h_mainfig, 'message', 'Particle finding on GPU failed.');
			return;
		end
		
        ind = (x > 0);
        x = x(ind);
        y = y(ind);
        sub_stack = makestack(data(:,:,start:fin), x, y, mask, ppf, mask_rgn, min_pix);
        ind = (x > 0);
		N = sum(ppf);
        coord_stackX(count:count-1+N) = x(ind);
        coord_stackY(count:count-1+N) = y(ind);
        stacks(:,:,count:count-1+N) = double(sub_stack(:,:,ind));
        count = count + N;
        particlesPerFrame(start:fin) = ppf;
        clear x y ind N ppf
        clear sub_stack mask
    end
    count = count - 1;
    coord_stackX = coord_stackX(1:count) - mask_rgn;
    coord_stackX(coord_stackX<=0) = 1;
    coord_stackY = coord_stackY(1:count) - mask_rgn;
    coord_stackY(coord_stackY<=0) = 1;
    stacks = stacks(:,:,1:count);
    
    tempcoords(2:count+1,2) = coord_stackX - 2;
    tempcoords(2:count+1,3) = coord_stackY - 2;

    % add the x-y drift correction data (if present)
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    N = 1;
    for i = 1:frames
        count = particlesPerFrame(i);
        tempcoords(N+1:N+count, 2) = tempcoords(N+1:N+count, 2) - mp(i, 1);
        tempcoords(N+1:N+count, 3) = tempcoords(N+1:N+count, 3) - mp(i, 2);
        N = N + count;
    end
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	% store frame number for each particle.
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    N = 1;
    for j = 1 : frames
        i = fit_frames(j);
		count = particlesPerFrame(j);
        tempcoords(N+1:N+count, 1) = i;
		N = N + count;
    end
    Npar = N-1;
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
    
	% save('tempcoordsGPU.mat','tempcoords')
    % save('stacksGpu.mat', 'stacks', '-MAT');
    % save('params.mat', 'params', '-MAT');
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % This is the end of the particle finding segment.
    % ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    % This is the beginning of the gaussian fitting.
    % ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
%     if stopped == 1
% 		stop_makecoord;
% 		return
% 	end
	showmsg(h_mainfig, 'message', 'Beginning Gaussian fitting...');
    pause(0.001);

    stream_width = 16384;
    chunk_size = stream_width*4;
    max_iter = 20;
    fit_thresh = 1e-3;
    r = mod(Npar,chunk_size);
    N = (Npar-r)/chunk_size;

    output = zeros(Npar, 10);
	
	%for debugging
	return;

    for i=1:N+1
        showmsg(h_mainfig, 'message', sprintf('Extracting particle coordinates ... current progress: %.1f%%', 100*(i-1)/(N+1)));
        pause(0.001);
        start = 1 + (i-1)*chunk_size;
        if i<=N
            fin = i*chunk_size;
            o = fitgaussgpu(stacks(:,:,start:fin), chunk_size, fit_thresh, max_iter, stream_width)';
        else
            fin = Npar;
            o = fitgaussgpu(stacks(:,:,start:fin), r, fit_thresh, max_iter, stream_width)';
        end
        output(start:fin,:) = o;
    end

	showmsg(h_mainfig, 'message', 'Particle coordinate extraction done.');
    pause(0.001);
    % output parameter order: b, a, y0, x0, sigy, sigx, goodness,
    % bk_rms, iterations
        
    % save the coords 
    tempcoords(2:Npar, 2) = tempcoords(2:Npar, 2) + output(1:Npar-1, 3) + startx - 1; % x
    tempcoords(2:Npar, 3) = tempcoords(2:Npar, 3) + output(1:Npar-1, 4) + starty - 1; % y
    tempcoords(2:Npar, 4) = output(1:Npar-1, 2); % intensity
    tempcoords(2:Npar, 5) = output(1:Npar-1, 5); % sigx
    tempcoords(2:Npar, 6) = output(1:Npar-1, 6); % sigy
    tempcoords(2:Npar, 7) = output(1:Npar-1, 8); % bk_rms
    tempcoords(2:Npar, 8) = output(1:Npar-1, 7); % goodness
    clear mex;
    clear('output');
    
    % need to filter out all those bad fittings  
    msg = sprintf('Examining particle coordinates ...');
    showmsg(h_mainfig, 'message', msg);
    pause(0.001);
    temp_1st = tempcoords(1, :);    % record the first line
    tempcoords = tempcoords(2:Npar, :);
    r = (tempcoords(:, 7) > 0); % this filters out all bad fittings
    tempcoords = tempcoords(r, :);
    r = (tempcoords(:, 2) > params.startx); 
    tempcoords = tempcoords(r, :);
    r = (tempcoords(:, 2) < params.endx);
    tempcoords = tempcoords(r, :);
    r = (tempcoords(:, 3) > params.starty);
    tempcoords = tempcoords(r, :);
    r = (tempcoords(:, 3) < params.endy);
    coords = [temp_1st; tempcoords(r, :)];

    msg = sprintf('Examining particle coordinates ... Done. %d particles saved (%d discarded)', nnz(r) - 1, Npar - nnz(r));
    showmsg(h_mainfig, 'message', msg);
    pause(1);
    % ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	% save parameters to the designated file
	
toc
    % save('fullcoordsGPU.mat','coords')
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
	showmsg(h_mainfig, 'message', sprintf('Coord extraction finished (%d frames; %d Particle)s. Data saved to %s.', frames, nnz(r), fullname));
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

	
