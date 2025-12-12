% Open a file selection dialog to choose multiple video files
[files, inputPath] = uigetfile({'*.mp4;*.avi', 'Video Files (*.mp4, *.avi)'}, ...
                               'Select Video Files to Merge', ...
                               'MultiSelect', 'on');

% Check if the user selected any files
if isequal(files, 0)
    disp('No files selected.');
    return;
end

% If only one file is selected, `files` is a string. Convert to cell array.
if ischar(files)
    files = {files};
end

% Determine output format based on the extension of the first file
[~, ~, ext] = fileparts(files{1});
if strcmpi(ext, '.mp4')
    outputFormat = 'MPEG-4';
    tempOutputFile = 'temp_merged_video.mp4';
elseif strcmpi(ext, '.avi')
    outputFormat = 'Uncompressed AVI';
    tempOutputFile = 'temp_merged_video.avi';
else
    error('Unsupported video format. Please select only .mp4 or .avi files.');
end

% Create a temporary output file for the merged video
tempOutputPath = fullfile(inputPath, tempOutputFile);
outputVideo = VideoWriter(tempOutputPath, outputFormat);
outputVideo.FrameRate = 30; % Set frame rate (adjust as needed)

% Open the VideoWriter to start writing the merged video
open(outputVideo);

% Loop through each selected video file and add frames to the output video
for i = 1:length(files)
    % Construct full file path for the current video
    videoFile = fullfile(inputPath, files{i});
    
    % Create VideoReader object for the current video
    inputVideo = VideoReader(videoFile);
    
    % Read and write each frame of the current video
    while hasFrame(inputVideo)
        frame = readFrame(inputVideo);
        writeVideo(outputVideo, frame); % Write frame to the output video
    end
end

% Close the VideoWriter to finalize the merged video file
close(outputVideo);

% Prompt the user to select where to save the final output video and give it a name
[outputFileName, outputFolderPath] = uiputfile({'*.mp4', 'MPEG-4 Video (*.mp4)'; '*.avi', 'AVI Video (*.avi)'}, ...
                                               'Save Merged Video As', ...
                                               fullfile(inputPath, tempOutputFile));

% Check if the user selected a valid output path and filename
if isequal(outputFileName, 0) || isequal(outputFolderPath, 0)
    disp('No save location selected. Merged video saved temporarily.');
else
    % Move the temporary merged video file to the chosen location and name
    movefile(tempOutputPath, fullfile(outputFolderPath, outputFileName));
    disp(['Merged video saved as: ', fullfile(outputFolderPath, outputFileName)]);
end

% Clean up temporary file if it wasn't saved
if exist(tempOutputPath, 'file')
    delete(tempOutputPath);
end


