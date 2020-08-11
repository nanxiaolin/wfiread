function exportmovie(object, event)
% function that exports current movie into avi
% using the current colormap (shown on screen)
% so before epxorting make sure the display range is properly adjusted
    
    global h_mainfig;

    userdata = get(h_mainfig, 'userdata');
    frames = userdata.frames;

	frame_skip = str2num(get(userdata.h_frameskip, 'string'));
	frame_rate = str2num(get(userdata.h_framerate, 'string'));

    cm = colormap;

    % let the user choose a file name
    pref_dir = userdata.exp_dir;
    [path name ext] = fileparts(userdata.file);
    pref_file = fullfile(pref_dir, name);

    extension = {'*.avi', 'Audio Video Interlace File (*.AVI)'};
    [filename pathname] = uiputfile(extension, 'Choose a filename for the movie', pref_file);

    if filename == 0
        return;
    end

	userdata.exp_dir = pathname;

    [path name ext] = fileparts(filename);
    fullname = fullfile(pathname, filename);
    %whos

    %[quality compression fps sel_only] = getavipara(90, 'none', 3, 0);

    aviobj = avifile(fullname);
    aviobj.quality = 90;
    aviobj.compression = 'none';
    aviobj.fps = frame_rate;
    % not supported under linux, unfortunately

    titlemsg = get(h_mainfig, 'name');
    sel_only = get(userdata.h_exportselection, 'value');

 	pstart = str2num(get(userdata.h_palmstart, 'String'));
    pend   = str2num(get(userdata.h_palmend, 'string'));
    

    for i = pstart : frame_skip : pend
        if sel_only == 0
            img =  ongetframe(i);
        else
            img = getselection(i);
        end

        % adjust image display range according to settings
        mins = str2num(get(userdata.h_displow, 'String'));
        maxs = str2num(get(userdata.h_disphigh, 'String'));

        img = uint8(255.0 * ((img - mins)/(maxs - mins)));

        F(i) = im2frame(img, cm);

        % convert the frame into AVI
        aviobj = addframe(aviobj, F(i));

        newtitlemsg = sprintf('WFI Reader - Converting frame %d', i);
        set(h_mainfig, 'name', newtitlemsg);
        pause(0.001);
    end

    %figure(2); movie(F);
    aviobj = close(aviobj);
    set(h_mainfig, 'name', titlemsg);

	message = sprintf('Movie %s \n has been created successfully.', filename);
    uiwait(msgbox(message, 'Message', 'OK'));

	% remembered changed settings
	set(h_mainfig, 'userdata', userdata);


%     function [quality compression fps sel_only] = getavipara(quality, compression, fps, sel_only)
%         para_fig = 100;
% 
%         figure(para_fig, 'NumberTitle', 'off', 'Name', 'Avi Parameters', 'MenuBar', 'none', '
%     end
