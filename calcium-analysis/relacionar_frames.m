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


% Pedir al usuario que seleccione el archivo de texto con los timestamps
[file, path] = uigetfile('*.dat', 'Selecciona el archivo de texto con los timestamps');
if isequal(file, 0)
    disp('Usuario canceló la selección de archivo.');
    return;
else
    timestampPath = fullfile(path, file);
    timestampTable = readtable(timestampPath);
end

%%
% Determinar el máximo número de filas entre todos los archivos CSV
maxRows = max(cellfun(@(c) size(c, 1), entradas));

% Crear una tabla para los resultados con el máximo número de filas
resultados = table();
% Obtener los tiempos del sistema para los índices encontrados
sysClocks_entrada = timestampTable.sysClock(timestampTable.camNum == 0);
sysClocks_salida = timestampTable.sysClock(timestampTable.camNum == 0);

% Procesar cada ROI
for j = 1:numROIs
    resultadosTemp = array2table(nan(maxRows, 2));  % Crear una tabla temporal con NaN
    for i = 1:size(entradas{j}, 1)
        % Obtener el frame de entrada y salida para la ROI actual
        frame_entrada = entradas{j}(i);
        frame_salida = frame_entrada + duraciones{j}(i) - 1;
        
        % Encontrar los timestamps de la cámara de comportamiento
        timestamps_entrada = timestampTable{timestampTable.camNum == 1 & timestampTable.frameNum == frame_entrada, 'sysClock'};
        timestamps_salida = timestampTable{timestampTable.camNum == 1 & timestampTable.frameNum == frame_salida, 'sysClock'};
        i
        j
        % Buscar todos los frames de la cámara de las trazas que coincidan con los timestamps
        indices_entrada = find(abs(timestampTable.sysClock(timestampTable.camNum == 0) - timestamps_entrada) <= 80);
        
        indices_salida = find(abs(timestampTable.sysClock(timestampTable.camNum == 0) - timestamps_salida) <= 80);
        
         % Buscar todos los frames de la cámara de calcio que coincidan con los timestamps
        
        
        if any(ismember(sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,1}), 2), 1, 'last'), :}),indices_entrada)) 
            indices_entrada=indices_entrada(indices_entrada - sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :}) >= 0);
        elseif j==2
            if any(ismember(resultados{~any(isnan(resultados{:,1}), 2), 1},indices_entrada)) 
                %% change  > or < when its needed
                indices_entrada=indices_entrada(indices_entrada>resultados{ismember(resultados{~any(isnan(resultados{:,1}), 2), 1},indices_entrada),1});
            elseif any(ismember(sum(resultados{~any(isnan(resultados{:,1}), 2), [1 2]},2),indices_entrada)) 
                indices_entrada=indices_entrada(indices_entrada>=sum(resultados{ismember(sum(resultados{~any(isnan(resultados{:,1}), 2), [1 2]},2),indices_entrada),[1 2]}));

            end
        end
        
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

         if any(ismember(sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :})-1,indices_salida)) 
            indices_salida=indices_salida(indices_salida-(sum(resultadosTemp{find(~any(isnan(resultadosTemp{:,:}), 2), 1, 'last'), :})-1) > 0);
            
        elseif j==2
            
            if any(ismember(resultados{~any(isnan(resultados{:,1}), 2), 1},indices_salida)) 
                
                frame_rep=resultados{ismember(resultados{~any(isnan(resultados{:,1}), 2), 1},indices_salida),1};
                frame_rep=min(frame_rep(frame_rep>frame_traza_entrada));
                indices_salida=indices_salida(indices_salida<frame_rep);
            
    
            end
        end
        
        if ~isempty(indices_salida)
            [~, min_idx_salida] = min(abs(sysClocks_salida(indices_salida) - timestamps_salida));
            frame_traza_salida = indices_salida(min_idx_salida);
        else
            frame_traza_salida = NaN;
        end
        

        
       
        % Encontrar el índice con la menor diferencia
        

        
        disp(['Frame de entrada: ', num2str(frame_entrada)]);
        disp(['Frame de salida: ', num2str(frame_salida)]);
        disp(['Timestamp de entrada: ', num2str(timestamps_entrada)]);
        disp(['Timestamp de salida: ', num2str(timestamps_salida)]);
        disp(['Índices de entrada: ', mat2str(indices_entrada)]);
        disp(['Índices de salida: ', mat2str(indices_salida)]);
        disp(['SysClocks entrada: ', mat2str(sysClocks_entrada(indices_entrada))]);
        disp(['SysClocks salida: ', mat2str(sysClocks_salida(indices_salida))]);
        disp('+++')
        disp(frame_traza_entrada)
        
        
        
        % Agregar los resultados a la tabla temporal
        resultadosTemp{i, 1} = frame_traza_entrada;
        if isnan(frame_traza_entrada) || isnan(frame_traza_salida)
            resultadosTemp{i, 2} = NaN;
        else
            resultadosTemp{i, 2} = frame_traza_salida - frame_traza_entrada + 1;
        end
    end
    resultadosTemp=table(resultadosTemp{~isnan(resultadosTemp{:,1}),1},resultadosTemp{~isnan(resultadosTemp{:,1}),2});
    resultadosTemp=[resultadosTemp; array2table(nan(maxRows-size(resultadosTemp,1),2), 'VariableNames', resultadosTemp.Properties.VariableNames)];
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


