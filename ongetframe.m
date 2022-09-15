function [img, startx, starty] = ongetframe(frame, selection)
%
  global imgdata;
  global h_mainfig;
  
 %if(isempty(h_mainfig) == 1)		% some java code messes up this variable
 %	h_mainfig = gcf;
 %end

  userdata = get(h_mainfig, 'userdata');
  
  if nargin == 0 || frame == 0
      frame = userdata.currentframe;
  end

  % the following is due to a very strange behavior of 'frame' once it is
  % above 65535
  frame = double(round(frame));
 
  if nargin < 2   % full frame
      %temp = zeros(userdata.height, userdata.width, 'uint16');
      temp = imgdata(:, :, frame);
      startx = 1;   starty = 1;
  elseif numel(selection) == 1     
      if selection == 0 || ~isgraphics(userdata.h_selrect)     % full frame    
          %temp = zeros(userdata.height, userdata.width, 'uint16');
          temp = imgdata(:, :, frame);
          startx = 1;   starty = 1;
      else                 % current selection
          startx = userdata.selection(1);   starty = userdata.selection(2);
          endx   = userdata.selection(3);   endy   = userdata.selection(4);
          %temp = zeros(endy - starty + 1, endx - startx + 1, 'uint16');
          temp = imgdata(starty : endy, startx : endx, frame);
      end
  else
      startx = selection(1);            starty = selection(2);
      if numel(selection) == 2
          img = imgdata(starty, startx, frame);
          return;
      else
          endx = selection(3);          endy = selection(4);
          %temp = zeros(endy - starty + 1, endx - startx + 1, 'uint16');
          temp = imgdata(starty : endy, startx : endx, frame);
      end
  end
  
  img = double(temp);
return
