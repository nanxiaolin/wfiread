function onautoscale(object, event)
% function that handles autoscale clicking event
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');

    status = get(userdata.h_autoscale, 'Value');

    if status == 1 && userdata.frames > 0
       % refresh the current frame display
       showframe(userdata.currentframe);
    end
