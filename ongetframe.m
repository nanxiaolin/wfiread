function [img startx starty numChannels] = ongetframe(frame, selection, channel)
%
  global imgdata h_mainfig;
  
 if(isempty(h_mainfig) == 1)		% some java code messes up this variable
	h_mainfig = gcf;
end

  userdata = get(h_mainfig, 'userdata');
  
  % parse the input
  
  if nargin == 0 || frame == 0
      frame = userdata.currentframe;
  end
  
  if nargin == 2 
      channel = userdata.current_channel;
      pages = (frame - 1) * userdata.channels + channel;
      numChannels = 1;
  else
      if channel == 0 % all channels
          pages = (frame - 1) * userdata.channels + 1 : frame * userdata.channels;
          numChannels = userdata.channels;
      else
          pages = (frame - 1) * userdata.channels + channel;
          numChannels = 1;
      end
  end
  
  
  if nargin < 2   % full frame
      %temp = zeros(userdata.width, userdata.height, 'uint16');
      img = imgdata(:, :, pages);
      startx = 1;   starty = 1;
  elseif numel(selection) == 1     
      if selection == 0 || userdata.h_selrect == -1     % full frame    
          %temp = zeros(userdata.width, userdata.height, 'uint16');
          img = imgdata(:, :, pages);
          startx = 1;   starty = 1;
      else                 % current selection
          startx = userdata.selection(1);   starty = userdata.selection(2);
          endx   = userdata.selection(3);   endy   = userdata.selection(4);
          %temp = zeros(endx - startx + 1, endy - starty + 1, 'uint16');
          img = imgdata(startx : endx, starty : endy, pages);
      end
  else
      startx = selection(1);            starty = selection(2);
      if numel(selection) == 2
          img = imgdata(startx, starty, pages);
          return;
      else
          endx = selection(3);          endy = selection(4);
          %temp = zeros(endx - startx + 1, endy - starty + 1, 'uint16');
          img = imgdata(startx : endx, starty : endy, pages);
      end
  end
  
  %img = double(temp');
return
