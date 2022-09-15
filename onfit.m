function onfit(object, event)
% function that performs gaussian curve fitting
global h_mainfig params;

userdata = get(h_mainfig, 'userdata');

if userdata.h_selrect == -1
    showmsg(h_mainfig, 'message', 'Select a region first!');
    return;
end

% prepare a few parameters
params.startx = userdata.selection(1);
params.starty = userdata.selection(2);
params.endx   = userdata.selection(3);
params.endy   = userdata.selection(4);
params.factor = str2double(get(userdata.h_threshold, 'String'));
params.sig_min = str2double(get(userdata.h_sigmamin, 'String'));
params.sig_max = str2double(get(userdata.h_sigmamax, 'String'));
params.meth = get(userdata.h_mnuPF, 'value');
%params.sm_area = str2double(get(userdata.h_smootharea, 'String'));

%numObj = 1;
%[numObj centers xs ys fit_boxes] = findparticles(0, userdata.currentframe);
[img xoff yoff] = getselection();
nfig = userdata.fig3d;
show3d(getselection, xoff, yoff, nfig, '3D View of Fitting Area');
    
%if numObj == 1
%    x0 = centers(2, 1);     y0 = centers(2, 1);
%    sigx = sigmax(1);		sigy = sigmay(1);	a = ints(1);
%elseif numObj == 0
    %[x0 y0 sigx sigy a bk finess iter] = fitgauss(img, 1e-4);
    output = fitgaussc(img, 1, 1e-4, 20);
    x0   = output(4);   y0   = output(3);
    sigx = output(6);   sigy = output(5);
    a    = output(2);   bk   = output(8);
    finess = output(7); iter = output(9);
    x0 = x0 + xoff - 1; y0 = y0 + yoff - 1;
%else
%    showmsg(h_mainfig, 'message', 'Selected area contains more than one particle. Fitting terminated.');
%    return;
%end
    
msg = sprintf('Centroid=(%3.3f, %3.3f) Amp=%.0f SigmaX=%1.2f  SigmaY=%1.2f  BK_Noise=%.0f Goodness=%0.3f Iterations=%d', x0, y0, a, sigx, sigy, bk, finess, iter);

showmsg(h_mainfig, 'message', msg);

% the lines commented below are to use the lsqnonlin function from matlab
% to fit the data to a 2-d gaussian function
% para = [bk a x0 y0 sig];
% tic;
% option = optimset('Display', 'off', 'LargeScale', 'off');
% result = lsqnonlin(@diffgauss, para, [], [], option, double(px), double(py), img);
% toc

% tic;

%toc
