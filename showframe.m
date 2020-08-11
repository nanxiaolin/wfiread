function showframe(frame, mode)
% function to show a specific frame
%
% if input has both parameters the call is not by dragging the slider so slider position will be manually updated

  global h_mainfig params;
  
  if(isempty(h_mainfig) == 1)		% some java code messes up this variable
	h_mainfig = gcf;
  end
  
  userdata = get(h_mainfig, 'userdata');
  
  img = getselection();

  % determine the display range
  if get(userdata.h_autoscale, 'Value') == 1   % autoscale on
	mins = min(min(img));
  	maxs = max(max(img));
	% set the display high low values
        set(userdata.h_disphigh, 'String', int2str(maxs));
        set(userdata.h_displow, 'String', int2str(mins));
  else
        mins = str2num(get(userdata.h_displow, 'String'));
        maxs = str2num(get(userdata.h_disphigh, 'String'));
  end

  img = ongetframe(frame);
  img = 255.0 * ((img - mins)/(maxs - mins));
	
  % store the selection rectangle information
  if userdata.h_selrect > 0
	pos = get(userdata.h_selrect, 'Position');
  end

  if h_mainfig ~= gcf
      figure(h_mainfig);
  end
  
  hold off;
  userdata.h_image = imshow(img, [0 255]);
  colormap(params.colormap);

  figure(h_mainfig); hold on;

  % redraw the selection box
  if userdata.h_selrect > 0
  	userdata.h_selrect = rectangle('Position', pos, 'LineStyle', '-', 'EdgeColor', [0.6,0.6,0.6]);
  end
  
  % now deal with the fiducial markers
  start_frame = str2num(get(userdata.h_palmstart, 'string'));
  end_frame   = str2num(get(userdata.h_palmend, 'string'));
  
  if (userdata.markernum > 0) && (frame >= start_frame) && (frame <= end_frame)
     for i = 1 : userdata.markernum
      % markerpos(i, 1) = get(userdata.markerhandles(i), 'XData');
      % markerpos(i, 2) = get(userdata.markerhandles(i), 'YData');
	  % redraw the green cross on current fiducial markers
	  %if userdata.markernum > 0 && frame >= start_frame
	  
       userdata.markerhandles(i) = plot(userdata.markers(i, frame, 1), userdata.markers(i, frame, 2), '+g', 'LineWidth', 2, 'MarkerSize', 6);
     end
  end

  % deal with axis options  
  if userdata.axison
      axis on;
  else
      axis off;
  end
  
  if userdata.gridon
      grid on;
  else
      grid off;
  end

  userdata.currentframe = frame;
  
  titlemsg = sprintf('%d', frame);
  set(userdata.h_curframe, 'String', titlemsg);

  % if not by sliding the slider, change the slider position
  if nargin > 1
  	set(userdata.h_slider, 'Value', frame);
  end
       
  set(h_mainfig, 'userdata', userdata);
  
return
