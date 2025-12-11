function [enter_frames] = F_BodyPartInROI(data,col_num_x, col_num_y, numROIs, position, names)
% Loop through the frames to check if the body part that enters the ROI(s)

% For simplicity, let's assume you have frame numbers and body part coordinates in your data
frame_numbers = data(:, 1); % Replace with the actual column containing frame numbers
body_part_x = data(:, col_num_x);   % Replace with the actual column containing body part x-coordinates
body_part_y = data(:, col_num_y);   % Replace with the actual column containing body part y-coordinates

% Define the x and y coordinates of the body part (replace with your data)
x = body_part_x;
y = body_part_y;

% Initialize variables to store the results for each ROI
enter_frames = cell(numROIs, 1); % Cell array to store results for each ROI

% Loop through each ROI
for roiIdx = 1:numROIs
    % Define the x and y coordinates of the current ROI (replace with your ROI coordinates)
    roi_x = {}; % Cell array to store x-coordinates of the current ROI
    roi_y = {}; % Cell array to store y-coordinates of the current ROI

    % Add your ROI coordinates as cell arrays here (each cell contains the coordinates of one ROI)
    if numROIs == 1
        roi_x{1} = position{1}(:, 1); % Replace with coordinates for ROI 1
        roi_y{1} = position{1}(:, 2); % Replace with coordinates for ROI 1
    elseif numROIs == 2
        roi_x{1} = position{1}(:, 1); % Replace with coordinates for ROI 1
        roi_y{1} = position{1}(:, 2); % Replace with coordinates for ROI 1
        roi_x{2} = position{2}(:, 1); % Replace with coordinates for ROI 2
        roi_y{2} = position{2}(:, 2); % Replace with coordinates for ROI 2
    elseif numROIs == 3
        roi_x{1} = position{1}(:, 1); % Replace with coordinates for ROI 1
        roi_y{1} = position{1}(:, 2); % Replace with coordinates for ROI 1
        roi_x{2} = position{2}(:, 1); % Replace with coordinates for ROI 2
        roi_y{2} = position{2}(:, 2); % Replace with coordinates for ROI 2
        roi_x{3} = position{3}(:, 1); % Replace with coordinates for ROI 3
        roi_y{3} = position{3}(:, 2); % Replace with coordinates for ROI 3
    elseif numROIs == 4
        roi_x{1} = position{1}(:, 1); % Replace with coordinates for ROI 1
        roi_y{1} = position{1}(:, 2); % Replace with coordinates for ROI 1
        roi_x{2} = position{2}(:, 1); % Replace with coordinates for ROI 2
        roi_y{2} = position{2}(:, 2); % Replace with coordinates for ROI 2
        roi_x{3} = position{3}(:, 1); % Replace with coordinates for ROI 3
        roi_y{3} = position{3}(:, 2); % Replace with coordinates for ROI 3
        roi_x{4} = position{4}(:, 1); % Replace with coordinates for ROI 4
        roi_y{4} = position{4}(:, 2); % Replace with coordinates for ROI 4
    else
        disp('Invalid number of ROIs. Please enter 1 or 2.');
        return; % Exit the script if the number of ROIs is invalid
    end

    % Initialize variables to store the results for the current ROI
    enter_frame = [];
    num_frames_inside = 0;

    % Loop through the frames
    for frameIdx = 1:length(frame_numbers)
        if F_is_inside_roi(x(frameIdx), y(frameIdx), roi_x{roiIdx}, roi_y{roiIdx})
            num_frames_inside = num_frames_inside + 1;
        else
            % Body part left the ROI, record the frame and the number of frames inside
            if num_frames_inside > 0
                enter_frame = [enter_frame; frame_numbers(frameIdx - num_frames_inside), num_frames_inside];
                num_frames_inside = 0;
            end
        end
    end

    % Check if the body part is inside the ROI at the end of the video
    if num_frames_inside > 0
        enter_frame = [enter_frame; frame_numbers(end - num_frames_inside + 1), num_frames_inside];
    end

    % Store the results for the current ROI
    enter_frames{roiIdx} = enter_frame;
end

% Display the results for each ROI
for roiIdx = 1:numROIs
    if isempty(enter_frames{roiIdx})
        disp(append('Results for ROI ', names(roiIdx)));
        disp('The animal spends 0 frames inside ROI.');
    else
        disp(append('Results for ROI ', names(roiIdx)));
        disp('Frame number and number of frames inside ROI:');
        disp(enter_frames{roiIdx});
end
end
end