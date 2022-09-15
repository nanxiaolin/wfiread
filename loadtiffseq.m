function data = loadtiffseq(path, file)
%
% function data = loadtiffseq(path, file)
%   function that load a tiff sequence from the first input file

% prepare the matrices as data containers
global imgdata h_mainfig;

userdata = get(h_mainfig, 'userdata');

% first, analyze the directory for files with similar names

