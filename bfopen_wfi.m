function [result] = bfopen_wfi(id)
% This script is rewritten based on the loci package to work with the wfi
% package. 
% 
% Modified by Xiaolin Nan, Oregon Health and Science University
% 09/01/2012
%
% A script for opening microscopy images in MATLAB using Bio-Formats.
%
% The function returns a list of image series; i.e., a cell array of cell
% arrays of (matrix, label) pairs, with each matrix representing a single
% image plane, and each inner list of matrices representing an image
% series. See below for examples of usage.
%
% Portions of this code were adapted from:
% http://www.mathworks.com/support/solutions/en/data/1-2WPAYR/
%
% This method is ~1.5x-2.5x slower than Bio-Formats's command line
% showinf tool (MATLAB 7.0.4.365 R14 SP2 vs. java 1.6.0_20),
% due to overhead from copying arrays.
%
% Thanks to all who offered suggestions and improvements:
%     * Ville Rantanen
%     * Brett Shoelson
%     * Martin Offterdinger
%     * Tony Collins
%     * Cris Luengo
%     * Arnon Lieber
%     * Jimmy Fong
%
% NB: Internet Explorer sometimes erroneously renames the Bio-Formats library
%     to loci_tools.zip. If this happens, rename it back to loci_tools.jar.
%
% For many examples of how to use the bfopen function, please see:
%     http://trac.openmicroscopy.org.uk/ome/wiki/BioFormats-Matlab

% -- Configuration - customize this section to your liking --

% Toggle the autoloadBioFormats flag to control automatic loading
% of the Bio-Formats library using the javaaddpath command.
%
% For static loading, you can add the library to MATLAB's class path:
%     1. Type "edit classpath.txt" at the MATLAB prompt.
%     2. Go to the end of the file, and add the path to your JAR file
%        (e.g., C:/Program Files/MATLAB/work/loci_tools.jar).
%     3. Save the file and restart MATLAB.
%
% There are advantages to using the static approach over javaaddpath:
%     1. If you use bfopen within a loop, it saves on overhead
%        to avoid calling the javaaddpath command repeatedly.
%     2. Calling 'javaaddpath' may erase certain global parameters.
autoloadBioFormats = 1;

% Toggle the stitchFiles flag to control grouping of similarly
% named files into a single dataset based on file numbering.
stitchFiles = 0;

% To work with compressed Evotec Flex, fill in your LuraWave license code.
%lurawaveLicense = 'xxxxxx-xxxxxxx';

% -- Main function - no need to edit anything past this point --

% load the Bio-Formats library into the MATLAB environment
status = bfCheckJavaPath(autoloadBioFormats);
assert(status, ['Missing Bio-Formats library. Either add loci_tools.jar '...
    'to the static Java path or add it to the Matlab path.']);

% Prompt for a file if not input
if nargin == 0 || exist(id, 'file') == 0
  [file, path] = uigetfile(bfGetFileExtensions, 'Choose a file to open');
  id = [path file];
  if isequal(path, 0) || isequal(file, 0), return; end
end

% initialize logging
loci.common.DebugTools.enableLogging('INFO');

% Get the channel filler
r = bfGetReader(id, stitchFiles);

numSeries = r.getSeriesCount();
result = cell(numSeries, 2);
for s = 1:numSeries
    fprintf('Reading series #%d', s);
    r.setSeries(s - 1);
    pixelType = r.getPixelType();
    bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
    bppMax = power(2, bpp * 8);
    numImages = r.getImageCount();
    imageList = cell(numImages, 2);
    colorMaps = cell(numImages);
    for i = 1:numImages
        if mod(i, 100) == 0
            fprintf('.');
        end
        
        if mod(i, 7000) == 0
        	fprintf('\n');
        end
        
        arr = bfGetPlane(r, i);

        % retrieve color map data
        if bpp == 1
            colorMaps{s, i} = r.get8BitLookupTable()';
        else
            colorMaps{s, i} = r.get16BitLookupTable()';
        end
        
        warning off
        if ~isempty(colorMaps{s, i})
            newMap = single(colorMaps{s, i});
            newMap(newMap < 0) = newMap(newMap < 0) + bppMax;
            colorMaps{s, i} = newMap / (bppMax - 1);
        end
        warning on


        % build an informative title for our figure
        label = id;
        if numSeries > 1
            qs = int2str(s);
            label = [label, '; series ', qs, '/', int2str(numSeries)];
        end
        if numImages > 1
            qi = int2str(i);
            label = [label, '; plane ', qi, '/', int2str(numImages)];
            if r.isOrderCertain()
                lz = 'Z';
                lc = 'C';
                lt = 'T';
            else
                lz = 'Z?';
                lc = 'C?';
                lt = 'T?';
            end
            zct = r.getZCTCoords(i - 1);
            sizeZ = r.getSizeZ();
            if sizeZ > 1
                qz = int2str(zct(1) + 1);
                label = [label, '; ', lz, '=', qz, '/', int2str(sizeZ)];
            end
            sizeC = r.getSizeC();
            if sizeC > 1
                qc = int2str(zct(2) + 1);
                label = [label, '; ', lc, '=', qc, '/', int2str(sizeC)];
            end
            sizeT = r.getSizeT();
            if sizeT > 1
                qt = int2str(zct(3) + 1);
                label = [label, '; ', lt, '=', qt, '/', int2str(sizeT)];
            end
        end

        % save image plane and label into the list
        imageList{i, 1} = arr;
        imageList{i, 2} = label;
    end

    % extract metadata table for this series
    metadataList = r.getMetadata();

    % save images and metadata into our master series list
    result{s, 1} = imageList;
    result{s, 2} = metadataList;
    result{s, 3} = colorMaps;
    result{s, 4} = r.getMetadataStore();
    fprintf('\n');
end
r.close();
