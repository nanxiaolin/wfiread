function answer = isbadframe(frame)
% tell if a frame is a bad frame (UV on or off suddenly, etc.)
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    
    if userdata.badframes == 0
        answer = 0;
    else
        if find(userdata.badframes == frame)
            answer = 1;
        else
            answer = 0;
        end
    end