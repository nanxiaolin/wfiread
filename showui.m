function showui()
%
% new function that loads main.fig and initializes interface and userdata
% this is re-written to facilitate future revisions of the interface and
% code

    global h_mainfig params;
    
    if isgraphics(h_mainfig)
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
        'NumberTitle', 'off', ...
        'Name', 'WFI reader', ...
        'Resize', 'off', ...
        'ToolBar', 'none', ...
        'MenuBar', 'none');

    %userdata = get(h_mainfig, 'userdata');
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
    h_figx = figure('visible', 'off');
    userdata.figdisplace = h_figx.Number;
    h_figx = figure('visible', 'off');
    userdata.fig3d = h_figx.Number;
    %userdata.figpalm = figure('visible', 'off');
    %userdata.figlowres = figure('visible', 'off');
    h_figx = figure('visible', 'off');
    userdata.figintensity = h_figx.Number;
    h_figx = figure('visible', 'off');
    userdata.figposition = h_figx.Number;

    % get handles to the buttons
    userdata.h_open = findobj(h_mainfig, 'tag', 'btnopen');
    set(userdata.h_open, 'callback', @openfile);
    userdata.h_play = findobj(h_mainfig, 'tag', 'btnplay');
    set(userdata.h_play, 'callback', @playmovie);
    userdata.h_slider = findobj(h_mainfig, 'tag', 'slider');
    set(userdata.h_slider, 'callback', @onslider);
    userdata.h_openlv = findobj(h_mainfig, 'tag', 'btnOpenLargeVideo');
    set(userdata.h_openlv, 'callback', @openlargefile);
	userdata.h_loadlinked = findobj(h_mainfig, 'tag', 'chkLoadAssocFiles');
    
    %userdata.h_select = findobj(h_mainfig, 'tag', 'btnselect');
    userdata.h_threshold = findobj(h_mainfig, 'tag', 'edthreshold');
	userdata.h_contrastfactor = findobj(h_mainfig, 'tag', 'edContrastFactor');
	userdata.h_sigmamax = findobj(h_mainfig, 'tag', 'edSigmaMax');
	userdata.h_sigmamin = findobj(h_mainfig, 'tag', 'edSigmaMin');
    userdata.h_plot = findobj(h_mainfig, 'tag', 'btnplot');
    set(userdata.h_plot, 'callback', @onplot);
    userdata.h_find = findobj(h_mainfig, 'tag', 'btnfind');
    set(userdata.h_find, 'callback', @findparticles);
	userdata.h_psfsize = findobj(h_mainfig, 'tag', 'edPSFsize');
	set(userdata.h_psfsize, 'callback', @onpsfsize);
    
    userdata.h_fit = findobj(h_mainfig, 'tag', 'btnfit');
    set(userdata.h_fit, 'callback', @onfit);
    userdata.h_mnuPF = findobj(h_mainfig, 'tag', 'mnuParticleFinding');
    userdata.h_mnuGF = findobj(h_mainfig, 'tag', 'mnuGaussFitting');
    %userdata.h_stats = findobj(h_mainfig, 'tag', 'btnstats');
    %userdata.h_zoomin = findobj(h_mainfig, 'tag', 'btnzoomin');

    userdata.h_export = findobj(h_mainfig, 'tag', 'btnexport');
	set(userdata.h_export, 'callback', @exportmovie);
    userdata.h_exporttype = findobj(h_mainfig, 'tag', 'mnuexporttype');
    set(userdata.h_exporttype, 'callback', @onexporttype);
    userdata.h_exportselection = findobj(h_mainfig, 'tag', 'chkexportselection');
	userdata.h_frameskip = findobj(h_mainfig, 'tag', 'edFrameSkip');
	userdata.h_framerate = findobj(h_mainfig, 'tag', 'edFPS');

    % draw the 'track' button and controls
    userdata.h_track = findobj(h_mainfig, 'tag', 'btntrack');
    set(userdata.h_track, 'callback', @ontrack);
    userdata.h_marker = findobj(h_mainfig, 'tag', 'btnaddmarker');
    set(userdata.h_marker, 'callback', @onmarker);
    userdata.h_markerdel = findobj(h_mainfig, 'tag', 'btndelmarker');
    set(userdata.h_markerdel, 'callback', @onmarkerdel);

    % draw the PALM group of controls
    %userdata.h_palm = findobj(h_mainfig, 'tag', 'btnpalm');
	%set(userdata.h_palm, 'callback', @palm);
    userdata.h_palmstart = findobj(h_mainfig, 'tag', 'edpalmstart');
    userdata.h_palmend = findobj(h_mainfig, 'tag', 'edpalmend');
    userdata.h_makecoord = findobj(h_mainfig, 'tag', 'btnMakeCoordFile');
    set(userdata.h_makecoord, 'callback', @onmakecoord, 'enable', 'off');
    %userdata.h_palmupdate = findobj(h_mainfig, 'tag', 'chkpalmupdate');
    %userdata.h_palmupdateframes = findobj(h_mainfig, 'tag', 'edpalmupdateframes');
    %userdata.h_palmkeypause = findobj(h_mainfig, 'tag', 'chkpalmkeypause');

    % display settings control
    userdata.h_autoscale = findobj(h_mainfig, 'tag', 'chkautoscale');
    set(userdata.h_autoscale,'callback', @onautoscale);
    userdata.h_disphigh = findobj(h_mainfig, 'tag', 'eddisphigh');
    userdata.h_displow  = findobj(h_mainfig, 'tag', 'eddisplow');
    %colors = {'Gray', 'Autumn', 'Hot'};  %, 'Cyan', 'Blue', 'Green', 'Orange', 'Red', 'HiLow'};
    userdata.h_colormap = findobj(h_mainfig, 'tag', 'mnucolormap');
    set(userdata.h_colormap, 'value', 3, 'callback', @oncolormap);
	userdata.h_zoom = findobj(h_mainfig, 'tag', 'chkMainZoom');
	set(userdata.h_zoom, 'value', 0, 'callback', @onzoom, 'enable', 'off');
	userdata.h_pan = findobj(h_mainfig, 'tag', 'chkMainPan');
	set(userdata.h_pan, 'value', 0, 'callback', @onpan, 'enable', 'off');
	userdata.h_resetview = findobj(h_mainfig, 'tag', 'btnResetview');
	set(userdata.h_resetview, 'callback', 'axis image; checkzoom', 'enable', 'off');
    userdata.h_image = -1;
    userdata.h_particlecenters = -1;
    
    % global variables
    params.colormap = 'hot';
    params.largevmode = 0;
    
	% misc controls
	userdata.h_curframe = findobj(h_mainfig, 'tag', 'edCurrentFrame');
	set(userdata.h_curframe, 'callback', @ongotoframe);

    % define callback functions of newly added buttons / controls
    set(findobj(h_mainfig, 'tag', 'chkaxison'), 'callback', @onmainaxis);
    set(findobj(h_mainfig, 'tag', 'chkgridon'), 'callback', @onmaingrid);
    set(findobj(h_mainfig, 'tag', 'chkboxon'), 'callback', @onmainbox);

    set(h_mainfig, 'userdata', userdata);
    set(h_mainfig, 'CloseRequestFcn', @closefigs);
      
return;
