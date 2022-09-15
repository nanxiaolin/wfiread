function [numobj, centers] = findparticles(obj, event)
% function to find particles
% suited for sparsely distributed particles
% faster than findparticles algorithms using watershed
% returned values of 'centers' are relatively to the origin
% of the entire image, not selected area
%
% revision on 03/23/2008:
%  changed the way particles are thresholded - use peak intensity instead of
%  sum intensity which prevents dim, diffusive features from being selected
%
% revision on 10/20/2008:
%  major revisions in two ways:
%  1. Use a low threshold (2xRMS) to determine as many particles as
%     possible, then use the user-defined threshold to reject non-qualified
%     particles. This helps step 2 as well;
%  2. In cases when particles (including non-qualified) are overlapping, put
%     those overlapping pixels into 0 so the fitgauss algorithm can ignore
%     those points and only use the good, non-overlapping region to fit the
%     center With these revisions, the routine is now able to find closely spaced
%     particles - and is much faster (typical execution time ~0.1s for a
%     200x200 image area
%
% revision on 04/01/2010:
%  Added more output parameters that characterizes all aspects of particle identification
%  bk_rms - background noise
%  goodness - residual squared error relative to sum intensity
%  iterations - number of iterations to converge
% 
% revision on 07/02/2010
%  Added a new algorithm (NMS) to find particles (also added UI menu for choice of methods)
%  The new method is at least 2x faster than the old one.
%
% revision on 07/10/2014
%  Major revision to make the scripts work with CUDA and GPU computing
%  now the function only returns the fitting areas and its associated parameters (x0, y0), and draws boxes when requested
%  but do not do the Gaussian fitting until asked to (by the makecoord.m function, for example)
%  this allows us to pool the data and send everything to the GPU at once for faster processing
%  timing measurement shows that Gaussian fitting takes up 99% of the time, and can be
%  significantly sped up by sending the data to GPUs or at least using multiple threads on a CPU.
% 
% revision on 02/22/2020
%  Major revision to make use of the new smlocalize function (CPU based) which returns the numobjects and coords
%  Refer to the smlocalize source code or annotations below for the format of the output
%  This function performs a quick fitting to identify the particles. For precise localizations please call smlocalize directly.
%
% Please feel free to distribute this script as long as you cite our original work (Nan et al PNAS, 2013)
% Xiaolin Nan, Oregon Health and Science University, Portland
% Email: nan@ohsu.edu

global h_mainfig params;

tic;
% obj signals the purpose of calling this function
%   obj = 0 means called by other programs such as onmakecoord, in which case the event is the mcpars structure; or event can be the frame
%			number, in which case the parameters use existing parameters
%   obj = 1 means called by the GUI, use the current frame number and selection

if obj == 0
    frame = event;
    thresh = params.factor;
    sig_min = params.sig_min;
    sig_max = params.sig_max;
    meth = params.meth;
    contrast_factor = params.contrast_factor;
	psf_size = params.psf_size;
else
	userdata = get(h_mainfig, 'userdata');
   	frame = userdata.currentframe;
   	%startx = userdata.selection(1);
    	%starty = userdata.selection(2);
	%endx   = userdata.selection(3);
	%endy   = userdata.selection(4);

	thresh = str2double(get(userdata.h_threshold, 'String'));
	sig_min = str2double(get(userdata.h_sigmamin, 'String'));
	sig_max = str2double(get(userdata.h_sigmamax, 'String'));
   	contrast_factor = str2double(get(userdata.h_contrastfactor, 'String'));
	psf_size = str2double(get(userdata.h_psfsize, 'String'));	
	% see which method is chosen to identify the particles
	meth = get(userdata.h_mnuPF, 'value');
end

startx = params.startx;
starty = params.starty;
endx = params.endx;
endy = params.endy;

% set some fitting parameters
nms_region = 2; 	% search region is 1+2*nms_region
%min_pixel = 4;
mask_rgn = psf_size;
err = 1e-2;
max_iter = 10;

fullimg = ongetframe(frame);
img = fullimg(starty : endy, startx : endx);
% smlocalize format: smlocalize( img, nms_region, mask_region, thresh_factor, min_pixel, sig_min, sig_max, err, max_iter )
[numobj, coords] = smlocalize(img, nms_region, mask_rgn, thresh, contrast_factor, sig_min, sig_max, err, max_iter);

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


% clean up the results according to sigma range settings
if numobj > 0 
	coords = coords(:, 1:numobj);
	centers = [coords(3, :);coords(4, :)];
	centers(1, :) = centers(1, :) + startx - 1;
	centers(2, :) = centers(2, :) + starty - 1;
else
	centers = [];
end

%save('fitboxes.mat', 'fit_boxes', '-MAT');

%% for calls from the GUI, display the output; otherwise, return
if obj~=0
    if numobj > 0
        figure(h_mainfig); 
        
		% estimate the marker size
		sig_mean = mean(coords(5, :)+coords(6, :));
		[height,width]=size(fullimg);
		axis_size = get(gca, 'Position'); axis_ampl = ((axis_size(3)/height)+(axis_size(4)/width))/2;
		ax = xlim; axis_zoom = width / (ax(2) - ax(1) + 1);
		markersize = round(sig_mean * axis_ampl * 1.6 * axis_zoom);
		linewidth = 0.8 + markersize / 20;
		
		hold on; 
        if userdata.h_particlecenters ~= -1
            delete(userdata.h_particlecenters);
            userdata.h_particlecenters = -1;
        end
		
        userdata.h_particlecenters = plot(centers(1, :), centers(2, :), 's', 'LineWidth', linewidth, 'MarkerSize', markersize, 'MarkerEdgeColor', [0.0 0.9 0]);  
        %hold on; plot(xs(:), ys(:), 'g+');
        set(h_mainfig, 'userdata', userdata);
        
		mesg = sprintf('Found %d particle(s) in selected area in %.4f seconds. ', numobj, toc);		
    else
			mesg = sprintf('No particle found in selected area. ');
    end

    if nargin == 2	% only shows a message if two inputs (to trigger a message line output)
		showmsg(h_mainfig, 'message', mesg);
	end
end

%clear fullimg img;
