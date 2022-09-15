function [imginfo, imgdata] = loadtiff( fullname, sample_gap, load_assoc_files )
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
% Major revision 02/17/2020, Xiaolin Nan (OHSU)
% 1. Ditched the bioformats plugin for reading TIFFs as a whole (which is
%    too slow that it takes 15-30 minutes to just load a file). 
%    Now the function utilizes libtiff for accessing TIFF info and image
%    data.
% 2. Added support for a 'sampler' mode which returns a small subset of the
%    images when the raw video is too big and takes up too much memory.
% 3. Aside from returning imginfo (data), the function also stores some key
%    info of the file in params:
%    .fileinfo structure with the following fields
%       .numfiles - the number of files associated with the RAW tiff stack
%       .filenames - names of the files in correct order
%       .frames - number of IFDs in each file
%    This information can be accessed in other functions.
% 
% Revision 03/04/2020, Xiaolin Nan
% 1. Added an output imgdata (in addition to imginfo) so this can be called
%	 by other functions without affecting the global imgdata;


	global h_mainfig params;
	
	% calling with only one argument is normal mode
	if nargin == 1
		sample_gap = 1;
	else
		if sample_gap < 1
			sample_gap = 1;
		end	
	end
	
	[pathname,filename,ext] = fileparts(fullname);
	msg = sprintf('Analzying file %s. Please wait ...', [filename,ext]);
	showmsg(h_mainfig, 'message', msg);	pause(0.05);
	%disp(msg);
	
	tif_info = analyze_tifs(fullname, load_assoc_files);
	
	% in case something went wrong
	if isempty(tif_info)
		imginfo = [];
		imgdata = [];
		return;
	end
	
	counted_frames = 0;
	sampled_frames = 0;
	actual_frames = {[]};
	params.fileinfo.numfiles = tif_info.totalfiles;
	params.fileinfo.frames = zeros(1, params.fileinfo.numfiles);
	
	est_frames = ceil(1.2*tif_info.totalframes / sample_gap);
	imgdata = zeros(tif_info.height, tif_info.width, est_frames, 'uint16');
	
	for i = 1 : tif_info.totalfiles
		fullname = cell2mat(tif_info.files(i));
		[~,filename] = fileparts(fullname);
		
		tf = Tiff(fullname);
		tf.setDirectory(1);
		
		more_frames = true;
		read_last_frame = false;
		cur_frames = 0;				% frame counter for the current file
		
		while more_frames
			counted_frames = counted_frames + 1;
			cur_frames = cur_frames + 1;
			
			% sample the first frame and every sample_gap frames 
			if counted_frames == 1 || mod(counted_frames, sample_gap) == 0
				sampled_frames = sampled_frames + 1;
				actual_frames(sampled_frames) = {counted_frames};
				imgdata(:, :, sampled_frames) = tf.read;
				
				if tf.lastDirectory
					read_last_frame = true;
				end
			end
			
			if counted_frames == 1 || mod(counted_frames, 100) == 0
				msg = sprintf('Reading data from file %s (file %d of %d): frame #%d', filename, i, tif_info.totalfiles, counted_frames);
				showmsg(h_mainfig, 'message', msg);	pause(0.05);
				%disp(msg);
			end
			
			if tf.lastDirectory
				more_frames = false;
			else	
				try
					tf.nextDirectory;
				catch ME
					% if for some reason, cannot read the next frame (although not reaching the end of the file yet)
					% treat it as if it is the end
					more_frames = false;
					
					% if the current frame has been sampled, marked it as sampled
					if counted_frames == 1 || mod(counted_frames, sample_gap) == 0
						read_last_frame = true;
					end	
				end
			end
		end
		
		if i == tif_info.totalfiles && read_last_frame == false
			% read in the last frame of the last file if it has not been read
			% note: every frame has already been counted for
			sampled_frames = sampled_frames + 1;
			actual_frames(sampled_frames) = {counted_frames};
			imgdata(:, :, sampled_frames) = tf.read;
		end
	
		tf.close;
		% add file to params
		params.fileinfo.filenames(i) = {fullname};
		params.fileinfo.frames(i) = cur_frames;
	end

	msg = sprintf('Finishing up. Please wait ...');
	showmsg(h_mainfig, 'message', msg);	pause(0.05);

	% populate the imginfo 
	imginfo.badframes = 0;
	imginfo.width = tif_info.width;
	imginfo.height = tif_info.height;
	imginfo.actualframes = cell2mat(actual_frames);
	imginfo.frames = sampled_frames;
	imginfo.rbad = 0;		   
	
	% clean up imgdata
	imgdata(:, :, sampled_frames + 1:est_frames) = [];
	msg = sprintf('Reading data from file %s: frame #%d (of total %.0f) completed.', filename, counted_frames, counted_frames);
	showmsg(h_mainfig, 'message', msg);	pause(0.05);
	
	return
	
	
	function tif_list = analyze_tifs( fullname, load_assoc_files )
	% this function analyzes the tif header or filenames in the folder to construct a tif_list
	% which is a cell array with all the related TIF fullnames
	
	% process the input file first
		tif_list.totalfiles = 0;
		
		if load_assoc_files	% when loading associated files
			% first analyze the full filename
			[file_common, cid] = regexp(fullname, '(.ome)?(.tif|.tiff|.TIF|.TIFF)', 'match');
			if isempty(file_common)
				tif_list = [];
				return
			end
			
			% now file_common should contain the '.ome.tif' or '.tif' parts of the file and
			% the cid is the index at which numbering should have been added.
			dir_common = [fullname(1:cid-1), '*', fullname(cid:length(fullname))];
			files_unsorted = dir(dir_common);
			% note that pathname is absent from the files_unsorted and files_sorted arrays
			files_sorted = natsortfiles( {files_unsorted.name} );
			
			% go through each file in the list and make sure it opens and has the same width
			% and height as the first one
			
			counted_files = 0;
			
			% there is much more information that can be extracted from iminfo
			for i = 1 : numel(files_sorted)
				filename = cell2mat(files_sorted(i));
				fullname = fullfile(pathname, filename);
				
				%msg = sprintf('Opening file #%d: %s ...\n', i, filename);
				%disp(msg);
				
				try
					tf = Tiff(fullname);
				catch ME
					%if i < numel(files_sorted)
					%	err_msg = sprintf('File %s cannot be opened. Proceeding to the next one.', filename);
					%else
					%	err_msg = sprintf('File %s cannot be opened. Skipping the file.', filename);
					%end
				
					%disp(err_msg);
					continue;
				end
				
				tf.setDirectory(1);			
				% check image width and height
				if counted_files == 0
					[tif_list.height, tif_list.width] = size(tf.read); 
				end
				
				[height, width] = size(tf.read);
				
				if height ~= tif_list.height || width ~= tif_list.width
					%if i < numel(files_sorted)
					%	err_msg = sprintf('File %s has a non-matching image dimension. Proceeding to the next one.', filename);
					%else
					%	err_msg = sprintf('File %s has a non-matching image dimension. Skipping the file.', filename);
					%end
				
					%disp(err_msg);
					continue;
				else
					counted_files = counted_files + 1;
					tif_list.totalfiles = tif_list.totalfiles + 1;
					tif_list.files(counted_files) = {fullname};
				end
				
				% estimate the total number of frames based on the 1st TIF file
				if counted_files == 1				
					total_frames = 1;
					
					while ~tf.lastDirectory
						tf.nextDirectory;
						total_frames = total_frames + 1;
					end
				end
				
				tf.close; pause(0.05);
			end
			
			% note that here the total frames is an estimate.
			tif_list.totalframes = total_frames * counted_files;
			tif_list.totalfiles = counted_files;
		else	% when not loading associated files
			try
				tf = Tiff(fullname);
			catch ME
				%err_msg = sprintf('File %s cannot be opened. ', filename);
				
				%disp(err_msg);
				tif_list = [];
				return;
			end
			
			[tif_list.height, tif_list.width] = size(tf.read); 
			total_frames = 1;
					
			while ~tf.lastDirectory
				tf.nextDirectory;
				total_frames = total_frames + 1;
			end
			
			tif_list.totalfiles = 1;
			tif_list.totalframes = total_frames;
			tif_list.files = {fullname};
			tf.close; pause(0.05);
		end
		
	end
	
end
