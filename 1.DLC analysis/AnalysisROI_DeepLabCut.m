%% 1. Allow the user to select the CSV or H5 file
[file, path] = uigetfile({'*.csv;*.h5', 'CSV or H5 Files (*.csv, *.h5)'}, 'Select DeepLabCut File');
if isequal(file, 0)
    disp('User canceled file selection. Exiting.');
    return;
end

% Construct the full file path
filename = fullfile(path, file);

% Check the file extension and load the data accordingly
[~, ~, ext] = fileparts(filename);
if strcmpi(ext, '.csv')
    data = readmatrix(filename); % Read CSV file
elseif strcmpi(ext, '.h5')

    % Prompt the user to enter the group and dataset names
    groupName = 'df_with_missing'; % Hardcode the group name
    datasetName = 'table'; % Hardcode the dataset name
    
    % Add a leading '/' to the dataset path
    datasetPath = ['/', groupName, '/', datasetName];
    % Read the data from the specified group and dataset
    dataStruct = h5read(filename, datasetPath);
    % Transpose values_block_0
    values_block_0 = dataStruct.values_block_0.';
    % Create a MATLAB table manually
    % Add the 'index' variable
    data = array2table([double(dataStruct.index), double(values_block_0)]);
    data = table2array(data)
else
    disp('Unsupported file format. Exiting.');
    return;
end

if strcmpi(ext, '.csv') 
    % Open the CSV file to extract the column names from the second header row
    fid = fopen(filename, 'r');
    % Read the first two header rows
    headerLine1 = fgetl(fid);
    headerLine2 = fgetl(fid);
    % Close the file
    fclose(fid);
    % Split the second header row into individual column names
    columnNames_full = strsplit(headerLine2, ',')
    columnNames = unique(columnNames_full)
    columnNames = columnNames(2:end)
    if columnNames{1} == 'bodyparts'
        columnNames = columnNames(2:end)
    end 
else 
    columnNames_full = {'bodyparts','miniscope', 'miniscope','miniscope', ... 
        'upper back','upper back','upper back', 'butt','butt','butt', 'tail end',...
        'tail end', 'tail end'}
    columnNames = {'miniscope', 'upper back', 'butt', 'tail end'}
end

%% 2. Allow the user to select the video file

[videoFile, videoPath] = uigetfile({'*.mp4;*.avi', 'Video Files (*.mp4, *.avi)'}, 'Select Video File');
if isequal(videoFile, 0)
    disp('User canceled video selection. Exiting.');
    return;
end

% Construct the full video file path
videoPath = fullfile(videoPath, videoFile);

% Load the video using VideoReader
videoObj = VideoReader(videoPath);

% Initialize frame indices
frameIndices = 1:videoObj.NumFrames;

%% Create a figure for selecting ROIs
fig = figure;

while true 
    % Randomly select a frame index
    randIdx = randi(length(frameIndices));
    frameIdx = frameIndices(randIdx);
    
    % Read and display the selected frame
    frame = read(videoObj, frameIdx);
    imshow(frame);
    title(['Select ROI(s) on Frame ', num2str(frameIdx)]);
    
    % Allow the user to change the frame
    changeFrame = questdlg('Do you want to change the frame?', 'Change Frame', 'Yes', 'No', 'No');
    if strcmp(changeFrame, 'Yes')
        continue; % Skip ROI selection and go to the next random frame
    else 
        break
    end
end

% Ask the user if they want to use existing ROIs or create new ones
roiChoice = questdlg('Do you want to use existing ROIs or create new ones?', 'ROI Selection', 'Use Existing', 'Create New', 'Create New');

