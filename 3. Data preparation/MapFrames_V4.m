clear all;
% Ask the user to input the number of ROIs
numROIs = input('Enter the number of ROIs: ');

% Initialize the matrices to store input data
entradas = cell(numROIs, 1);
duraciones = cell(numROIs, 1);

% Ask the user to select the CSV files for each ROI
for i = 1:numROIs
    [file, path] = uigetfile('*.csv', sprintf('Select the CSV file for ROI %d', i));
    indicesGuionBajo = strfind(file, '_');

    % Extract the name portion up to the second underscore
    nombreExtraido = file(1:indicesGuionBajo(2)-1);
    
    if isequal(file, 0)
        disp('User canceled file selection.');
        return;
    else
        fullPath = fullfile(path, file);
        tempTable = readtable(fullPath, 'ReadVariableNames', true, 'Range', 1);
        entradas{i} = tempTable{:, 1};  
        duraciones{i} = tempTable{:, 2}; 
    end
end

% Ask the user to select the timestamp files for the cameras
[calciumFile, calciumPath] = uigetfile('*.csv', 'Select the timestamp file for the calcium camera');
if isequal(calciumFile, 0)
    disp('User canceled file selection.');
    return;
else
    calciumTimestampPath = fullfile(calciumPath, calciumFile);
    calciumTimestampTable = readtable(calciumTimestampPath);
end

[behaviorFile, behaviorPath] = uigetfile('*.csv', 'Select the timestamp file for the behavior camera');
if isequal(behaviorFile, 0)
    disp('User canceled file selection.');
    return;
else
    behaviorTimestampPath = fullfile(behaviorPath, behaviorFile);
    behaviorTimestampTable = readtable(behaviorTimestampPath);
end

% Determine the maximum number of rows across all CSV files
maxRows = max(cellfun(@(c) size(c, 1), entradas));

% Create a results table with the maximum number of rows
resultados = table();

% Process each ROI
for j = 1:numROIs
    resultadosTemp = array2table(nan(maxRows, 2));  
    for i = 1:size(entradas{j}, 1)

        % Get entry and exit frames for the current ROI
        if entradas{j}(i)>max(behaviorTimestampTable{:,1})
            break
        end
        frame_entrada = entradas{j}(i);
        frame_salida = frame_entrada + duraciones{j}(i) - 1;
        
        % Find behavior camera timestamps
        timestamps_entrada = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_entrada, 2};
        disp(frame_entrada)
        disp("---")
        disp(frame_salida)

        % If exit frame does not exist, use the closest one
        if any(behaviorTimestampTable{:, 1} == frame_salida)
            timestamps_salida = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_salida, 2};
        else
            frame_salida = max(behaviorTimestampTable{:, 1});
            timestamps_salida = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_salida, 2};
        end

        % Debug display
        disp(['Entry frame: ', num2str(frame_entrada)]);
        disp(['Exit frame: ', num2str(frame_salida)]);
        disp(['Entry timestamp: ', num2str(timestamps_entrada)]);
        disp(['Exit timestamp: ', num2str(timestamps_salida)]);
        disp(['SysClock size (entry): ', num2str(size(calciumTimestampTable{:, 2}))]);
        disp(['SysClock size (exit): ', num2str(size(calciumTimestampTable{:, 2}))]);
        
        % Find calcium camera frames matching timestamps
        indices_entrada = find(abs(calciumTimestampTable{:, 2} - timestamps_entrada) <= 80);
        if ismember(sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :}),indices_entrada)
            indices_entrada=indices_entrada(indices_entrada - sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :}) > 0);
        end
        indices_salida = find(abs(calciumTimestampTable{:, 2} - timestamps_salida) <= 80);

        % Extract sysClock values
        sysClocks_entrada = calciumTimestampTable{:, 2};
        sysClocks_salida = calciumTimestampTable{:, 2};

        % Debug display
        disp(['Entry indices: ', mat2str(indices_entrada)]);
        disp(['Exit indices: ', mat2str(indices_salida)]);
        disp(['Entry index size: ', num2str(size(indices_entrada))]);
        disp(['Exit index size: ', num2str(size(indices_salida))]);

        % Find best matching index
        if ~isempty(indices_entrada)
            if frame_entrada == 1
                frame_traza_entrada = indices_entrada(1);
            else
                [~, min_idx_entrada] = min(abs(sysClocks_entrada(indices_entrada) - timestamps_entrada));
                frame_traza_entrada = indices_entrada(min_idx_entrada)
            end
        else
            frame_traza_entrada = NaN;
        end

        if ~isempty(indices_salida)
            [~, min_idx_salida] = min(abs(sysClocks_salida(indices_salida) - timestamps_salida));
            frame_traza_salida = indices_salida(min_idx_salida)
        else
            frame_traza_salida = NaN;
        end
        
        % Make sure exit frame does not exceed available frames
        if frame_traza_salida > max(calciumTimestampTable{:, 1})
            frame_traza_salida = max(calciumTimestampTable{:, 1});
        end
        
        % Add results
        resultadosTemp{i, 1} = frame_traza_entrada;
        if isnan(frame_traza_entrada) || isnan(frame_traza_salida)
            resultadosTemp{i, 2} = NaN;
        else
            resultadosTemp{i, 2} = frame_traza_salida - frame_traza_entrada + 1;
        end
    end

    % Column names
    resultadosTemp.Properties.VariableNames = {['ROI', num2str(j), '_1'], ['ROI', num2str(j), '_2']};
    
    % Merge into final table
    resultados = [resultados, resultadosTemp];
