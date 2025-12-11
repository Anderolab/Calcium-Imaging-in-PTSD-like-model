% Function to check if a point is inside a polygon
function inside = is_inside_roi(x, y, roi_x, roi_y)
    inside = inpolygon(x, y, roi_x, roi_y);
end