if strcmp(roiChoice, 'Create New')
    % Allow user to specify the number of ROIs using a GUI
    numROIs = str2double(inputdlg('Enter the number of ROIs (1 to 4):', 'Number of ROIs', 1, {'1'}));
    
    if isempty(numROIs) || isnan(numROIs) || numROIs < 1 || numROIs > 4
        disp('Invalid number of ROIs. Exiting.');
        return;
    end

    while ~isempty(frameIndices)

        % Allow the user to draw 1-4 rectangles on the image
        roiPositions{randIdx} = cell(1, numROIs); 
        names = cell(1, numROIs);
        
        for i = 1:numROIs
            % Draw polygon ROI
            h = drawpolygon;
            wait(h);
            roiPositions{randIdx}{i} = h.Position;
        
            % Ask for the ROI name immediately after drawing it
            answer = inputdlg(['Enter name for ROI ', num2str(i), ':'], ...
                              'ROI Name', 1, {['ROI_', num2str(i)]});
            if isempty(answer)
                names{i} = ['ROI_', num2str(i)];
            else
                names{i} = answer{1};
            end
        
            delete(h); % remove interactive object
        end


        % Remove the selected frame index from the list
        frameIndices(randIdx) = [];
        
        % Ask the user if they want to continue selecting ROI(s) on another random frame
        if isempty(frameIndices)
            break; % Exit the loop if all frames have been processed
        else
            % Ask if the user wants to save the ROIs
            saveROIsChoice = questdlg('Do you want to save the selected ROIs?', 'Save ROIs', 'Yes', 'No', 'No');
            if strcmp(saveROIsChoice, 'Yes')
                % Allow the user to choose the folder and name of the ROI file
                [roiFileName, roiFilePath] = uiputfile('*.mat', 'Save ROIs', 'ROIs.mat');
                if isequal(roiFileName, 0) || isequal(roiFilePath, 0)
                    disp('User canceled ROI saving. Continuing without saving.');
                    close(fig);
                    break
                else
                    % Save the ROI positions to the selected file
                    save(fullfile(roiFilePath, roiFileName), 'roiPositions', "randIdx", "numROIs", "names");
                    disp(['ROIs saved successfully to ', fullfile(roiFilePath, roiFileName)]);
                    close(fig);
                    break
                end
            else
                disp('ROIs not saved.');
                close(fig);
                break
            end
        end
    end
else 
    % Allow the user to select the existing ROI file
    [roiFile, roiPath] = uigetfile({'*.mat', 'MAT Files (*.mat)'}, 'Select ROI File');
    if isequal(roiFile, 0)
        disp('User canceled ROI selection. Exiting.');
        return;
    end

    % Load the existing ROI file
    load(fullfile(roiPath, roiFile), 'roiPositions', "randIdx", "numROIs", "names");
    disp(['Existing ROIs loaded from ', fullfile(roiPath, roiFile)]);
    
    if numROIs == 1
        hold on 
        h = impoly(gca, roiPositions{randIdx}{numROIs});
        wait(h)
        roiPositions{randIdx} = {getPosition(h)};
        delete(h);
        hold off;
    elseif numROIs == 2
        hold on 
        h = impoly(gca, roiPositions{randIdx}{numROIs});
        h2 = impoly(gca, roiPositions{randIdx}{numROIs-1});
        wait(h)
        wait(h2)
        roiPositions{randIdx} = {getPosition(h), getPosition(h2)};
        delete(h);
        delete(h2);
        hold off;
    elseif numROIs == 3
        hold on 
        h = impoly(gca, roiPositions{randIdx}{numROIs});
        h2 = impoly(gca, roiPositions{randIdx}{numROIs-1});
        h3 = impoly(gca, roiPositions{randIdx}{numROIs-2});
        wait(h)
        wait(h2);
        wait(h3);
        roiPositions{randIdx} = {getPosition(h), getPosition(h2), getPosition(h3)};
        delete(h);
        delete(h2);
        delete(h3);
        hold off;
    else
        hold on 
        h = impoly(gca, roiPositions{randIdx}{numROIs});
        h2 = impoly(gca, roiPositions{randIdx}{numROIs-1});
        h3 = impoly(gca, roiPositions{randIdx}{numROIs-2});
        h4 = impoly(gca, roiPositions{randIdx}{numROIs-3});
        wait(h)
        wait(h2);
        wait(h3);
        wait(h4);
        roiPositions{randIdx} = {getPosition(h), getPosition(h2), getPosition(h3), getPosition(h4)};
        delete(h);
        delete(h2);
        delete(h3);
        delete(h4);
        hold off;
    end
    % Ask if they want to change the names 
    saveROIsChoice = questdlg('Do you want to change the ROIs names', 'Change ROIs names', 'Yes', 'No', 'No');
    if strcmp(saveROIsChoice, 'Yes')
        names = F_changeROINames(names);
        hold off
    else 
        disp('ROIs names are the same');
        hold off 
    end
end 

%% 3. Detect when the body part enters the selected ROI(s)

%Create array with all positions 
position = {};
if numROIs == 1
    position{1} = roiPositions{randIdx}{1};
elseif numROIs == 2
    position{1} = roiPositions{randIdx}{1};
    position{2} = roiPositions{randIdx}{2};
elseif numROIs == 3
    position{1} = roiPositions{randIdx}{1};
    position{2} = roiPositions{randIdx}{2};
    position{3} = roiPositions{randIdx}{3};
elseif numROIs == 4
    position{1} = roiPositions{randIdx}{1};
    position{2} = roiPositions{randIdx}{2};
    position{3} = roiPositions{randIdx}{3};
    position{4} = roiPositions{randIdx}{4};
end  

% Choose the body parts to analyse 
% Create a GUI to allow the user to select body parts
selected_body_parts = F_SelectBodyParts(columnNames);

% Initialize an empty cell to store the indices
indices = cell(1, length(selected_body_parts));

