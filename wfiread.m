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
	% initialize the interface
    
	showui();
	%
	%openfile();
    
    % load the loci toolbox: this will corrupt the global variables
    % please do not uncomment
    % javaaddpath('/mnt/data0/shared/Matlab/wfiread/loci');

	% enable multi threaded operations	
	maxNumCompThreads(2);

return;

