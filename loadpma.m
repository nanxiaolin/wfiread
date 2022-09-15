function data = loadpma(fp)

global imgdata h_mainfig;

userdata = get(h_mainfig, 'userdata');

%disp 'PMA file opened.';
width = fread(fp, 1, 'uint16');
height = fread(fp, 1, 'uint16');

frame_size = width * height * 2;
fseek(fp, -2-frame_size, 'eof');
frames = fread(fp, 1, 'uint16');
max_frames = floor(3.0e9/(width * height));

if frames > max_frames
    frames = max_frames;
end

fseek(fp, 4, 'bof');

if numel(imgdata)
	imgdata = [];
end

imgdata = zeros(frames, width, height, 'uint16');
intensity = zeros(frames, 1);

for i=1:frames
    fread(fp, 1, 'uint16');
    imgdata (i, :, :) = fread(fp, [width height], 'uint16');
    %intensity(i) = mean(mean(imgdata(i, 1:width, 1:height/5)));

    if mod(i, 100) == 0 || i == frames
        new_name = sprintf('WFI Reader: loading frame %d of %d', i, frames);
        showmsg(h_mainfig, 'message', new_name);
        pause(0.001);
    end
end

% remove the bad frames
%figure(userdata.figintensity);
%set(userdata.figintensity, 'numbertitle', 'off', 'name', 'Intensity Differential');
%intensity = intensity ./ mean(intensity(1:frames));
%plot(1:frames-1, abs(diff(intensity))); grid on;
%int_diff = abs(diff(intensity));
%has_bad = find(int_diff > 0.01);
%badframes = zeros(numel(has_bad), 1);
%rbad = 0;

%if has_bad
%    nbad = numel(has_bad);
%    for k = 1 : nbad - 1
%        if has_bad(k + 1) - has_bad(k) == 1
%            rbad = rbad + 1;
%            badframes(rbad) = has_bad(k) + 1;
%        end
%    end
%    data.badframes = badframes(1:rbad);
%else
    data.badframes = 0;
%end

% assign data fields
data.width = width;
data.height = height;
data.frames = frames;
%data.intensity = intensity;
data.rbad = 0;

return