% Loop through each element in columnNames
for i = 1:length(selected_body_parts)
    % Find the indices in columnNames_full that match the current element in columnNames
    indices{i} = find(ismember(columnNames_full, selected_body_parts{i}));
end

% Calculate frames in ROIs for each body part
enter_frames = {};
for i = 1:length(selected_body_parts)
    enter_frames{i} = F_BodyPartInROI(data, indices{i}(1),  indices{i}(2), numROIs, position, names);
end 

%% 4. Confront the various body parts, keeping only frames present for all body parts 

% Initialize final_frames with y cells
final_frames = cell(1, numROIs);
RejectedFrames_Indices = cell(1, numROIs);

% Loop through each ROI
for roi = 1:numROIs
    % Initialize a timeline for this ROI, all zeros (no bodypart present initially)
    timeline = zeros(videoObj.NumFrames, length(enter_frames));

    % Loop through each bodypart
    for bp = 1:length(enter_frames)
        % Check if roi is within valid bounds for this body part
        if roi <= numel(enter_frames{bp})
            % For each entry, mark the presence in the timeline
            for entry = 1:size(enter_frames{bp}{roi}, 1)
                startFrame = enter_frames{bp}{roi}(entry, 1) + 1;
                duration = enter_frames{bp}{roi}(entry, 2);
                timeline(startFrame:(startFrame + duration - 1), bp) = 1;
            end
        else
            disp(['Skipping ROI ', num2str(roi), ' for body part ', num2str(bp), ' as it exceeds array bounds.']);
        end
    end

    % Find frames where all bodyparts are present
    allPresent = all(timeline, 2);

    % Find frames where all bodyparts are present
    anyPresent = any(timeline, 2);

    % Find frames where at least 1 but not all body parts are present
    atLeastOneNotAll = anyPresent & ~allPresent;

    % Find indices where allPresent is true
    RejectedFrames_Indices{roi} = find(atLeastOneNotAll);

    % Find indices where atLeastOneNotAll is true
    AcceptedFrames_Indices{roi} = find(allPresent);

    % Find continuous intervals where all bodyparts are present
    starts = find(diff([0; allPresent]) == 1);
    ends = find(diff([allPresent; 0]) == -1);

    % Store entry frame and duration for each interval
    intervals = [starts, ends - starts + 1];

    % Store the intervals in final_frames
    final_frames{roi} = intervals;
end

%%  EXTRA Show discarted frames to user to double check False Negatives

FinalFramesUpdated = final_frames
Number_Rejected_Frames = 0;
for roi = 1:numROIs
    number_frames_roi = length(RejectedFrames_Indices{roi});
    Number_Rejected_Frames = Number_Rejected_Frames + number_frames_roi;
end

Question = strcat('You have ', " ", string(Number_Rejected_Frames),' discarted frames. Do you want to check the them?')
frameInspection = questdlg(Question, 'Frames Inspection', 'No', 'Yes', 'Yes');

currentIndex = 1

if strcmp(frameInspection, 'Yes')
    Frames_Kept = cell(1, numROIs); % Initialize the cell array

    for roi = 1:numROIs
        Frames_Kept{roi} = F_CheckFrames(currentIndex, RejectedFrames_Indices{roi}, videoObj, roiPositions, randIdx, numROIs, 'Keep', names{roi});
        
        %Wait for the user to complete inspection before moving to the next ROI
        waitfor(Frames_Kept{roi}.fig);
    end
end

%% EXTRA Show Included frames to user to double check False Positives 

Number_Included_Frames = 0;
for roi = 1:numROIs
    number_frames_roi = length(AcceptedFrames_Indices{roi});
    Number_Included_Frames = Number_Included_Frames + number_frames_roi;
end

Question = strcat('You have ', " ", string(Number_Included_Frames),' included frames. Do you want to check the them?')
frameInspection = questdlg(Question, 'Frames Inspection', 'No', 'Yes', 'Yes');

currentIndex = 1

if strcmp(frameInspection, 'Yes')
    Frames_Rejected = cell(1, numROIs); % Initialize the cell array

    for roi = 1:numROIs
        Frames_Rejected{roi} = F_CheckFrames(currentIndex, AcceptedFrames_Indices{roi}, videoObj, roiPositions, randIdx, numROIs, 'Reject', names{roi});

        % Wait for the user to complete inspection before moving to the next ROI
        waitfor(Frames_Rejected{roi}.fig);
    end
end

%% EXTRA Remove Rejected Frames from Final Frame array

