function [selected_body_parts] = F_SelectBodyParts(columnNames)
% Create a figure with checkboxes for each body part
fig = figure('Name', 'Select Body Parts', 'NumberTitle', 'off', 'Position', [100, 100, 300, 200]);

% Create checkboxes for each body part
checkboxHandles = zeros(1, numel(columnNames));
for i = 1:numel(columnNames)
    checkboxHandles(i) = uicontrol('Style', 'checkbox', 'String', columnNames{i}, 'Value', 0, 'Position', [20, 180 - 20 * i, 200, 20]);
end

% Add a "Proceed" button
proceedButton = uicontrol('Style', 'pushbutton', 'String', 'Proceed', 'Position', [20, 20, 100, 40], 'Callback', @proceedCallback);

% Wait for the "Proceed" button callback
uiwait(fig);

% Callback function for the "Proceed" button
    function proceedCallback(~, ~)
        % Get the selected body parts
        selected_body_parts = columnNames(logical(cell2mat(get(checkboxHandles, 'Value'))));

        % Display selected body parts
        disp('Selected Body Parts:');
        disp(selected_body_parts);

        % Close the figure
        close(fig);
    end

end