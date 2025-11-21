clear all;
% Pedir al usuario que indique el número de ROIs
numROIs = input('Introduce el número de ROIs: ');

% Inicializar las matrices para guardar los datos de entrada
entradas = cell(numROIs, 1);
duraciones = cell(numROIs, 1);

% Pedir al usuario que seleccione los archivos CSV para cada ROI
for i = 1:numROIs
    [file, path] = uigetfile('*.csv', sprintf('Selecciona el archivo CSV para la ROI %d', i));
    indicesGuionBajo = strfind(file, '_');

    % Extraer la parte del nombre hasta el segundo guión bajo
    nombreExtraido = file(1:indicesGuionBajo(2)-1);
    
    if isequal(file, 0)
        disp('Usuario canceló la selección de archivo.');
        return;
    else
        fullPath = fullfile(path, file);
        tempTable = readtable(fullPath, 'ReadVariableNames', true, 'Range', 1);  % Leer a partir de la segunda fila
        entradas{i} = tempTable{:, 1};  % Accediendo a la primera columna directamente
        duraciones{i} = tempTable{:, 2};  % Accediendo a la segunda columna directamente
    end
end

% Pedir al usuario que seleccione los archivos de timestamps de las cámaras
[calciumFile, calciumPath] = uigetfile('*.csv', 'Selecciona el archivo de timestamps de la cámara de calcio');
if isequal(calciumFile, 0)
    disp('Usuario canceló la selección de archivo.');
    return;
else
    calciumTimestampPath = fullfile(calciumPath, calciumFile);
    calciumTimestampTable = readtable(calciumTimestampPath);
end

[behaviorFile, behaviorPath] = uigetfile('*.csv', 'Selecciona el archivo de timestamps de la cámara de comportamiento');
if isequal(behaviorFile, 0)
    disp('Usuario canceló la selección de archivo.');
    return;
else
    behaviorTimestampPath = fullfile(behaviorPath, behaviorFile);
    behaviorTimestampTable = readtable(behaviorTimestampPath);
end

% Determinar el máximo número de filas entre todos los archivos CSV
maxRows = max(cellfun(@(c) size(c, 1), entradas));

% Crear una tabla para los resultados con el máximo número de filas
resultados = table();

% Procesar cada ROI
for j = 1:numROIs
    resultadosTemp = array2table(nan(maxRows, 2));  % Crear una tabla temporal con NaN
    for i = 1:size(entradas{j}, 1)
        % Obtener el frame de entrada y salida para la ROI actual
        if entradas{j}(i)>max(behaviorTimestampTable{:,1})
            break
        end
        frame_entrada = entradas{j}(i);
        frame_salida = frame_entrada + duraciones{j}(i) - 1;
        
        % Encontrar los timestamps de la cámara de comportamiento
        timestamps_entrada = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_entrada, 2};
        disp(frame_entrada)
        disp("---")
        disp(frame_salida)
        % Verificar si el frame_salida existe, si no, usar el frame más cercano
        if any(behaviorTimestampTable{:, 1} == frame_salida)
            timestamps_salida = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_salida, 2};
        else
            % Usar el último frame disponible si frame_salida no existe
            frame_salida = max(behaviorTimestampTable{:, 1});
            timestamps_salida = behaviorTimestampTable{behaviorTimestampTable{:, 1} == frame_salida, 2};
        end

        % Verificar las dimensiones y valores
        disp(['Frame entrada: ', num2str(frame_entrada)]);
        disp(['Frame salida: ', num2str(frame_salida)]);
        disp(['Timestamps entrada: ', num2str(timestamps_entrada)]);
        disp(['Timestamps salida: ', num2str(timestamps_salida)]);
        disp(['Tamaño sysClocks de entrada: ', num2str(size(calciumTimestampTable{:, 2}))]);
        disp(['Tamaño sysClocks de salida: ', num2str(size(calciumTimestampTable{:, 2}))]);
        
        % Buscar todos los frames de la cámara de calcio que coincidan con los timestamps
        indices_entrada = find(abs(calciumTimestampTable{:, 2} - timestamps_entrada) <= 80);
        if ismember(sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :}),indices_entrada)
            indices_entrada=indices_entrada(indices_entrada - sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :}) > 0);
        end
        indices_salida = find(abs(calciumTimestampTable{:, 2} - timestamps_salida) <= 80);

        % Obtener los tiempos del sistema para los índices encontrados
        sysClocks_entrada = calciumTimestampTable{:, 2};
        sysClocks_salida = calciumTimestampTable{:, 2};

        % Verificar las dimensiones y valores de los índices
        disp(['Indices entrada: ', mat2str(indices_entrada)]);
        disp(['Indices salida: ', mat2str(indices_salida)]);
        disp(['Tamaño indices entrada: ', num2str(size(indices_entrada))]);
        disp(['Tamaño indices salida: ', num2str(size(indices_salida))]);

        % Encontrar el índice con la menor diferencia
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
        
        % Asegurarse de que el frame de salida no exceda el último frame de la cámara de calcio
        if frame_traza_salida > max(calciumTimestampTable{:, 1})
            frame_traza_salida = max(calciumTimestampTable{:, 1});
        end
        
        % Agregar los resultados a la tabla temporal
        resultadosTemp{i, 1} = frame_traza_entrada;
        if isnan(frame_traza_entrada) || isnan(frame_traza_salida)
            resultadosTemp{i, 2} = NaN;
        else
            resultadosTemp{i, 2} = frame_traza_salida - frame_traza_entrada + 1;
        end
    end
    % Asignar nombres a las columnas de la tabla temporal
    resultadosTemp.Properties.VariableNames = {['ROI', num2str(j), '_1'], ['ROI', num2str(j), '_2']};
    
    % Añadir los resultados de la tabla temporal a la tabla de resultados final
    resultados = [resultados, resultadosTemp];
