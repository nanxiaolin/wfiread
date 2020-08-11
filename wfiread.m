%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main function: wfiread

function wfiread()
	% Originally written as a reader for WFI files
	% usage: wfiread
    %
    % Now has ability to read tif, tif stacks, PMA files
    % do gaussian fitting, particle tracking, and PALM/STORM data
    % processing
    %
    % 
    % Major update 03/2015: 
    % 1. added support for multichannel data by using a new data structure
    %    to store the image and parameter data
    % 2. changed the .cor file format to .loc (to accommodate multichannel
    %    data
    % 3. now wfiread and palm are integrated as one package
    % 4. the new package is renamed as nanoimg
    %
    %
	% initialize the program
    
    % intialize the img structure (that has all the image and parameter
    % data
    
    initiate_img();
	
    % initiate the user interface
    showui();
	
    
    % load the loci toolbox: this will corrupt the global variables
    % please do not uncomment
    % javaaddpath('/mnt/data0/shared/Matlab/wfiread/loci');

	% enable multi threaded operations	
	maxNumCompThreads(2);

return;

