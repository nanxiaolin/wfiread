function onplot(object, event)
%
    global h_mainfig;
    
    userdata = get(h_mainfig, 'userdata');
    intensity = zeros(userdata.frames, 1);
    
	for i=1:userdata.frames
        
        if isbadframe(i) && i>=2
            intensity(i) = intensity(i-1);
            continue;
        end
        
		img = getselection(i);
		intensity(i) = mean(mean(img));
    end
	
    color = rand(1, 3);
    
    %if (find(opened == userdata.figintensity))
    %    n = userdata.figintensity;
    %    figure(n); 
    %else
    n = figure(userdata.figintensity);
    plot([1:i], intensity, 'Color', color); axis on; hold on;
    set(n, 'NumberTitle', 'off', 'Name', 'Intensity Trajectory', 'visible', 'on');
	xlabel('Frame Number'); ylabel('Intensity (a.u.)');
	xlim([0 userdata.frames]);
	%ylim([0 65535]);

	grid on;	
	%figure(1);
