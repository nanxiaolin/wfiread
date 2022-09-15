function exportmovie(object, event)
% function that exports current movie into avi
% using the current colormap (shown on screen)
% so before epxorting make sure the display range is properly adjusted
    
    global h_mainfig;

    userdata = get(h_mainfig, 'userdata');
    frames = userdata.frames;

	frame_skip = str2double(get(userdata.h_frameskip, 'string')) + 1;
	frame_rate = str2double(get(userdata.h_framerate, 'string'));

    cm = colormap;

    % let the user choose a file name
    pref_dir = userdata.exp_dir;
    [~, name, ~] = fileparts(userdata.file);
    pref_file = fullfile(pref_dir, name);

    extension = {'*.avi', 'Audio Video Interlace File (*.AVI)'};
    [filename, pathname] = uiputfile(extension, 'Choose a filename for the movie', pref_file);

    if isempty(filename)
        return;
    end

	userdata.exp_dir = pathname;

    %[path, name, ext] = fileparts(filename);
    fullname = fullfile(pathname, filename);

    aviobj = VideoWriter(fullname, 'Uncompressed AVI');
    aviobj.FrameRate = frame_rate;
    open(aviobj);

    titlemsg = get(h_mainfig, 'name');
    sel_only = get(userdata.h_exportselection, 'value');

 	pstart = str2double(get(userdata.h_palmstart, 'string'));
    pend   = str2double(get(userdata.h_palmend, 'string'));
    
    if pstart < 1
        pstart = 1;
    end
    
    if pend > frames
        pend = frames;
    end
    

    for i = pstart : frame_skip : pend
        if sel_only == 0
            img =  ongetframe(i);
        else
            img = getselection(i);
        end

        % adjust image display range according to settings
        mins = str2double(get(userdata.h_displow, 'String'));
        maxs = str2double(get(userdata.h_disphigh, 'String'));

        img = uint8(length(cm) * (img - mins)/(maxs - mins));
        img(img > length(cm) -1) = length(cm)-1;

        F = im2frame(img, cm);

        % convert the frame into AVI
        writeVideo(aviobj, F);

        newtitlemsg = sprintf('WFI Reader - Converting frame %d', i);
        set(h_mainfig, 'name', newtitlemsg);
        pause(0.01);
    end

    %figure(2); movie(F);
    close(aviobj);
    set(h_mainfig, 'name', titlemsg);

	message = sprintf('Movie %s \n has been created successfully.', filename);
    uiwait(msgbox(message, 'Message', 'OK'));

	% remembered changed settings
	set(h_mainfig, 'userdata', userdata);

    return
