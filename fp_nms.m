function [numObjects centers xss yss fit_boxes] = fp_nms(img, factor, sig_min, sig_max, startx, starty)
%
% function locateparticles(obj, event)
%   this function locates particles within the current frame and retrieves the coordinates
%   and fitting parameters
% rewritten from the original findparticles.m
%   uses non-maximal suppression instead of simple intensity thresholding
%   aiming at maximal identification of particles in ever-changing situations
% 
% 07/10/2014: major revision
%   now the function only returns the fitting boxes along with the position of the fitting
%   boxes (marked by x0, y0) relative to startx and starty
%   it no longer performs Gaussian fitting on the fitting boxes to save time

% first use NMS to mark out the local maxima

nms_region = 2; 	% search region is 1+2*nms_region
rms = min([min(std(img)), min(std(img, 0, 2))]);
thresh = factor * rms;
min_pixel = 4;
mask_rgn = 4;
[height width] = size(img);

warning('off', 'all');

% the function nms returns a list of (x, y) coordinates corresponding to
% maxima pixels of found particles. a 'mask' matrix is returned at the
% same time that contains only 1s and 0s, where 1 indicates an area designated
% to a single particle (within its 11x11 region) and 0 indicates empty or
% overlapping areas

[y x mask] = nms(img, nms_region, thresh, min_pixel, mask_rgn);

ind = find(x > 0);
x = x(ind); y = y(ind);
numObjects = length(x);

% prepare return variables
% returned fitting boxes are regular 11 * 11 sqaures (at mask_rgn = 5)

centers = zeros(2, numObjects);
good_objects = zeros(1, numObjects);
xss = zeros(1, numObjects);
yss = zeros(1, numObjects);

fit_width = 2*mask_rgn + 1;
if fit_width > width
    fit_width = width;
end

fit_height = 2*mask_rgn + 1;
if fit_height > height
    fit_height = height;
end

fit_boxes = zeros(fit_height, fit_width, numObjects);
%num_good = 0;

for i=1:numObjects
	xs = x(i) - mask_rgn;
	if xs<1
		xs = 1;
	end

	ys = y(i) - mask_rgn;
	if ys < 1
		ys = 1;
	end

	xe = x(i) + mask_rgn;
	if xe > width
		xe = width;
	end

	ye = y(i) + mask_rgn;
	if ye > height
		ye = height;
    end

    %fitpart = zeros(fit_height, fit_width);
    %fitmask = zeros(fit_height, fit_width);
    
	%fitpart = img(ys:ye, xs:xe);
	fitmask = mask(ys:ye, xs:xe);
	
	% remove mask part that does not belong to current particle
	%fitmask = (fitmask == i);
	fitpart = img(ys:ye, xs:xe) .* (fitmask == i);
	
	if(numel(nonzeros(fitpart)) < 7)
		continue;	
	else
		good_objects(i) = 1;
		centers(1, i) = x(i) + startx - 1; 
        centers(2, i) = y(i) + starty - 1;
        fit_boxes(1:(ye-ys+1), 1:(xe-xs+1), i) = fitpart;
        %num_good = num_good + 1;
        xss(i) = xs + startx - 1;
        yss(i) = ys + starty - 1;
	end
end

goodobj = find(good_objects == 1);
numObjects = numel(goodobj);

if numObjects   
    centers    = centers(:, goodobj);
    fit_boxes  = fit_boxes(:, :, goodobj);
    xss        = xss(goodobj);
    yss        = yss(goodobj);
 end