% Combinar y ordenar los frames de entrada de ambos ROIs
allEntries = [resultados.ROI1_1; resultados.ROI2_1];
allEntries = allEntries(~isnan(allEntries)); % Eliminar NaN
allEntries = sort(allEntries); % Ordenar de menor a mayor



% Inicializar la lista NO_ROI
NO_ROI = [];

% Combinar y ordenar los frames de entrada de todos los ROIs
allEntries = [];
for j = 1:numROIs
    allEntries = [allEntries; resultados{:, ['ROI', num2str(j), '_1']}];
end
allEntries = allEntries(~isnan(allEntries)); % Eliminar NaN
allEntries = sort(allEntries); % Ordenar de menor a mayor

% Verificar si el primer frame de entrada es mayor que 0
if min(allEntries)>0    
    if ~(min(allEntries) == 1)
        NO_ROI(1) = min(allEntries)-1;
    else
        NO_ROI(1) = min(allEntries);
    end
end
%%
% Calcular los frames fuera de los ROIs
for i = 1:length(allEntries) - 1
    % Encuentra el frame de salida asociado a la entrada actual
    exitFrame = NaN;
    for j = 1:numROIs
        if any(resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i))
            duracion = resultados{resultados{:, ['ROI', num2str(j), '_1']} == allEntries(i), ['ROI', num2str(j), '_2']};
            exitFrame = allEntries(i) + duracion;
            disp('+++');
            disp(duracion);
            disp('---');
            disp(exitFrame);
            break;
        end
    end
    if isnan(exitFrame)
        exitFrame = allEntries(i); % Por si acaso no se encuentra la entrada en las columnas
        disp('.....')
        disp(exitFrame)
    end

    % Calcula los frames fuera del ROI antes de la siguiente entrada
    noROIFrames = allEntries(i + 1) - exitFrame;
    % Agrega al c
    if noROIFrames < 0
        noROIFrames = 0;
    end
    if ~(noROIFrames==0)
        NO_ROI(end + 1) = noROIFrames;
    end
end



%%

% Encuentra el último frame registrado para la cámara de trazas
maxFrameCam0 = max(timestampTable.frameNum(timestampTable.camNum == 0));

% Encuentra la duración correspondiente al último valor en allEntries
if any(resultados.ROI1_1 == allEntries(end))
    lastDuration = resultados.ROI1_2(resultados.ROI1_1 == allEntries(end));
elseif any(resultados.ROI2_1 == allEntries(end))
    lastDuration = resultados.ROI2_2(resultados.ROI2_1 == allEntries(end));
else
    lastDuration = 0; % Por si acaso no se encuentra la entrada en las columnas
end

% Calcula el frame de salida final
finalExitFrame = allEntries(end) + lastDuration;

% Calcula el último valor para NO_ROI
NO_ROI(end + 1) = maxFrameCam0 - finalExitFrame;

% Convertir NO_ROI en una tabla
NO_ROITable = table(NO_ROI', 'VariableNames', {'NO_ROI'});

% Comprobar cuál tabla es más larga y rellenar la más corta con NaN
if height(NO_ROITable) > height(resultados)
    % Si NO_ROI es más larga, extiende 'resultados' con NaN
    additionalRows = array2table(nan(height(NO_ROITable) - height(resultados), width(resultados)), 'VariableNames', resultados.Properties.VariableNames);
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
