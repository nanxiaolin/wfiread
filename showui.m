function showui()
%
% new function that loads main.fig and initializes interface and userdata
% this is re-written to facilitate future revisions of the interface and
% code

    global h_mainfig params;

    if h_mainfig
        msgbox('Another instance of WFI Reader is already running. Click OK to end.', 'Error', 'Error');
        return;
    end
    
    p = fileparts(mfilename('fullpath'));
    h_mainfig = open([p filesep 'fig' filesep 'main.fig']);
    warning off;

    winpos = get(h_mainfig, 'Position');
    window_width = winpos(3);        window_height = winpos(4);

    % position the window to the center of screen
    screen_size = get(0, 'screensize');
    screen_width = screen_size(3);		screen_height = screen_size(4);

    set(h_mainfig, 	...
        'unit', 'pixels', ...
        'position', [(screen_width - window_width)/2 (screen_height - window_height)/2 window_width window_height], ...
        'NumberTitle', 'off', ...
        'Name', 'WFI reader', ...
        'Resize', 'off', ...
        'ToolBar', 'none', ...
        'MenuBar', 'none');

    userdata = get(h_mainfig, 'userdata');
    userdata.h_axis = gca;

    axpos = get(gca, 'Position');
    % initialize a few parameters
    userdata.windowwidth = window_width;	userdata.windowheight = window_height;
    userdata.figurestartx = axpos(1);       userdata.figurestarty = axpos(2);
    userdata.figurewidth = axpos(3);        userdata.figureheight = axpos(4);
    userdata.file = '';			userdata.pref_dir = '~/Data';
    userdata.frames = 0;		userdata.h_selrect = -1;
	userdata.exp_dir = '';

    % figure numbers used by the program
    userdata.figdisplace = h_mainfig + 1;
    userdata.fig3d = h_mainfig + 2;
    userdata.figpalm = h_mainfig + 3;
    userdata.figlowres = h_mainfig + 4;
    userdata.figintensity = h_mainfig + 5;
    userdata.figposition = h_mainfig + 6;

    % get handles to the buttons
    userdata.h_open = findobj(h_mainfig, 'tag', 'btnopen');
    userdata.h_play = findobj(h_mainfig, 'tag', 'btnplay');
    userdata.h_slider = findobj(h_mainfig, 'tag', 'slider');
    
    %userdata.h_select = findobj(h_mainfig, 'tag', 'btnselect');
    userdata.h_threshold = findobj(h_mainfig, 'tag', 'edthreshold');
	userdata.h_smootharea = findobj(h_mainfig, 'tag', 'edSmoothArea');
	userdata.h_sigmamax = findobj(h_mainfig, 'tag', 'edSigmaMax');
	userdata.h_sigmamin = findobj(h_mainfig, 'tag', 'edSigmaMin');
    userdata.h_plot = findobj(h_mainfig, 'tag', 'btnplot');
    userdata.h_find = findobj(h_mainfig, 'tag', 'btnfind');
    userdata.h_fit = findobj(h_mainfig, 'tag', 'btnfit');
    userdata.h_mnuPF = findobj(h_mainfig, 'tag', 'mnuParticleFinding');
    userdata.h_mnuGF = findobj(h_mainfig, 'tag', 'mnuGaussFitting');
    %userdata.h_stats = findobj(h_mainfig, 'tag', 'btnstats');
    %userdata.h_zoomin = findobj(h_mainfig, 'tag', 'btnzoomin');

    userdata.h_export = findobj(h_mainfig, 'tag', 'btnexport');
	set(userdata.h_export, 'callback', @exportmovie);
    userdata.h_exporttype = findobj(h_mainfig, 'tag', 'mnexport');
    set(userdata.h_exporttype, 'callback', @onexporttype);
    userdata.h_exportselection = findobj(h_mainfig, 'tag', 'chkexportselection');
	userdata.h_frameskip = findobj(h_mainfig, 'tag', 'edFrameSkip');
	userdata.h_framerate = findobj(h_mainfig, 'tag', 'edFPS');

    % draw the 'track' button and controls
    userdata.h_track = findobj(h_mainfig, 'tag', 'btntrack');
    userdata.h_marker = findobj(h_mainfig, 'tag', 'btnaddmarker');
    userdata.h_markerdel = findobj(h_mainfig, 'tag', 'btndelmarker');

    % draw the PALM group of controls
    userdata.h_palm = findobj(h_mainfig, 'tag', 'btnpalm');
	set(userdata.h_palm, 'callback', @palm);
    userdata.h_palmstart = findobj(h_mainfig, 'tag', 'edpalmstart');
    userdata.h_palmend = findobj(h_mainfig, 'tag', 'edpalmend');
    userdata.h_makecoord = findobj(h_mainfig, 'tag', 'btnMakeCoordFile');
    set(userdata.h_makecoord, 'callback', @onmakecoord, 'enable', 'off');
    %userdata.h_palmupdate = findobj(h_mainfig, 'tag', 'chkpalmupdate');
    %userdata.h_palmupdateframes = findobj(h_mainfig, 'tag', 'edpalmupdateframes');
    %userdata.h_palmkeypause = findobj(h_mainfig, 'tag', 'chkpalmkeypause');

    % display settings control
    userdata.h_autoscale = findobj(h_mainfig, 'tag', 'chkautoscale');
    userdata.h_disphigh = findobj(h_mainfig, 'tag', 'eddisphigh');
    userdata.h_displow  = findobj(h_mainfig, 'tag', 'eddisplow');
    %colors = {'Gray', 'Autumn', 'Hot'};  %, 'Cyan', 'Blue', 'Green', 'Orange', 'Red', 'HiLow'};
    userdata.h_colormap = findobj(h_mainfig, 'tag', 'mncolormap');
    
	% misc controls
	userdata.h_curframe = findobj(h_mainfig, 'tag', 'edCurrentFrame');
	set(userdata.h_curframe, 'callback', @ongotoframe);

    % define callback functions of newly added buttons / controls
    set(findobj(h_mainfig, 'tag', 'chkaxison'), 'callback', @onmainaxis);
    set(findobj(h_mainfig, 'tag', 'chkgridon'), 'callback', @onmaingrid);
    set(findobj(h_mainfig, 'tag', 'chkboxon'), 'callback', @onmainbox);

    set(h_mainfig, 'userdata', userdata);
    set(h_mainfig, 'CloseRequestFcn', @closefigs);
    
    % set a few field for params;
    params.colormap = 'autumn';
    %params.frameskip = str2num(get(userdata.h_frameskip, 'string')) + 1;
    
return;
