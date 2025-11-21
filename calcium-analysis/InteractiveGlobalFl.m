% Load the data
load('C:\Users\18jos\Desktop\FEAR MEMORY\paperLeire\DLC\SPT_ms\ms_M9_SPT.mat', 'ms');
%% 


% Calculate globalF
globalF = sum(ms.FiltTraces, 2);  % Use vectorized sum for efficiency

numFrames = size(globalF,1);  % Total number of frames
frameRate = 30;    % Frame rate of the video (fps)

videoFileName = 'C:\Users\18jos\Desktop\NeuronalTraceLucas.avi'; 
videoWriter = VideoWriter(videoFileName);
videoWriter.FrameRate = frameRate;
open(videoWriter);

% Create a figure for the plot
figure('Visible','off');
set(gcf, 'Color', 'w');  % Set background color of the figure to white
% Set figure to fullscreen
screenSize = get(0, 'ScreenSize');  % Get the screen size
set(gcf, 'Position', [1, 1, screenSize(3), screenSize(4)]);  % Set figure to fullscreen


% Customize the plot
xlabel('Time', 'FontSize', 12);  % x-axis label
ylabel('Mean Fluorescense', 'FontSize', 12);  % y-axis label
title('Representative Neuronal Trace', 'FontSize', 14, 'FontWeight', 'bold');  % Title
grid on;  % Add a grid
box on;   % Add a border around the plot
hold on;  % Keep adding to the plot without clearing it

% Initialize variables for incremental plotting
timeVector = ((0:numFrames-1) / frameRate);

% Plot handle for updating the plot data
plotHandle = plot(NaN, NaN, 'b-', 'LineWidth', 1.5);  % Initialize an empty plot


% Loop through each frame and update the plot
for i = 1:numFrames
    % Update the plot data for each frame
    set(plotHandle, 'XData', timeVector(1:i), 'YData', globalF(1:i));
    
    % Update the x-axis limits to show the progression of time
    if timeVector(i) > 1
        % Set initial xlim to avoid errors
        xlim([timeVector(i)-1, timeVector(i)+1]);  % Slightly extend the limit for first frame
    else
        % Update xlim dynamically based on the current timeVector(i)
        xlim([0, timeVector(i)+1]);  % Make sure the limits are valid and increasing
    end
    
    drawnow;

    writeVideo(videoWriter, getframe(gcf));
    % Pause to simulate 30 fps
    pause(1 / 30);  % Pause for 1/30 of a second to match video frame rate
end

hold off;
close(videoWriter);