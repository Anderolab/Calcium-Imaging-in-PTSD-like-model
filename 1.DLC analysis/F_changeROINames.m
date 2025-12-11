function roiNames = F_changeROINames(existingNames)
    % Check if there are existing ROI names
    if isempty(existingNames)
        disp('No existing ROI names provided. Exiting.');
        roiNames = {};
        return;
    end

    % Create a GUI for changing ROI names
    fig = figure('Name', 'Change ROI Names', 'NumberTitle', 'off', 'Position', [100, 100, 400, 200]);

    % Create UI components
    promptText = uicontrol('Style', 'text', 'String', 'Do you want to change ROI names?', 'Position', [20, 200, 200, 20]);
    oldLabels = cell(numel(existingNames), 1);
    newEditBoxes = cell(numel(existingNames), 1);

    for i = 1:numel(existingNames)
        oldLabels{i} = uicontrol('Style', 'text', 'String', ['Old ROI ', num2str(i), ': ', existingNames{i}], 'Position', [20, 130 - 20 * i, 150, 20]);
        newEditBoxes{i} = uicontrol('Style', 'edit', 'Position', [180, 130 - 20 * i, 150, 20]);
    end

    okButton = uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [150, 20, 100, 40], 'Callback', @okButtonCallback);
    roiNamesText = uicontrol('Style', 'text', 'Position', [20, 50, 250, 50]);

    % Wait for the user to change ROI names
    uiwait(fig);

    % Callback function for the OK button
    function okButtonCallback(~, ~)
        % Retrieve new ROI names from the edit boxes
        roiNames = cell(numel(existingNames), 1);
        for j = 1:numel(existingNames)
            newName = get(newEditBoxes{j}, 'String');
            if isempty(newName)
                roiNames{j} = existingNames{j}; % Keep the old name if the user didn't enter a new one
            else
                roiNames{j} = newName;
            end
        end

        % Display new ROI names in the figure
        namesString = ['New ROI Names: ', strjoin(roiNames, ', ')];
        set(roiNamesText, 'String', namesString);

        % Close the GUI
        close(fig);
    end
end
