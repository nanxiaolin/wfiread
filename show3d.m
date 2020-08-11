function show3d(img, xoff, yoff, nfig, titlemsg)
% function that displays image (img) as 3-d surface
% xoff and yoff are used to correct the starting x & y coordinates
% nfig is the designated figure number

[size_y size_x] = size(img);
[px,py] = meshgrid(xoff:size_x+xoff-1, yoff:size_y+yoff-1);

figure(nfig);  surf(px,py,img); %shading interp;
xlabel('X /pixel'); ylabel('Y /pixel'); zlabel('Intensity (a.u.)'); 
set(nfig, 'name', titlemsg, 'numbertitle', 'off');
axis tight;
