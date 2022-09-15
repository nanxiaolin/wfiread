function openlargefile(obj, event)
%
% Created 02/18/2020 Xiaolin Nan (OHSU) 
%
% function that handles image file opening - redesigned to handle large
% files in so called 'large video mode'
% 
% two variables are added to accommodate this change,
%   1. userdata.actualframes: matrix that stores the actual frame number
%      for each loaded image frame (for sampler and testing makecoord
%      settings);
%   2. params.largevmode: a switch that tells other programs to use the
%      large video mode (1 = large video mode; 0 = normal mode)
%
% this allows the all previous operations (getframe, gotoframe, etc.) to
% run as before; the only place that needs to be handled differently is the
% 'current frame' box (that needs to show the actual frame# in the raw
% video and not that in the sampler (which is only 20 frames).
% 
% also made a new version of makecoords (makelvcoords to work with the
% large videos.

    global h_mainfig params imgdata;

    userdata = get(h_mainfig, 'userdata');
    pref_dir = userdata.pref_dir;

    extension = {'*.tif; *.stk; *.lsm; *.nd2', 'OME-TIFF stack (*.TIF, *.LSM, *.STK, *.ND2)'};
    [filename,pathname,fi] = uigetfile(extension, 'Select a file to open', pref_dir);
   
    if filename == 0
        return;
    end

    %[path name ext] = fileparts(filename);
    fullname = fullfile(pathname, filename);
 
    enable_selection(h_mainfig, 'disable');
	set(h_mainfig, 'WindowButtonMotionFcn', '');
    
    % get the sampler stack from the TIF file
    % load every other 100 frames
	 % read the data
    %switch load_assoc_files
    %    case 1  % OME-TIFF stack (.LSM; .STK; .ND2; .TIF; etc)
	
	% check to see if opening a single TIF or a whole sequence
	load_assoc_files = get(userdata.h_loadlinked, 'value');
    [imginfo, imgdata] = loadtiff(fullname, 100, load_assoc_files);
	
    %    case 0  % TIF sequences
    %        [imginfo, imgdata] = loadtiffseq(fullname, 100);
    %end
	    
    if isempty(imginfo)
        showmsg(h_mainfig, 'message', 'Failed to retrive information or data from the file.');
        
        % re-enable the selection function
        if ~isempty(filename)
            enable_selection(h_mainfig, 'enable');
            set(h_mainfig, 'WindowButtonMotionFcn', @showpoint);
        end
        
        return;
    end

   
    % assign fields
    width = imginfo.width;
    height = imginfo.height;
    frames = imginfo.frames;
    rbad = imginfo.rbad;
    %h_mainfig = gcf;		% this is a temp fix for a weird problem caused by loadbf() function which clears up h_mainfig variable

    % save the configuration
    userdata.badframes = imginfo.badframes;
    userdata.file = filename;
    userdata.pref_dir = pathname;
	%userdata.exp_dir = pathname;		% reset export dir to curret folder
    userdata.width = width;
    userdata.height = height;
    userdata.frames = frames;
    userdata.currentframe = 1.0;
    userdata.axison = get(findobj(h_mainfig, 'tag', 'chkaxison'), 'value');
    userdata.gridon = get(findobj(h_mainfig, 'tag', 'chkgridon'), 'value');
    
    % for recording the actual frame #s
    userdata.actualframes = imginfo.actualframes;

    % reset the fiducial markers and the controls
    userdata.markernum = 0;
    userdata.markerpos = 0;
    userdata.markerhandles = -1;
    userdata.markers = [];
    set(userdata.h_markerdel, 'enable', 'off');
    
    % clear the selection box and reset selection matrix
    if userdata.h_selrect ~= -1
        delete(userdata.h_selrect);
        userdata.h_selrect = -1;
    end
    userdata.selection = [1 1 width height];
    params.startx = 1;		params.endx = userdata.width;
    params.starty = 1; 		params.endy = userdata.height;
    
    mesg = sprintf('(%d, %d)', width, height);
    showmsg(h_mainfig, 'selstart', '(1, 1)');
    showmsg(h_mainfig, 'selend', mesg);

    userdata.h_image = -1; % force figure update
    
    set(h_mainfig, 'userdata', userdata);

    setslider();

    % update text message fields
    mesg = sprintf('%d', max(imginfo.actualframes));
    showmsg(h_mainfig, 'totalframes', mesg);
    %if rbad
    %    mesg = sprintf('File %s successfully opened. %d frames marked as bad frames', filename, rbad);
    %else
    %    mesg = sprintf('File %s successfully opened.', filename);
    %end
    %showmsg(h_mainfig, 'message', mesg);
    figure(h_mainfig);

    new_name = sprintf('WFI Reader: %s (large video mode) ', filename);
    set(h_mainfig, 'Name', new_name);

    % set default data processing frame range. for the largevmode, the last
    % frame is defined as max(data.actualframes)
    set(userdata.h_palmend, 'String', num2str(max(imginfo.actualframes)), 'enable', 'on');
    set(userdata.h_palmstart, 'String', '1', 'enable', 'on');
    
    % disable the 'gotoframe' response when typing the frame # in the box
	set(userdata.h_curframe, 'callback', '', 'enable', 'off');

    % activate disabled buttons
    set(userdata.h_play, 'enable', 'on');
    %set(userdata.h_select, 'enable', 'on');
    %set(h_mainfig, 'WindowButtonMotionFcn', @showpoint);
    set(userdata.h_plot, 'enable', 'off');
    set(userdata.h_find, 'enable', 'on');
    set(userdata.h_colormap, 'enable', 'on');
    set(userdata.h_export, 'enable', 'on');
    set(userdata.h_exporttype, 'enable', 'on');
    set(userdata.h_makecoord, 'enable', 'on');
    %set(userdata.h_palm, 'enable', 'on');   %--> moved to the new palm rendering program

    params.largevmode = 1;    
    showframe(1);

	set(h_mainfig, 'WindowButtonMotionFcn', @showpoint);
	enable_selection(h_mainfig, 'enable');
	axis image; zoom reset; onzoom(0, 'off'); onpan(0, 'off');
	set(userdata.h_pan, 'enable', 'on');
	set(userdata.h_zoom,'enable', 'on');
	set(userdata.h_resetview, 'enable', 'on');
	h = zoom; h.ActionPostCallback = @checkzoom;

return
