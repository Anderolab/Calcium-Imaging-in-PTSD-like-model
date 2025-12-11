function [data] = F_CheckFrames(currentIndex, frameIndices, videoObj, roiPositions, randIdx, numROIs, variable, nameROI)
    % Array of Frames to Keep
    FramesToKeep = [];

   % Create a figure for selecting ROIs
    fig = figure;

    % Create axes to display frames
    ax = axes(fig, 'Position', [0.1, 0.1, 0.8, 0.8]);

    % Display the first frame initially
    currentFrame = read(videoObj, frameIndices(1));
    imshow(currentFrame, 'Parent', ax);
    title(ax, ['Frame number ', num2str(frameIndices(1)), ' for ROI called ', num2str(numROIs)]);
    
    % Create "Keep Frame" button
    keepButton = uicontrol(fig, 'Style', 'pushbutton', 'String', variable, 'Position', [150, 20, 100, 40], 'Callback', @KeepButtonCallback);

    % Create "Next Frame" button
    nextButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Next', 'Position', [320, 20, 100, 40], 'Callback', @NextButtonCallback);

    % Set up timer
    t = timer('ExecutionMode', 'fixedRate', 'Period', 0.1, 'TimerFcn', @updateDisplay, 'StopFcn', @timerStop);

    % Save data to guidata
    guidata(fig, struct('currentIndex', currentIndex, 'FramesToKeep', FramesToKeep, 'ax', ax, 'frameIndices', frameIndices, 'fig', fig, 'randIdx', randIdx, 'numROIs', numROIs));

    % Start the timer
    start(t);

    % Wait for the user to close the figure
    waitfor(fig);

    % Callback function for updating display
    function updateDisplay(~, ~)
        % Retrieve data from guidata
        data = guidata(fig);

        % Check if currentIndex is within bounds
        if data.currentIndex <= numel(data.frameIndices)
            % Read the frame from the video
            currentFrame = read(videoObj, data.frameIndices(data.currentIndex));

            % Display the frame in the axes
            imshow(currentFrame, 'Parent', data.ax);
            if data.numROIs == 1
                impoly(gca, roiPositions{data.randIdx}{data.numROIs});
            elseif data.numROIs == 2
                impoly(gca, roiPositions{data.randIdx}{data.numROIs});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-1});
            elseif data.numROIs == 3
                impoly(gca, roiPositions{data.randIdx}{data.numROIs});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-1});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-2});
            else
                impoly(gca, roiPositions{data.randIdx}{data.numROIs});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-1});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-2});
                impoly(gca, roiPositions{data.randIdx}{data.numROIs-3});
            end
    
            title(data.ax, ['Frame number ', num2str(data.frameIndices(data.currentIndex)), ' for ROI called ', nameROI]);
        else
            % If all frames are checked, stop the timer
            stop(t);
        end

        % Save data to guidata
        guidata(fig, data);
    end

    % Callback function for the "Keep" button
    function KeepButtonCallback(~, ~)
        % Retrieve data from guidata
        data = guidata(fig);

        % Display frame
        if data.currentIndex <= numel(data.frameIndices)
            data.FramesToKeep = [data.FramesToKeep, data.frameIndices(data.currentIndex)];
            display(data.FramesToKeep)
        end

        % Increment the index
        data.currentIndex = data.currentIndex + 1;

        % Save data to guidata
        guidata(fig, data);
    end

    % Callback function for the "Next" button
    function NextButtonCallback(~, ~)
        % Retrieve data from guidata
        data = guidata(fig);

        % Increment the index
        data.currentIndex = data.currentIndex + 1;

        % Save data to guidata
        guidata(fig, data);
    end

    % Callback function for when the timer stops
    function timerStop(~, ~)
        % Retrieve data from guidata
        data = guidata(fig);
    
        % Close the figure when the timer stops
        close(fig);
    end
end

