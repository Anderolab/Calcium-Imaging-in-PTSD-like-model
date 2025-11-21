% Set the file path and name of the input video
inputFilePath = 'G:\Ex3_BLA\Miniscope Recordings\IMO\EARLY IMO\MALES\5C\2024_05_20\11_24_43\BehavCam_0\0.avi'; % Replace with your file path
outputFilePath = 'G:\Ex3_BLA\Miniscope Recordings\IMO\EARLY IMO\MALES\5C\2024_05_20\11_24_43\BehavCam_0\0_new.avi'; % Replace with desired output path

% Create a VideoReader object for the input video
inputVideo = VideoReader(inputFilePath);

% Create a VideoWriter object for the output video in AVI format
outputVideo = VideoWriter(outputFilePath, 'Uncompressed AVI');
outputVideo.FrameRate = inputVideo.FrameRate; % Keep the same frame rate

% Set desired output dimensions
outputWidth = 336;
outputHeight = 254;

% Open the VideoWriter to begin writing the resized video
open(outputVideo);

% Loop through each frame of the input video
while hasFrame(inputVideo)
    frame = readFrame(inputVideo); % Read the next frame
    
    % Resize the frame to the target resolution
    resizedFrame = imresize(frame, [outputHeight, outputWidth]);
    
    % Write the resized frame to the output video
    writeVideo(outputVideo, resizedFrame);
end

% Close the VideoWriter to save the video
close(outputVideo);

disp('AVI video resizing complete!');

