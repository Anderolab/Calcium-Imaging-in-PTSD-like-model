% Ask the user to indicate the number of ROIs
numROIs = input('Introduce the number ROIs: ');

% Initialize the matrices to store the input data
entradas = cell(numROIs, 1);
duraciones = cell(numROIs, 1);

% Ask the user to select the CSV files for each ROI
for i = 1:numROIs
    [file, path] = uigetfile('*.csv', sprintf('Select the csv file of ROI %d', i));
    indicesGuionBajo = strfind(file, '_');

    % Extract the part of the name up to the second underscore
    nombreExtraido = file(1:indicesGuionBajo(2)-1);
   
    if isequal(file, 0)
        disp('The user deleted the file selection');
        return;
    else
        fullPath = fullfile(path, file);
        tempTable = readtable(fullPath, 'ReadVariableNames', true, 'Range', 1);  % Read from the second row
        entradas{i} = tempTable{:, 1};  % Accessing the first column directly
        duraciones{i} = tempTable{:, 2};  % Accessing the second column directly
    end
end


%% Ask the user to select the text file with the timestamps
[file, path] = uigetfile('*.dat', 'Select the timestamp file');
if isequal(file, 0)
    disp('The user deleted the file selection');
    return;
else
    timestampPath = fullfile(path, file);
    timestampTable = readtable(timestampPath);
end

% Determine the maximum number of rows among all CSV files
maxRows = max(cellfun(@(c) size(c, 1), entradas));

% Create a table for the results with the maximum number of rows
resultados = table();

AnimalNewName = input('Choose new animal name: ','s');
Trial = input('Trial name: ','s');

%% Process each ROI
for j = 1:numROIs
    resultadosTemp = array2table(nan(maxRows, 2));  % Create a temporary table with NaN
    for i = 1:size(entradas{j}, 1)
        % Get the entry and exit frames for the current ROI
        frame_entrada = entradas{j}(i);
        frame_salida = frame_entrada + duraciones{j}(i) - 1;
        
        % Find the timestamps from the behavior camera
        timestamps_entrada = timestampTable{timestampTable.camNum == 0 & timestampTable.frameNum == frame_entrada, 'sysClock'};
        timestamps_salida = timestampTable{timestampTable.camNum == 0 & timestampTable.frameNum == frame_salida, 'sysClock'};

        % Search all frames from the trace camera matching the timestamps
        indices_entrada = find(abs(timestampTable.sysClock(timestampTable.camNum == 1) - timestamps_entrada) <= 80);
        indices_salida = find(abs(timestampTable.sysClock(timestampTable.camNum == 1) - timestamps_salida) <= 80);

        % Get the system times for the found indices
        sysClocks_entrada = timestampTable.sysClock(timestampTable.camNum == 1); % Always the calcium camera number
        sysClocks_salida = timestampTable.sysClock(timestampTable.camNum == 1); % Always the calcium camera number
       
        % Find the index with the smallest difference
        if ~isempty(indices_entrada)
            if frame_entrada==1
                frame_traza_entrada = indices_entrada(1)
            else
            [~, min_idx_entrada] = min(abs(sysClocks_entrada(indices_entrada) - timestamps_entrada));
            frame_traza_entrada = indices_entrada(min_idx_entrada);
            end
        else
            frame_traza_entrada = NaN;
        end

        if j == 3 && i == 1
        disp(['Entry frame: ', num2str(frame_entrada)]);
        disp(['Exit frame: ', num2str(frame_salida)]);
        disp(['Entry Timestamp: ', num2str(timestamps_entrada)]);
        disp(['Exit Timestamp: ', num2str(timestamps_salida)]);
        disp(['Entry index: ', mat2str(indices_entrada)]);
        disp(['Exit index: ', mat2str(indices_salida)]);
        disp(['Entry SysClocks: ', mat2str(sysClocks_entrada(indices_entrada))]);
        disp(['Exit SysClocks: ', mat2str(sysClocks_salida(indices_salida))]);
        disp(frame_traza_entrada)
        end
        if ~isempty(indices_salida)
            [~, min_idx_salida] = min(abs(sysClocks_salida(indices_salida) - timestamps_salida));
            frame_traza_salida = indices_salida(min_idx_salida);
        else
            frame_traza_salida = NaN;
        end
        
        % Add the results to the temporary table
        resultadosTemp{i, 1} = frame_traza_entrada;
        if isnan(frame_traza_entrada) || isnan(frame_traza_salida)
            resultadosTemp{i, 2} = NaN;
        else
            resultadosTemp{i, 2} = frame_traza_salida - frame_traza_entrada + 1;
        end
    end
    % Assign names to the columns of the temporary table
    resultadosTemp.Properties.VariableNames = {['ROI', num2str(j), '_1'], ['ROI', num2str(j), '_2']};
    
    % Add the temporary results table to the final results table
    resultados = [resultados, resultadosTemp];
