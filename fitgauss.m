function [x0 y0 sigx sigy a bk_rms finess iter] = fitgauss(img, err)
% 
%Function that fits an 2-d array to a gaussian function
% Usage: centroid = fitguass(img, bk, a, x0, y0, sig, err)
% Typical CPU time of calling this function for a 12x12 image: 1 ms
% 
% This function does not reject fittings based on image quality. All
% rejections will have to be done by your calling function.
%
% Revision 2.0: replaced nonlinear optimization method with Jacobian matrix
% (analytical form) method. Speed increased by ~150 times.
% Date: 08/25/2008 by Xiaolin Nan (c), UC Berkeley
%
% Revision 2.1: added code to deal with 'invalide pionts' marked as 0
% so a scattered matrix can be fitted just fine.
% Date: 10/21/2008 by Xiaolin Nan (c), UC Berkeley
% 
% Revision 3.0: changed the default symmetric fitting to elliptical so
% it generates one more output parameter (sigx sigy instead of sig).
% Date: 03/16/2010 by Xiaolin Nan (c), UC Berkeley
%
% Revision 3.1: added three return parameters
%  bk_rms - background noise level after fitting
%  finess - goodness of fitting or sqaured residue divided by sum
%  iter - number of iterations need to converge on the fitting
% Also added amplitude (a) err as third loop terminator (in addition to err_x and err_y) 



%tic;

[sizex sizey] = size(img);

% make guesses of parameters based on the image itself
bk = mean(mean(img));
a = max(max(img)) - bk;

[imax yi] = max(img);
[imax x0] = max(imax);
y0 = yi(x0);

sigx = 1;
sigy = 1;

% prepare a few matrices
vpoints = numel(find(img ~=0));
jg = ones(vpoints, 6);	 % jacobian matrix; jg(:, 1) is always 1.
dif = zeros(vpoints, 1);  % difference matrix

ex0 = 1; ey0 = 1; 		 % changes in x and y; initialized for while loop.
iter = 0; ea = 1;

while ((ex0 > err) || (ey0 > err) || (ea > err)) && (iter <= 20)
    % calculate the jacobian and difference matrices
    pos = 0;
    for(i=1:sizex)   % column (first dimension) first
        for(j=1:sizey)
            
            % ignore the points set as 0
            if img(i, j) == 0
                continue;
            end

            pos = pos + 1;
            
            % remember: use calculated values for the jacobian matrix; do not use
            % the acquired data to calculate anything here
            % and remember: i - y direction, j - x direction; in matlab.
            % this way, calling of this function is done in normal (x, y) convention
            pexp = a * exp(-(j - x0)^2/(2*sigx^2) - (i - y0)^2/(2*sigy^2));
            jg(pos, 2) = pexp / a;
            jg(pos, 3) = (j - x0) * pexp / (sigx^2);
            jg(pos, 4) = (i - y0) * pexp / (sigy^2);
            jg(pos, 5) = (j - x0)^2 * pexp / (sigx^3);
			jg(pos, 6) = (i - y0)^2 * pexp / (sigy^3);
            dif(pos) = bk + pexp - img(i, j);
        end
    end

    % calculate the adjustments needed to make on parameters
    dlambda = jg \ dif;

    % make adjustments to the set of parameters
    bk = bk - dlambda(1);
    a = a - dlambda(2);
    x0 = x0 - dlambda(3);
    y0 = y0 - dlambda(4);
    sigx = sigx - dlambda(5);
    sigy = sigy - dlambda(6);
    
    ex0 = abs(dlambda(3)/x0);
    ey0 = abs(dlambda(4)/y0);
    ea  = abs(dlambda(2)/a);
    %pause(); 

    iter = iter + 1;
end

% calculate the bk_rms and finess
bk_rms = std(dif);
finess = sqrt(dif' * dif)/sum(sum(img));

%[bk a]
%toc
%disp(['Iterations: ' int2str(iter)]);
