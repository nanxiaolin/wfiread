function showframe(frame, mode)
% function to show a specific frame
%
% if input has both parameters the call is not by dragging the slider so slider position will be manually updated

  global h_mainfig params;
  
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
        mins = str2double(get(userdata.h_displow, 'String'));
        maxs = str2double(get(userdata.h_disphigh, 'String'));
  end

  img = ongetframe(frame);
  img = 255.0 * ((img - mins)/(maxs - mins));
  
  % store the selection rectangle information
  if ishandle(userdata.h_selrect)
	pos = get(userdata.h_selrect, 'Position');
    selected = 1;
  else
    selected = 0;
  end

  %if h_mainfig ~= gcf
  %figure(h_mainfig);
  %end
  
  hold off; 
  % 2018/09/15 trying to fix the slow update speed with imshow.
  if userdata.h_image == -1     % figure has not been previously drawn yet
      userdata.h_image = imshow(img, [0 255]);
      colormap(gca, params.colormap);
      
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
      
  else
      set(userdata.h_image, 'CData', img);
      %userdata.h_image = imshow(img, [0,255]);
      %colormap(gca, params.colormap);
  end

  %userdata.h_image = imshow(img, [0,255]);
  %userdata.h_image = imagesc(img); 
  %colormap(gca, params.colormap);
 
  %figure(h_mainfig); 
  hold on;
  
  % redraw the selection box
  %if selected
    %disp('redrawing selection ...');
  %	userdata.h_selrect = rectangle('Position', pos, 'LineStyle', '-', 'EdgeColor', [0.6,0.6,0.6]);
  %end
  
  if userdata.h_particlecenters ~= -1
      delete(userdata.h_particlecenters);
      userdata.h_particlecenters = -1;
  end
  
  % now deal with the fiducial markers
  %start_frame = str2num(get(userdata.h_palmstart, 'string'));
  %end_frame   = str2num(get(userdata.h_palmend, 'string'));
  
  %if (userdata.markernum > 0) && (frame >= start_frame) && (frame <= end_frame)
  %   for i = 1 : userdata.markernum
      % markerpos(i, 1) = get(userdata.markerhandles(i), 'XData');
      % markerpos(i, 2) = get(userdata.markerhandles(i), 'YData');
	  % redraw the green cross on current fiducial markers
	  %if userdata.markernum > 0 && frame >= start_frame
	  
  %     userdata.markerhandles(i) = plot(userdata.markers(i, frame, 1), userdata.markers(i, frame, 2), '+g', 'LineWidth', 2, 'MarkerSize', 6);
  %   end
  %end
  

  % deal with axis options  

  frame = round(double(frame));
  userdata.currentframe = frame;
    
  % the actual frame # is stored in userdata.actualframes - to accommodate
  % the large video mode.
  titlemsg = sprintf('%.0f', userdata.actualframes(frame));
  set(userdata.h_curframe, 'String', titlemsg);
  
  % if not by sliding the slider, change the slider position
  if nargin > 1
  	set(userdata.h_slider, 'Value', frame - 1);
  end
  
  set(h_mainfig, 'userdata', userdata);
  set(gca, 'FontSize', 7);
  
  drawnow;
  
return