end

% Remove the rows with NaN at the end of the table if necessary
% Find the number of valid rows for each set of ROI columns
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
% Find the maximum number of valid rows among all ROI column sets
maxValidRows = max(numValidRows);
% Trim the results table to only have the maximum number of valid rows
resultados = resultados(1:maxValidRows, :);



% Remove rows with NaN at the end of the table if necessary
% Find the number of valid rows for each set of ROI columns
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
% Find the maximum number of valid rows among all ROI column sets
maxValidRows = max(numValidRows);
% Trim the results table to only have the maximum number of valid rows
resultados = resultados(1:maxValidRows, :);

% Initialize the NO_ROI list
NO_ROI = [];

% Combine and sort the entry frames from all ROIs
allEntries = [];
for j = 1:numROIs
    allEntries = [allEntries; resultados{:, ['ROI', num2str(j), '_1']}];
end
allEntries = allEntries(~isnan(allEntries)); % Remove NaN
allEntries = sort(allEntries); % Sort ascending

% Check if the first entry frame is greater than 0
if min(allEntries)>0    
    if ~(min(allEntries) == 1)
        NO_ROI(1) = min(allEntries)-1;
    end
end

%% Calculate the frames outside the ROIs

for i = 1:length(allEntries) - 1
    % Find the exit frame associated with the current entry
    exitFrame = NaN;
    for j = 1:numROIs
        if any(resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i))
            duracion = resultados{resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i), ['ROI', num2str(j), '_2']};
            exitFrame = allEntries(i) + duracion;
            % disp(duracion);
            % disp(exitFrame);
            break;
        end
    end
    if isnan(exitFrame)
        exitFrame = allEntries(i); % Just in case the entry is not found in the columns
    end

    % Calculate the frames outside the ROI before the next entry
    noROIFrames = allEntries(i + 1) - exitFrame
    % Add to the list
    if noROIFrames < 0
        noROIFrames = 0;
    end
    if ~(noROIFrames==0)
        NO_ROI(end + 1) = noROIFrames;
    end
end

%% Find the last recorded frame for the trace camera

maxFrameCam0 = max(timestampTable.frameNum(timestampTable.camNum == 1));

% Find the duration corresponding to the last value in allEntries
if any(resultados.ROI1_1 == allEntries(end))
    lastDuration = resultados.ROI1_2(resultados.ROI1_1 == allEntries(end));
elseif any(resultados.ROI2_1 == allEntries(end))
    lastDuration = resultados.ROI2_2(resultados.ROI2_1 == allEntries(end));
elseif any(resultados.ROI3_1 == allEntries(end))
    lastDuration = resultados.ROI2_2(resultados.ROI3_1 == allEntries(end));
elseif any(resultados.ROI4_1 == allEntries(end))
    lastDuration = resultados.ROI2_2(resultados.ROI4_1 == allEntries(end));
else
    lastDuration = 0; % Just in case the entry is not found in the columns
end

% Compute the final exit frame
finalExitFrame = allEntries(end) + lastDuration;

% Compute the last value for NO_ROI
NO_ROI(end + 1) = maxFrameCam0 - finalExitFrame;
if NO_ROI(end) < 0
    NO_ROI(end) = [];
end

% Convert NO_ROI into a table
NO_ROITable = table(NO_ROI', 'VariableNames', {'NO_ROI'});

% Check which table is longer and pad the shorter one with NaN
if height(NO_ROITable) > height(resultados)
    % If NO_ROI is longer, extend 'resultados' with NaN
    additionalRows = array2table(nan(height(NO_ROITable) - height(resultados), width(resultados)), 'VariableNames', resultados.Properties.VariableNames);
    resultados = [resultados; additionalRows];
elseif height(NO_ROITable) < height(resultados)
    % If 'resultados' is longer, extend NO_ROI with NaN
    additionalRows = array2table(nan(height(resultados) - height(NO_ROITable), 1), 'VariableNames', {'NO_ROI'});
    NO_ROITable = [NO_ROITable; additionalRows];
end

% Join the NO_ROI table with 'resultados'
resultados = [resultados, NO_ROITable];

%% Save File

% Ask the user to select a folder
folderPath = uigetdir(pwd, 'Select a folder');

% Check if the user pressed "Cancel"
if folderPath == 0
    disp('No folder selected.');
    return;
end

nombreArchivoResultados = [folderPath, '\resultados_', AnimalNewName, '_', Trial, '.csv'];

% Write the final table to a new CSV file
writetable(resultados, nombreArchivoResultados);
