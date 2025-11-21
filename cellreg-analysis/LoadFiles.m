function [loadedDataTun ning_test1,filePathsTunning_test1] = LoadFiles(testName1, x, files)

    % Allow the selection of multiple files at once
    [fileNames, filePath] = uigetfile('*.mat', sprintf('Select files for %s results for test %s', files, testName1), 'MultiSelect', 'on');
    
    if isequal(fileNames, 0)
        error('File selection cancelled. Exiting...');
    end
    
    % If only one file is selected, fileNames will not be a cell array
    if ischar(fileNames)
        fileNames = {fileNames}; % Convert to a cell array for consistency
    end
    
    
    loadedDataTunning_test1 = cell(1, x);    % Cell array to store loaded data
    filePathsTunning_test1 = cell(1, x);     % Store file paths for reference
    
    % Loop through the selected files
    for j = 1:length(fileNames)
        fullPath = fullfile(filePath, fileNames{j});
        filePathsTunning_test1{j} = fullPath;  % Store file path
        loadedDataTunning_test1{j} = load(fullPath);  % Store loaded data
    
    end

end