end

% Eliminar las filas con NaN al final de la tabla si es necesario
% Encuentra el número de filas válidas para cada conjunto de columnas de ROI
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
% Encuentra el número máximo de filas válidas en todos los conjuntos de columnas de ROI
maxValidRows = max(numValidRows);
% Reduce la tabla de resultados para que solo tenga el número máximo de filas válidas
resultados = resultados(1:maxValidRows, :);

% Escribir la tabla de resultados a un nuevo archivo CSV
writetable(resultados, 'F:\Ex3_BLA\DLC\OR_FRAMESUNIDOS\resultados.csv');

% Eliminar las filas con NaN al final de la tabla si es necesario
% Encuentra el número de filas válidas para cada conjunto de columnas de ROI
numValidRows = arrayfun(@(n) sum(~isnan(resultados{:, ['ROI', num2str(n), '_1']})), 1:numROIs);
% Encuentra el número máximo de filas válidas en todos los conjuntos de columnas de ROI
maxValidRows = max(numValidRows);
% Reduce la tabla de resultados para que solo tenga el número máximo de filas válidas
resultados = resultados(1:maxValidRows, :);

% Combinar y ordenar los frames de entrada de todos los ROIs
allEntries = [];
for j = 1:numROIs
    allEntries = [allEntries; resultados{:, ['ROI', num2str(j), '_1']}];
end
allEntries = allEntries(~isnan(allEntries)); % Eliminar NaN
allEntries = sort(allEntries); % Ordenar de menor a mayor
%% 

% Inicializar la lista NO_ROI
NO_ROI = [];

% Verificar si el primer frame de entrada es mayor que 0
if min(allEntries)>0    
    if ~(min(allEntries) == 1)
        NO_ROI(1) = min(allEntries)-1;
    else
        NO_ROI(1) = min(allEntries);
    end
end

% Calcular los frames fuera de los ROIs
for i = 1:length(allEntries) - 1
    % Encuentra el frame de salida asociado a la entrada actual
    exitFrame = NaN;
    for j = 1:numROIs
        if any(resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i))
            duracion = resultados{resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i), ['ROI', num2str(j), '_2']};
            exitFrame = allEntries(i) + duracion;
            disp(allEntries(i))
            disp('duracio')
            disp(duracion)
            disp('Exit')
            disp(exitFrame)
            break;
        end
    end
    if isnan(exitFrame)
        exitFrame = allEntries(i); % Por si acaso no se encuentra la entrada en las columnas
    end

    % Calcula los frames fuera del ROI antes de la siguiente entrada
    noROIFrames = allEntries(i + 1) - exitFrame;
    % Asegurarse de que noROIFrames no sea negativo
    % if noROIFrames < 0
    %     NO_ROI(end + 1) = 0;
    % end
    % Agrega al resultado
    if ~(noROIFrames==0) && noROIFrames > 0
        NO_ROI(end + 1) = noROIFrames;
    end
    disp('i')
    disp(i)
end
%%
% Encuentra el último frame registrado para la cámara de calcio
maxFrameCalcium = max(calciumTimestampTable{:, 1});

% Encuentra la duración correspondiente al último valor en allEntries
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


if finalExitFrame > maxFrameCalcium
    NO_ROI(end + 1) = 0;
else
    NO_ROI(end + 1) = maxFrameCalcium - finalExitFrame
end

% Convertir NO_ROI en una tabla
NO_ROITable = table(NO_ROI', 'VariableNames', {'NO_ROI'});

% Depuración: Verificar tamaños de tablas y variables
disp('Tamaño de NO_ROITable:');
disp(size(NO_ROITable));
disp('Tamaño de resultados:');
disp(size(resultados));

% Comprobar cuál tabla es más larga y rellenar la más corta con NaN
if height(NO_ROITable) > height(resultados)
    % Si NO_ROI es más larga, extiende 'resultados' con NaN
    additionalRows = array2table(nan(height(NO_ROITable) - height(resultados), width(resultados.Properties.VariableNames)), 'VariableNames', resultados.Properties.VariableNames);
    resultados = [resultados; additionalRows];
elseif height(NO_ROITable) < height(resultados)
    % Si 'resultados' es más largo, extiende NO_ROI con NaN
    additionalRows = array2table(nan(height(resultados) - height(NO_ROITable), 1), 'VariableNames', {'NO_ROI'});
    NO_ROITable = [NO_ROITable; additionalRows];
end

% Unir la tabla NO_ROI con 'resultados'
resultados = [resultados, NO_ROITable];
% Verificar si el primer valor en la columna NO_ROI es igual a 1
% if resultados.NO_ROI(1) == 1
%     % Eliminar el primer valor y desplazar el resto hacia arriba
%     resultados.NO_ROI(1:end-1) = resultados.NO_ROI(2:end);
%     resultados.NO_ROI(end) = NaN; % Añadir NaN al final
% end
%%
nombreArchivoResultados = ['F:\Ex3_BLA\DLC\OR_FRAMESUNIDOS\resultados_', nombreExtraido, '.csv'];

% Escribir la tabla final a un nuevo archivo CSV
writetable(resultados, nombreArchivoResultados);
delete('F:\Ex3_BLA\DLC\OR_FRAMESUNIDOS\resultados.csv');

