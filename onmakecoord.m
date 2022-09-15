function onmakecoord(object, event)
%
% function that produces a coordinate matrix for the entire
% movie and save it to a file with the same name as main data file

global h_mainfig params;

use_gpu = get(findobj(h_mainfig, 'tag', 'chkUseGPU'), 'value');

if params.largevmode == 0
    % normal operations
    if use_gpu == 0
        showmsg(h_mainfig, 'message', 'Using CPU for coordinate extraction ...');
        pause(0.5);
        makecoord_cpu;
    else
        showmsg(h_mainfig, 'message', 'Using GPU for coordinate extraction ...');
        pause(0.5);
        makecoord_gpu; 
    end
else
   % large video operation
   if use_gpu == 0
        showmsg(h_mainfig, 'message', 'Coordinate extraction in large video mode using CPU ...');
        pause(0.5);
        makecoord_cpu_lv;
   else
        showmsg(h_mainfig, 'message', 'Coordinate extraction in large video mode using CPU ...');
        pause(0.5);
        makecoord_gpu_lv;
   end
end

	