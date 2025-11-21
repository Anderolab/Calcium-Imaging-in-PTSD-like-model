%% Code for Tunning Results Processing 

%% Load all the files 
x = 4;  % Number of original files to load
loadedData = cell(1, x);    % Cell array to store loaded data
filePaths = cell(1, x);     % Store file paths for reference

% Load files
for i = 1:x
    [fileName, filePath] = uigetfile('*.mat', sprintf('Select file for Tunning results', i, x));
    
    if isequal(fileName, 0)
        error('File selection cancelled. Exiting...');
    end

    fullPath = fullfile(filePath, fileName);
    filePaths{i} = fullPath;
    loadedData{i} = load(fullPath);
    
    disp(['Loaded file ' num2str(i) ': ' fullPath]);
end

%% Ask user for test and ROI names
testName = input('Enter the test name: ', 's');
roiName = input('Enter the ROI name: ', 's');

%% Ask user where to save the new files
outputDir = uigetdir('', 'Select Output Folder');
if outputDir == 0
    error('No folder selected. Exiting...');
end

%% Ask user list of animal numbers

animalNumbers = input('Enter the animal numbers (separated by spaces): ', 's');
animalNumbers = str2num(animalNumbers)

%% Process each file
for i = 1:x
    % Extract data from the loaded file
    data = loadedData{i};  % Modify if you need to save specific variables

    % Assuming the loaded data contains a table
    fieldNames = fieldnames(data);
    tableData = data.(fieldNames{1});  % Access the first table (modify if you have specific structure)

    % Split the table based on the second column's unique values
    secondColumn = tableData{:, 2};  % Assuming the second column holds the category for splitting
    uniqueValues = unique(secondColumn);
    
    % Split table into smaller tables based on the second column
    splitTables = cell(1, numel(uniqueValues));
    
    for j = 1:numel(uniqueValues)
        splitTables{j} = tableData(secondColumn == uniqueValues(j), :);
    end
    
    % Save each split table with the new name in the chosen folder
    for j = 1:numel(splitTables)
        splitTable = splitTables{j};

        % Create the file name based on the format: M<number>_<Test>_<ROI>.mat
        fileName = sprintf('M%d_%s_%s.mat', animalNumbers(1), testName, roiName); 
        animalNumbers = animalNumbers(2:end);

        % Save the split table with the new name
        save(fullfile(outputDir, fileName), 'splitTable');
        
        disp(['Saved split table as: ' fullfile(outputDir, fileName)]);
    end
end

disp('All files have been processed and saved.');
