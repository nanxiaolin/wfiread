function openfile(obj, event)
% function that handles image file opening

    global h_mainfig params;

    userdata = get(h_mainfig, 'userdata');
    pref_dir = userdata.pref_dir;

    extension = {'*.tif; *.stk; *.lsm; *.nd2', 'Bio-format Supported Files (*.TIF, *.LSM, *.STK, *.ND2)'; ...
	'*.pma', 'WFI raw data file (*.PMA)'; ...
        '*.tif', 'TIF sequence (*.TIFs)'};
    [filename pathname fi] = uigetfile(extension, 'Select a file to open', pref_dir);
    %pathname = '/home/xiaolin/Data/2008.08.14';
    %filename = 'with_godcat_af488_500ms_0.pma';

    if filename == 0
        return;
    end

    %[path name ext] = fileparts(filename);
    fullname = fullfile(pathname, filename);

    % open the file
    fp = fopen(fullname);
    if ~fp
        showmsg(h_mainfig, 'message', 'Failed to open file.');
        return;
    end

    enable_selection(h_mainfig, 'disable');
	set(h_mainfig, 'WindowButtonMotionFcn', '');
   
    % read the data
    switch fi
        case 2	% PMA files
            data = loadpma(fp);
            fclose(fp);
        case 1  % Bio-Formats Package Supported File Types (.LSM; .STK; .ND2; .TIF; etc)
            fclose(fp);		% pass the full file name to bf package
            data = loadbf(fullname);
        case 3  % TIF sequences
        	fclose(fp);
            data = loadtiffseq(pathname, filename);
    end

    if isempty(data)        % something wrong and data not retrieved
        showmsg(h_mainfig, 'message', 'Failed to read data from file. ');
        
        if ~isempty(filename)
            enable_selection(h_mainfig, 'enable');
        end
        
        return;
    end

    % assign fields
    width = data.width;
    height = data.height;
    frames = data.numFrames;
    channels = data.numChannels;
    rbad = data.rbad;
    h_mainfig = gcf;		% this is a temp fix for a weird problem caused by loadbf() function which clears up h_mainfig variable

    % save the configuration
    userdata.badframes = data.badframes;
    userdata.file = filename;
    userdata.pref_dir = pathname;
	%userdata.exp_dir = pathname;		% reset export dir to curret folder
    userdata.width = width;
    userdata.height = height;
    userdata.frames = frames;
    userdata.channels = channels;
    userdata.currentframe = 1;
    userdata.currentchannel = 0;        % assumes all channels
    userdata.axison = get(findobj(h_mainfig, 'tag', 'chkaxison'), 'value');
    userdata.gridon = get(findobj(h_mainfig, 'tag', 'chkgridon'), 'value');

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

    set(h_mainfig, 'userdata', userdata);

    setslider();

    % update text message fields
    mesg = sprintf('%d', frames);
    showmsg(h_mainfig, 'totalframes', mesg);
    if rbad
        mesg = sprintf('File %s successfully opened. %d frames marked as bad frames', fullname, rbad);
    else
        mesg = sprintf('File %s successfully opened.', fullname);
    end
    showmsg(h_mainfig, 'message', mesg);
    figure(h_mainfig);

    new_name = sprintf('WFI Reader: %s', fullname);
    set(h_mainfig, 'Name', new_name);

    % we need to enable the palm start and ending frames
	set(userdata.h_palmstart, 'enable', 'on');
	set(userdata.h_palmend, 'enable', 'on');
    % set default data processing frame range
    set(userdata.h_palmend, 'String', num2str(frames));
    set(userdata.h_palmstart, 'String', '1');
    set(userdata.h_frameskip, 'enable', 'on', 'string', '0');

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

    %showframe(1);
    %fclose(fp);

	set(h_mainfig, 'WindowButtonMotionFcn', @showpoint);
	enable_selection(h_mainfig, 'enable');
    
%     % set the params field
%     params.factor = str2num(get(userdata.h_threshold, 'String'));
%     params.sig_min = str2num(get(userdata.h_sigmamin, 'String'));
% 	params.sig_max = str2num(get(userdata.h_sigmamax, 'String'));
%    	params.sm_area = str2num(get(userdata.h_smootharea, 'String'));
% 	% see which method is chosen to identify the particles
% 	params.meth = get(userdata.h_mnuPF, 'value');
%     

return