end


% Remove trailing NaN rows if needed
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
maxValidRows = max(numValidRows);
resultados = resultados(1:maxValidRows, :);


% Repeat NaN trimming (duplicate block kept as in your script)
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
maxValidRows = max(numValidRows);
resultados = resultados(1:maxValidRows, :);

% Combine and sort all ROI entry frames
allEntries = [];
for j = 1:numROIs
    allEntries = [allEntries; resultados{:, ['ROI', num2str(j), '_1']}];
end
allEntries = allEntries(~isnan(allEntries));
allEntries = sort(allEntries);
%%
% Initialize NO_ROI list
NO_ROI = [];

% Check if the first entry frame is > 0
if min(allEntries)>0    
    if ~(min(allEntries) == 1)
        NO_ROI(1) = min(allEntries)-1;
    end
end

% Compute frames outside ROIs
for i = 1:length(allEntries) - 1
    exitFrame = NaN;
    for j = 1:numROIs
        if any(resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i))
            duracion = resultados{resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i), ['ROI', num2str(j), '_2']};
            exitFrame = allEntries(i) + duracion;
            disp(allEntries(i))
            disp('duration')
            disp(duracion)
            disp('Exit')
            disp(exitFrame)
            break;
        end
    end
    if isnan(exitFrame)
        exitFrame = allEntries(i);
    end

    noROIFrames = allEntries(i + 1) - exitFrame;

    if ~(noROIFrames==0) && noROIFrames > 0
        NO_ROI(end + 1) = noROIFrames;
    end
    disp('i')
    disp(i)
end
%%
% Last calcium frame
maxFrameCalcium = max(calciumTimestampTable{:, 1});

% Duration of last entry
lastDuration = 0;
for j = 1:numROIs
    if any(resultados{:, ['ROI', num2str(j), '_1']} == allEntries(end))
        lastDuration = resultados{resultados{:, ['ROI', num2str(j), '_1']} == allEntries(end), ['ROI', num2str(j), '_2']};
        break
    end
end
%% 

% Calcula el frame de salida final
finalExitFrame = allEntries(end) + lastDuration;
%%
% Compute final exit frame
finalExitFrame = allEntries(end) + lastDuration;
%%

if finalExitFrame > maxFrameCalcium
    NO_ROI(end + 1) = 0;
else
    NO_ROI(end + 1) = maxFrameCalcium - finalExitFrame
end

% Convert NO_ROI to table
NO_ROITable = table(NO_ROI', 'VariableNames', {'NO_ROI'});

% Debug
disp('NO_ROITable size:');
disp(size(NO_ROITable));
disp('resultados size:');
disp(size(resultados));

% Ensure equal height
if height(NO_ROITable) > height(resultados)
    additionalRows = array2table(nan(height(NO_ROITable) - height(resultados), width(resultados.Properties.VariableNames)), 'VariableNames', resultados.Properties.VariableNames);
    resultados = [resultados; additionalRows];
elseif height(NO_ROITable) < height(resultados)
    additionalRows = array2table(nan(height(resultados) - height(NO_ROITable), 1), 'VariableNames', {'NO_ROI'});
    NO_ROITable = [NO_ROITable; additionalRows];
end

% Merge NO_ROI into results
resultados = [resultados, NO_ROITable];


%% Save results

folderPath = uigetdir('', 'Select a folder');
nombreArchivoResultados = ['resultados_', nombreExtraido, '.csv'];

if folderPath == 0
    disp('No folder selected');
else
    disp(['Selected folder: ' folderPath]);
end

fileName1 = strcat(string(folderPath), '\', nombreArchivoResultados);
writetable(resultados, fileName1);

