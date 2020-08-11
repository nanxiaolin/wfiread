function [numObj centers xs ys fit_boxes] = findparticles(obj, event)
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
% Please feel free to distribute this script as long as you cite our original work (Nan et al PNAS, 2013)
% Xiaolin Nan, Oregon Health and Science University, Portland
% Email: nan@ohsu.edu

global h_mainfig params;


% obj signals the purpose of calling this function
%   obj = 0 means called by other programs such as onmakecoord, use existing parameters
%   obj = 1 means called by the GUI, use the current frame number and selection


if obj == 0
    	frame = event;
    	factor = params.factor;
    	sig_min = params.sig_min;
    	sig_max = params.sig_max;
   	meth = params.meth;
    	sm_area = params.sm_area;
else
    tic
	userdata = get(h_mainfig, 'userdata');
   	frame = userdata.currentframe;
   	%startx = userdata.selection(1);
    	%starty = userdata.selection(2);
	%endx   = userdata.selection(3);
	%endy   = userdata.selection(4);

	factor = str2num(get(userdata.h_threshold, 'String'));
	sig_min = str2num(get(userdata.h_sigmamin, 'String'));
	sig_max = str2num(get(userdata.h_sigmamax, 'String'));
   	sm_area = str2num(get(userdata.h_smootharea, 'String'));
	% see which method is chosen to identify the particles
	meth = get(userdata.h_mnuPF, 'value');
end

fullimg = ongetframe(frame);
startx = params.startx;
starty = params.starty;
endx = params.endx;
endy = params.endy;

% all the different particle finding algorithms will define a list of fit
% boxes surrounding each particle. returned information include:
% 1. numObj = total number of particles meeting certain criteria
% 2. centers = center pixel as found corasely by the algorithm
% 3. xs = start x pixel of the fitting box
% 4. ys = start y pixel of the fitting box
% 5. fit_boxes = the fitting boxes that surround each particle.

if meth == 1 % NMS method
   img = fullimg(starty : endy, startx : endx);
   [numObj centers xs ys fit_boxes] = fp_nms(img, factor, sig_min, sig_max, startx, starty);
elseif meth == 2 % SIT (Simple Intensity Threshold) method
   [numObj centers xs ys fit_boxes] = fp_thresh(fullimg, sm_area, factor, sig_min, sig_max, startx, starty, endx, endy);
end

%save('fitboxes.mat', 'fit_boxes', '-MAT');


if obj~=0
    if numObj > 0
       
        %show_binary = get(findobj(h_mainfig, 'tag', 'chkshowbinary'), 'Value');
        
        %if show_binary
        %    fullimg(:, :) = 0;
        %    fullimg(starty:endy, startx:endx) = img;
        %    imshow(fullimg, [0 1]);  
        %else
        showframe(frame);
        %end

        sigx = zeros(numObj, 1);
        sigy = zeros(numObj, 2);
        
        % fit all the centers
        [fit_height fit_width ~] = size(fit_boxes);
        %img = zeros(fit_height, fit_width);
        for i = 1: numObj
            img = fit_boxes(:, :, i);
            [centers(1, i), centers(2, i), sigx(i), sigy(i)] = fitgauss(img, 1e-4);
            centers(1, i) = centers(1, i) + xs(i) - 1;
            centers(2, i) = centers(2, i) + ys(i) - 1;
        end
        
        % filter the data according to the filter settings
        r = find(sigx >= sig_min);
        centers = centers(:, r); sigx = sigx(r); sigy = sigy(r);
        r = find(sigy >= sig_min);
        centers = centers(:, r); sigx = sigx(r); sigy = sigy(r);
        r = find(sigx <= sig_max);
        centers = centers(:, r); sigx = sigx(r); sigy = sigy(r);
        r = find(sigy <= sig_max);
        centers = centers(:, r); sigx = sigx(r); sigy = sigy(r);
        numparticles = length(centers);
        
        % show the number of particles found
        mesg = sprintf('Found %d particle(s) in selected area in %.4f seconds. ', numparticles, toc);
        figure(h_mainfig); 
               
        if meth == 2
        	color = [0 0.7 0];
        else
        	color = [0.7 0.7 0];
        end
        
        hold on; plot(centers(1, :), centers(2, :), 's', 'LineWidth', 1, 'MarkerSize', 14, 'MarkerEdgeColor', color);  
        %hold on; plot(xs(:), ys(:), 'g+');
    else
        mesg = sprintf('No particle found in selected area. ');
    end

    showmsg(h_mainfig, 'message', mesg);
end

%clear fullimg img;
