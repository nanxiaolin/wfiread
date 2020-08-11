function displ = displace(coord)

% r = displace(t, dist_per_pixel, sec_per_frame)
% calculate the displacement along the time series
% xy: the (x, y) coordinate pairs. must be n x 2 matrix
x = coord(:, 1);
y = coord(:, 2);

points = length(x);
displ = zeros(points, 1);

for k = 1 : points
    displ(k) = sqrt((x(k) - x(1))^2 + (y(k) - y(1))^2);
end