function data = loadbf(fullname)
% ====
% function to load data from bio-format (bf) supported file types
% refer to loci.wisc.edu for more information on bio-formats
% 
% usage: data = loadbf(fullname)
% fullname is full file name including path
% data contains accessory information about the image/movie file
% 
% Xiaolin Nan, OHSU, 09/01/2012
% version 0: only takes series 1
% in the next version, will modify the img_data global array into
% a structure array to contain meta data for each frame
% to prepare for multicolor imaging data
%
% Xiaolin Nan, OHSU, 09/03/2012
% combined the original bfopen.m with loadbf.m; only retrieving image data
% in series 1 and no meta data nor colormap information
%
% Xiaolin Nan, OHSU 03/25/2015
% changed the core data structure and correspondingly the data workflow.
% now the img global variable is a structure that stores all key
% information for the images

global imgdata h_mainfig img;

% suppress the warning on multiple bindings etc.
warning off; 

	% read the data file with bfopen_wfi function
	[path name ext] = fileparts(fullname);
	msg = sprintf('Parsing file %s. Please wait ...', [name ext]);
	showmsg(h_mainfig, 'message', msg);	pause(0.1);
	
	%%%%%%%%
	% code below comes from bfopen.m
	autoloadBioFormats = 1;

	% Toggle the stitchFiles flag to control grouping of similarly
	% named files into a single dataset based on file numbering.
	stitchFiles = 1;

	% load the Bio-Formats library into the MATLAB environment
	status = bfCheckJavaPath(autoloadBioFormats);
	assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
    	'to the static Java path or add it to the Matlab path.']);

	% initialize logging (will complain if not)
	loci.common.DebugTools.enableLogging('INFO');

	% Get the channel filler
	r = bfGetReader(fullname, stitchFiles);
    
    if(~isempty(r))
        clear(img);     % free the mem used by the current img data
    else
        error('Cannot open the image file. Exiting ...');
    end

    %if planeSize/(1024)^3 >= 2,
    %    error(['Image plane too large. Only 2GB of data can be extracted '...
    %    'at one time. You can workaround the problem by opening '...
    %    'the plane in tiles.']);
    %end

    numSeries = r.getSeriesCount();
    %result = cell(numSeries, 2);

    globalMetadata = r.getGlobalMetadata();

    for s = 1:1 %numSeries: for now, only deal with one series (max 4D data)
        %fprintf('Reading series #%d', s);
        r.setSeries(s - 1);
        %pixelType = r.getPixelType();
        %bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
        %bppMax = power(2, bpp * 8);
        numImages = r.getImageCount();
        numChannels = r.getSizeC();
        numFrames = r.getSizeT();
        index_channel = zeros(numImages, 1);
        index_frame   = zeros(numImages, 1);
        %imageList = cell(numImages, 2);
        %colorMaps = cell(numImages) - ignore colormaps;
        
        % get frame 1 for the width and height information
        temp = bfGetPlane(r, 1);
        %image1 = temp{1, 1};
        [width height] = size(temp);

        % create the imgdata array
        % change on 03/23/2015 - the image data now is 'double' again
        % it is also changed into the width, height, frames 
        imgdata = zeros(height, width, numImages);
	
        if(isempty(imgdata) == 1)
            disp('Cannot create matrix to store image. Possible reason: file too large.');
            data = [];
            return;
        end

        for i = 1:numImages
            
            imgdata(:, :, i) = bfGetPlane(r, i);
            
            if numImages > 1
                zct = r.getZCTCoords(i - 1);

                if numChannels > 1
                    index_channel(i) = zct(2) + 1;
                end

                if numFrames > 1
                    index_frame(i) = zct(3) + 1;
                end
            end
            
            if mod(i, 100) == 0 || i == numImages
                msg = sprintf('Reading file %s. Please wait ... image %d of %d (frame %d of %d)', [name ext], i, numImages, zct(3)+1, numFrames);
                showmsg(gcf, 'message', msg);
                pause(0.002);
            end

        end

    end
    r.close();
    
	% fill the data structure for compatibility issues
	data.badframes = 0;
	% assign data fields
	data.width = width;
	data.height = height;
	data.numFrames = numFrames;
    data.numChannels = numChannels;
    data.frame_index = index_frame;
    data.channel_index = index_channel;
	%data.intensity = intensity;
	data.rbad = 0;
	
	r.close();
return
