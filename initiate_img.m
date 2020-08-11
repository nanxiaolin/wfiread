function initiate_img(num_pages)
%
% This function is to initiate the img structure
% When called without an argument, it defaults to loading a logo file
% that displays 'NanoImg' and an image of the OHSU CLSB campus.
%
% Usage: initiate_img(num_pages)
%        num_pages = the number of frames to hold the image data
% 
% the function will automatically generate fields needed to store the
% information.
%
% first declare img as a global variable
global img;

if nargin == 0  % fill in the logo image
    num_pages = 1;
end

img.imgdata = struct;

for i = 1:num_pages
    img.imgdata(i).rawimg = [];
    img.imgdata(i).channel = 1;
    img.imgdata(i).frame = 1;
    img.imgdata(i).time = 1;
end

% the channel structure
img.channels = struct;
img.channels.disp_colormap = [];
img.channels.disp_autoscale = 0;
img.channels.disp_high = 255;
img.channels.disp_low  = 1;
img.channels.fiducials = [];
img.channels.height = 0;
img.channels.width = 0;
img.channels.viewport = [];
img.channels.selection = [];

% the parameters structure
img.params = struct;
img.params.filename = '';
img.params.total_images = 1;
img.params.total_frames = 1;
img.params.total_channels = 1;
img.params.current_frame = 1;
img.params.current_channel = 1;
img.params.axis_on = 0;
img.params.grid_on = 0;

% the processed data structure (for storing coordinates and sorted coords)
img.processed = struct;
img.processed.sigma_low = 0.5;
img.processed.sigma_high = 2.5;
img.processed.smooth_area = 3;
img.processed.threshold = 5;
img.processed.rms = 0;
img.processed.PF = 1;   % particle finding algorithm - default to NMS
img.processed.GF = 1;   % gaussian fitting algorithm - default to least square
img.processed.sorted = 0; % records how many sorted images (each can use a different parameter set) are stored.




    