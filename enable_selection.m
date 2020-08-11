function enable_selection(fignum, option)

switch option
    case 'enable'
        set(fignum, 'WindowButtonDownFcn', @onmouseclick);
    case 'disable'
        set(fignum, 'WindowButtonDownFcn', '');
end