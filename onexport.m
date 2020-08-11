function onexport(object, event)
% function that exports current movie into avi
% using the current colormap (shown on screen)
% so before epxorting make sure the display range is properly adjusted
    
    %global h_mainfig;

    %userdata = get(h_mainfig, 'userdata');
    
    %sel = get(userdata.h_exporttype, 'value');
    
    %switch sel
    %    case 1
    %        exportview();
    %    case 2
    %        exportmovie();
    %end
    
%     frames = userdata.frames;
% 
%     cm = colormap;
% 
%     % let the user choose a file name
%     pref_dir = userdata.pref_dir;
%     [path name ext] = fileparts(userdata.file);
%     pref_file = fullfile(pref_dir, name);
% 
%     extension = {'*.avi', 'Audio Video Interlace File (*.AVI)'};
%     [filename pathname] = uiputfile(extension, 'Choose a filename for the movie', pref_file);
% 
%     if filename == 0
%         return;
%     end
% 
%     [path name ext] = fileparts(filename);
%     fullname = fullfile(pathname, filename);
%     %whos
% 
%     %[quality compression fps sel_only] = getavipara(90, 'none', 3, 0);
% 
%     aviobj = avifile(fullname);
%     aviobj.quality = 90;
%     aviobj.compression = 'none';
%     aviobj.fps = 3;
%     % not supported under linux, unfortunately
% 
%     titlemsg = get(h_mainfig, 'name');
%     sel_only = get(userdata.h_exportselection, 'value');
% 
%     for i = 1 : frames
%         if sel_only == 0
%             img =  ongetframe(i);
%         else
%             img = getselection(i);
%         end
% 
%         % adjust image display range according to settings
%         mins = str2num(get(userdata.h_displow, 'String'));
%         maxs = str2num(get(userdata.h_disphigh, 'String'));
% 
%         img = uint8(255.0 * ((img - mins)/(maxs - mins)));
% 
%         F(i) = im2frame(img, cm);
% 
%         % convert the frame into AVI
%         aviobj = addframe(aviobj, F(i));
% 
%         newtitlemsg = sprintf('WFI Reader - Converting frame %d', i);
%         set(h_mainfig, 'name', newtitlemsg);
%         pause(0.001);
%     end
% 
%     %figure(2); movie(F);
%     aviobj = close(aviobj);
%     set(h_mainfig, 'name', titlemsg);
% 
%     uiwait(msgbox('Movie created successfully', 'Message', 'OK'));

%     function [quality compression fps sel_only] = getavipara(quality, compression, fps, sel_only)
%         para_fig = 100;
% 
%         figure(para_fig, 'NumberTitle', 'off', 'Name', 'Avi Parameters', 'MenuBar', 'none', '
%     end
