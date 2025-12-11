clear all;
% Read the CSV file
[filename, pathname] = uigetfile('*.csv', 'Select the csv file for mapped frames');

if isequal(filename,0)
    disp('No file selected');
    return;
else
    fullpath = fullfile(pathname, filename);
    disp(['Selected file: ' fullpath]);
end
% Correct CSV loading
dataTable = readtable(fullpath);
animalName = string(input('Enter the new animal name (e.g. M1): ', 's'));

% Number of ROIs (assuming each ROI has two columns: _1 and _2)
numROIs = (width(dataTable) - 1) / 2; % -1 to exclude the NO_ROI column
% Variables to store frames and ROI durations
roi_frames = cell(numROIs, 1);
roi_durations = cell(numROIs, 1);
for i = 1:numROIs
    roi_frames{i} = dataTable{:, sprintf('ROI%d_1', i)};
    roi_durations{i} = dataTable{:, sprintf('ROI%d_2', i)};
end
no_roi_durations = dataTable{:, 'NO_ROI'};

%% Variables to store the sequences

sequence = {}; % Stores sequence
count_no_roi = 1;
current_frame = 1;

while current_frame <= max(cellfun(@(x) max(x, [], 'omitnan'), roi_frames), [], 'omitnan')
    max(cellfun(@(x) max(x, [], 'omitnan'), roi_frames), [], 'omitnan')
    % Find next closest frame
    current_frame
    % Find next closest frame
current_frame
next_frames = cellfun(@(x) min(x(x >= current_frame)), roi_frames, 'UniformOutput', false);
next_frames = [next_frames{:}];
next_frames = next_frames(~isnan(next_frames)) 
numColumns = size(dataTable, 2);
valid_indices = find(mod(1:numColumns, 2) == 1); 
valid_indices = valid_indices(valid_indices ~= numColumns); 

 % If there is only one next frame, determine which ROI it belongs to
    if length(next_frames) == 1

        frame_to_find = next_frames(1);
        roi_index = find(arrayfun(@(i) any(dataTable{:, valid_indices(i)} == frame_to_find), 1:length(valid_indices)), 1);
        next_frame = frame_to_find; % The next frame is already known

    else

        next_frame = min(next_frames, [], 'omitnan');
        roi_index = find(arrayfun(@(i) any(dataTable{:, valid_indices(i)} == next_frame), 1:length(valid_indices)), 1);
    
    end
% Check if there is a NO_ROI period before the next ROI frame
if isempty(next_frames) || current_frame < next_frame
    sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi);
    count_no_roi = count_no_roi + 1;
    if ~isempty(next_frames)
        current_frame = next_frame; 
    else
        break; % Get out of the loop if there are no more frames in ROI
    end
else
    % Add ROI to the sequence
    a="hola"
    roi_index;
    sequence{end+1} = sprintf('ROI%d_%d', roi_index, find(roi_frames{roi_index} == next_frame, 1));
    current_frame = next_frame + roi_durations{roi_index}(find(roi_frames{roi_index} == next_frame, 1));
end
end


%% Check and add the last NO_ROI period if needed
if count_no_roi <= height(dataTable)
    sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi);
end
%Assign sequence to Task.Titles
Task.Titles = sequence;
%% Read the CSV file

% Extract period titles from Task.Titles
period_titles = Task.Titles;

% Initialize Task.Lengths as a zero vector
Task.Lengths = zeros(1, numel(period_titles));
Task.Frames = zeros(1, numel(period_titles));
%% Loop through titles and look for the corresponding value in the CSV file

for i = 1:numel(period_titles)
    title = period_titles{i};
    
    if startsWith(title, 'NO_ROI')

        % This is a NO_ROI period, look in the "NO_ROI" column of the CSV
        Task.Lengths(i) = dataTable{str2double(extractAfter(title, 'NO_ROI_')), 'NO_ROI'};
    
    else

        % This is an ROI period, determine whether it is ROI1 or ROI2, etc.
        roi_type = extractBefore(title, '_');
        roi_index = str2double(extractAfter(title, '_'));
        % Look in the corresponding column of the CSV (ROIX_2)
        Task.Lengths(i) = dataTable{roi_index, sprintf('%s_2', roi_type)};

    end
end
Task.Frames=Task.Lengths;
Task.Lengths = num2cell(Task.Lengths);
% Convert numeric cells to cells of character strings
Task.Lengths = cellfun(@num2str, Task.Lengths, 'UniformOutput', false);
%% Initialize Task.Start and Task.End as cell arrays
Task.Start = cell(1, numel(Task.Lengths));
Task.End = cell(1, numel(Task.Lengths));

% Compute Task.Start
Task.Start{1} = 1; % The first Task.Start is always 1

for i = 2:numel(Task.Lengths)
    Task.Start{i} = Task.Start{i-1} + str2double(Task.Lengths{i-1});
end

% Compute Task.End
for i = 1:numel(Task.Lengths)
    Task.End{i} = Task.Start{i} + str2double(Task.Lengths{i}) - 1;
end

Task.FPS = 20;
%% Initialize Task.Pattern as a zero matrix

Task.Pattern = zeros(numel(Task.Titles), max(cellfun(@str2double, Task.Lengths)));

% Fill Task.Pattern with ones at the corresponding frames
current_frame = 1;
for i = 1:numel(Task.Titles)
    length = str2double(Task.Lengths{i});
    Task.Pattern(i, current_frame:current_frame + length - 1) = 1;
    current_frame = current_frame + length;
end

Task.Start = cell2mat(Task.Start);
Task.End = cell2mat(Task.End);
%% Save results

folderPath = uigetdir('', 'Select a folder');
test = string(regexp(filename, '.*_.*_(.*)\.csv', 'tokens'));
file_name = strcat('task_', animalName, '_', test, '.mat');

if folderPath == 0
    disp('No folder selected');
else
    disp(['Selected folder: ' folderPath]);
end

full_file_path = fullfile(folderPath, file_name);

% Save the Task variable to the .mat file
save(full_file_path, 'Task');

% Display a confirmation message
fprintf('The variable Task has been saved in: %s\n', full_file_path);
