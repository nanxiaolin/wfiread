function onmouseclick(object, event)
% function that handles mouse click events
% it tells left from right clicks and call appropriate functions
global h_mainfig;

seltype = get(h_mainfig, 'SelectionType');

switch seltype
    case 'normal'       % left click
        startselection();
    case 'alt'
        clearselection();
end