function [numObj centers intens sigmax sigmay bk_rms goodness iterations] = fp_thresh(fullimg, sm_area, factor, sig_min, sig_max, startx, starty, endx, endy)
% Function fp_thresh(img, sm_area, factor) identifies particles within an image frame by thresholding
%  Rewritten from previous findparticles()
%  sm_area: smoothing area
%  factor:  times rms as the threshold (above background)

%
% calculates the background to remove any features smaller than 3 pixels
img = fullimg(starty : endy, startx : endx);

background = imopen(img, strel('disk', sm_area));  
img2 = imsubtract(img, background);

ave = mean(mean(img2));
rms = min(std(img));

% use a small threshold to label the image first
th = ave + min(3, factor) * rms;
%maxth = factor * rms;

img = (img2 >= th);

% make all the features a 4x4 image around its center
%img2 = imdilate(img2, strel('disk', 1));
%imshow(img2);
[img numObjects] = bwlabeln(img, 8);

% prepare return variables
centers = zeros(numObjects, 2);
intens = zeros(numObjects, 1);
sigmax = zeros(numObjects, 1);
sigmay = zeros(numObjects, 1);
bk_rms = zeros(numObjects, 1);
goodness = zeros(numObjects, 1);
iterations = zeros(numObjects, 1);

good_objects = zeros(numObjects, 1);

for n = 1 : numObjects
    [r c] = find(img == n);

    ol = numel(r);
	
	% this is where the threshold factor is applied - RMS
    if ol < 2 || ((max(max(img2(r, c))) - ave) < factor * rms) %sum(sum(img2(r, c) - ave)) < (factor * ol * rms)
        continue;
    end
    
    %iter = 0;
    % x0, y0 are all relative to the full image
    x0 = round(mean(c)) + startx - 1;    %x0 = x+0.5;
    y0 = round(mean(r)) + starty - 1;    %y0 = y+0.5;

    % default fitting area is a 9x9 (4 pixels around) square, but the
    % overlapping area will be set as 0 and fitgauss function will ignore
    % those points
    frad = 4;
    xs = max(round(x0) - frad, startx);     xe = min(round(x0) + frad, endx);
    ys = max(round(y0) - frad, starty);     ye = min(round(y0) + frad, endy);
    %hold on; rectangle('Position', [xs ys xe-xs+1 ye-ys+1], 'EdgeColor', [0.9 0.9 0.9]); 
    
    % examine the overlap between particles
    lstartx = xs-startx+1;      lendx = xe-startx+1;
    lstarty = ys-starty+1;      lendy = ye-starty+1;
    %lx0 = round(x0) - startx + 1;      ly0 = round(y0) - starty + 1;

    smat = img(lstarty : lendy, lstartx : lendx);

    % a small trick here: change all '0' into 'n's so it is easy to
    % tell if smat has other particles (0 is background)
    smat(find(smat == 0)) = n;

    % see if there's another particles within the range
    [r c] = find(smat ~= n);
    ols = numel(r);
    fitpart = fullimg(ys : ye, xs : xe);
    
    % if there are overlapping particles, trim the fitting area of
    % the current particle to keep maximum number of points around
    % the center point (lx0, ly0)
    % then put all the pixels overlapping with other particles to 0
    % and let fitgauss function to handle it
    if ols
        for k = 1 : ols
            fitpart(r(k), c(k)) = 0;
            fitpart(max(r(k) - 1, 1), c(k)) = 0;
            fitpart(r(k), max(c(k) - 1, 1)) = 0;
            fitpart(min(r(k) + 1, ye-ys+1), c(k)) = 0;
            fitpart(r(k), min(c(k) + 1, xe-xs+1)) = 0;
        end
    end

    [x y sigx sigy ints bk finess iter] = fitgauss(fitpart, 1e-4);
    x = x + xs - 1;     y = y + ys - 1;

    if ints < 0 || abs(x - x0) > 2 || abs(y - y0) > 2  || sigx > sig_max || sigx < sig_min || sigy > sig_max || sigy < sig_min || finess >= 0.6
        continue;
    end

    good_objects(n) = 1;
    centers(n, 1) = x;
    centers(n, 2) = y;
    intens(n) = ints;
    bk_rms(n) = bk;
    sigmax(n) = sigx;
    sigmay(n) = sigy;
    goodness(n) = finess;
    iterations(n) = iter;
	
    %figure(3); 
    %imshow(fitpart, [mean(mean(fitpart)) max(max(fitpart))], 'InitialMagnification', 500); 
    %colormap('Hot');
    %pause;
    %mesg = sprintf('Particle %d has %d iterations', numObj, iter);
    %disp(mesg);
end

goodobj = find(good_objects == 1);
numObj = numel(goodobj);

if numObj    
    centers    = centers(goodobj, 1:2);
    intens     = intens(goodobj);
    sigmax     = sigmax(goodobj);
	sigmay     = sigmay(goodobj);
	bk_rms     = bk_rms(goodobj);
	goodness   = goodness(goodobj);
	iterations = iterations(goodobj);
end
