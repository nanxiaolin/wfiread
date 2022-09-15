function [sel startx starty] = getselection(frame)
% function that retrieves selection image
% getselection() will get the selected area of the current frame
% getselection(frame) will get the selected area in frame 'frame'

if nargin == 0
    [sel startx starty] = ongetframe(0.0, 1);
else
    [sel startx starty] = ongetframe(frame, 1);
end