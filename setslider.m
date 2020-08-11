function setslider
% function that sets slider configurations
% show the first frame and enable the slider

global h_mainfig;

if(isempty(h_mainfig) == 1)		% some java code messes up this variable
	h_mainfig = gcf;
end

userdata = get(h_mainfig, 'userdata');

frames = userdata.frames;

if(frames == 1)
% when there is only one frame, make the slider invisible
	set(userdata.h_slider, 'visible', 'off');
	return;
end

width = userdata.width;
height = userdata.height;

step = double(1/frames);
set(userdata.h_slider, 'Max', frames - 1, 'Min', 0, 'visible', 'on', 'SliderStep', [step 5*step], 'Value', 0);

if width > height
    ratio = double (512/width);
else
    ratio = double (512/height);
end

swidth = uint16 (ratio * width);
sheight = uint16(ratio * height);
shmargin = (512 - swidth) / 2;
svmargin = (512 - sheight) / 2;
shpos = userdata.figurestartx + shmargin;
svpos = userdata.figurestarty + sheight + svmargin + 12;

set(userdata.h_slider, 'Position', [shpos svpos swidth 13]);
