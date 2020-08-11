function showmsg(parent, tag, mesg)
% function that updates message displayed in certain text fields marked by
% 'tag'

h = findobj(parent, 'tag', tag);
set(h, 'String', mesg);
