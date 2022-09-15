function playmovie(obj, event)
% function that plays the movie
    global h_mainfig params;
    
    userdata = get(h_mainfig, 'userdata');

    if isempty(userdata.file)
        msgbox('no movies open');
        return;
    end

    startframe = double(userdata.currentframe);
    frameskip = str2double(get(userdata.h_frameskip, 'String')) + 1;
    stop = 0;

    set(userdata.h_play, 'callback', @stopmovie);
    set(userdata.h_play, 'String', 'Stop');
    
    for i=startframe: frameskip : userdata.frames
        showframe(i);
        %findparticles();
        set(userdata.h_slider, 'Value', i - 1);
        %pause(0.01);
        
        if stop == 1
            break;
        end
        
    end

    set(userdata.h_play, 'callback', @playmovie);
    set(userdata.h_play, 'String', 'Play');

    function stopmovie(object, event)
        stop = 1;
    end
end