% FinalFramesUpdated = final_frames; 
if exist('Frames_Rejected', 'var') == 1
    for roi = 1:numROIs
        FramesToRemove = Frames_Rejected{roi}.FramesToKeep;
        if ~isempty(FramesToRemove)
            % Sort FramesToRemove to ensure the frames are in ascending order
            FramesToRemove = sort(FramesToRemove);

            % Initialize variables to track the first frame and duration
            firstFrame = FramesToRemove(1);
            duration = 1;

            % Iterate through FramesToRemove starting from the second frame
            for i = 2:length(FramesToRemove)
                frameIndex = FramesToRemove(i);

                if frameIndex - FramesToRemove(i-1) == 1
                    % If consecutive, update the duration
                    duration = duration + 1;
                else
                    % If not consecutive, remove the frames
                    framesToRemove = (firstFrame):(firstFrame + duration - 1);
                    FinalFramesUpdated{roi} = F_removeFrames(FinalFramesUpdated{roi}, framesToRemove);

                    % Update firstFrame and reset duration for the new entry
                    firstFrame = frameIndex;
                    duration = 1;
                end
            end

            % Remove the last entry after the loop
            framesToRemove = (firstFrame):(firstFrame + duration - 1);
            FinalFramesUpdated{roi} = F_removeFrames(FinalFramesUpdated{roi}, framesToRemove);
        else
            continue
        end
    end
end

%% EXTRA Integrate Kept Frames in Final Frame array

if exist('Frames_Kept', 'var') == 1
    for roi = 1:numROIs
        FramesToKeep = Frames_Kept{roi}.FramesToKeep;
        if ~isempty(FramesToKeep) 
            % Sort FramesToKeep to ensure the frames are in ascending order
            FramesToKeep = sort(FramesToKeep);

            % Initialize variables to track the first frame and duration
            firstFrame = FramesToKeep(1);
            duration = 1;

            % Iterate through FramesToKeep starting from the second frame
            for i = 2:length(FramesToKeep)
                frameIndex = FramesToKeep(i);

                if frameIndex - FramesToKeep(i-1) == 1
                    % If consecutive, update the duration
                    duration = duration + 1;
                else
                    % If not consecutive, add a new entry
                    newRow = [firstFrame, duration];
                    FinalFramesUpdated{roi} = [FinalFramesUpdated{roi}; newRow];

                    % Update firstFrame and reset duration for the new entry
                    firstFrame = frameIndex;
                    duration = 1;
                end
            end

            % Add the last entry after the loop
            newRow = [firstFrame, duration];
            FinalFramesUpdated{roi} = [FinalFramesUpdated{roi}; newRow];
        else
            continue 
        end
    end
end 


%% EXTRA Fix FinalFramesUpdated Structure

for roi = 1:numROIs
    % Sort the data based on the first column
    sortedData = sortrows(FinalFramesUpdated{roi}, 1);

    % Initialize variables to store the result
    result = sortedData(1, :);

    % Loop through the sorted data
    for i = 2:size(sortedData, 1)
        % Check if the current interval overlaps or is consecutive with the previous one
        if sortedData(i, 1) <= (result(end, 1) + result(end, 2)) + 1
            % Update the second column
            result(end, 2) = max(sortedData(i, 1) + sortedData(i, 2) - result(end, 1), result(end, 2));
        else
            % If not overlapping or consecutive, start a new interval
            result = [result; sortedData(i, :)];
        end
    end 

    FinalFramesUpdated{roi} = result;
end 

%% 6. Analyse Time Spent on ROIs

PercentageResults = cell(1, numROIs);

% Percentage of Frames spent in each ROIs
for roi = 1:numROIs
    FramesOnROI = sum(FinalFramesUpdated{roi}(:,2));
    PercentageOfROIFrames = FramesOnROI / videoObj.NumFrames * 100;
    PercentageResults{roi} = PercentageOfROIFrames
end

%% 7. Create Final csv file 

% Create a GUI dialog for user input
prompt = {'Enter the animal number:', 'Enter the session name:'};
dlgTitle = 'User Input';
numLines = 1;
defaultValues = {'', ''};  % Default values for each input field

userInput = inputdlg(prompt, dlgTitle, numLines, defaultValues);

% Extract values from the user input
animalNumber = char(userInput{1});
sessionName = char(userInput{2});

for roi = 1:numROIs
    % Create Tables with results
    FinalTable = table();
    FinalTable.FirstFrameROI = FinalFramesUpdated{roi}(:,1);
    FinalTable.TotalFramesROI = FinalFramesUpdated{roi}(:,2);

    nameROi = strrep(names{roi}, ' ', '');

    % Construct the filename
    csv_file_name = sprintf('%s_%s_%s.csv', animalNumber, sessionName, nameROi);

    % Allow the user to choose the folder and name of the ROI file
    [roiFileName, roiFilePath] = uiputfile('*.csv', 'Save ROIs', csv_file_name);
    writetable(FinalTable, fullfile(roiFilePath, roiFileName));
end
