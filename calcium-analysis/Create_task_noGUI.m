clear all;
% Leer el archivo CSV
filename = ['F:\Ex3_BLA\DLC\OR_FRAMESUNIDOS\resultados_2C_OR.csv']; % Cambiar esto por la ruta a tu archivo CSV
dataTable = readtable(filename);

% Número de ROIs (asumiendo que cada ROI tiene dos columnas: _fr y _num)
numROIs = (width(dataTable) - 1) / 2; % -1 para excluir la columna NO_ROI

% Variables para almacenar los frames y duraciones de cada ROI
roi_frames = cell(numROIs, 1);
roi_durations = cell(numROIs, 1);
for i = 1:numROIs
    roi_frames{i} = dataTable{:, sprintf('ROI%d_1', i)};
    roi_durations{i} = dataTable{:, sprintf('ROI%d_2', i)};
end
no_roi_durations = dataTable{~isnan(dataTable{:, 'NO_ROI'}), :};
%%
% Variables para almacenar las secuencias
sequence = {}; % Almacena la secuencia de periodos

if min(roi_frames{1,:})==1 || min(roi_frames{2,:})==1
    count_no_roi = 0;% Contador para los periodos NO_ROI
else
    count_no_roi = 1;
end

% Procesar y almacenar secuencia de eventos
current_frame = min(min(roi_frames{1,:}),min(roi_frames{2,:})); % Iniciar en el frame 1

while current_frame <= max(cellfun(@(x) max(x, [], 'omitnan'), roi_frames), [], 'omitnan')
    max(cellfun(@(x) max(x, [], 'omitnan'), roi_frames), [], 'omitnan')
    % Encontrar el próximo frame de ROI más cercano
    current_frame
    % Encontrar el próximo frame de ROI más cercano
   
    next_frames = cellfun(@(x) min(x(x >= current_frame)), roi_frames, 'UniformOutput', false);
    next_frames = [next_frames{:}];
    next_frames = next_frames(~isnan(next_frames)) % Eliminar NaNs
    numColumns = size(dataTable, 2);
    valid_indices = find(mod(1:numColumns, 2) == 1); % Índices de las columnas impares
    valid_indices = valid_indices(valid_indices ~= numColumns); % Excluir la última columna impar
    % Si solo hay un frame siguiente, determina a qué ROI pertenece
    a='Hola'
    if length(next_frames) == 1
        frame_to_find = next_frames(1);
        roi_index = find(arrayfun(@(i) any(dataTable{:, valid_indices(i)} == frame_to_find), 1:length(valid_indices)), 1);
        %roi_index = ceil(roi_index / 2); % Ajuste porque cada ROI tiene 2 columnas
        next_frame = frame_to_find; % El siguiente frame ya es conocido
    else
        b="ey"
        %[next_frame, roi_index] = min(next_frames, [], 'omitnan');
        
        next_frame = min(next_frames, [], 'omitnan');
        
    
        roi_index = find(arrayfun(@(i) any(dataTable{:, valid_indices(i)} == next_frame), 1:length(valid_indices)), 1);
        %roi_index = ceil(roi_index / 2)
    end
    next_frame
    roi_index
    % Verificar si hay un periodo NO_ROI antes del próximo frame de ROI
    if isempty(next_frames) || current_frame < next_frame
        
        if min(roi_frames{1,:})==1 || min(roi_frames{2,:})==1
            sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi+1);
        else
            sequence{end+1} = sprintf('NO_ROI_%d',count_no_roi);
        end
        
        count_no_roi = count_no_roi + 1
        if ~isempty(next_frames)
            current_frame = next_frame; % Asegúrate de actualizar current_frame solo si next_frames no está vacío
        else
            break; % Sal del bucle si no hay más frames de ROI
        end
    else
        % Agregar el periodo de ROI a la secuencia
        a="hola"
        roi_index;
        
        sequence{end+1} = sprintf('ROI%d_%d', roi_index, find(roi_frames{roi_index} == next_frame, 1));
        current_frame = next_frame + roi_durations{roi_index}(find(roi_frames{roi_index} == next_frame, 1));
    end
end
% %%
% % Leer el archivo CSV
% filename = 'C:\Users\lpm97\OneDrive\Documentos\Documentos\Laboratorio de neuro\Paper leire\Funciones\resultados_10A_EPM.csv';
% dataTable = readtable(filename);
% 
% % Número de ROIs (asumiendo que cada ROI tiene dos columnas: _fr y _num)
% numROIs = (width(dataTable) - 1) / 2; % -1 para excluir la columna NO_ROI
% 
% % Variables para almacenar los frames y duraciones de cada ROI
% roi_frames = cell(numROIs, 1);
% roi_durations = cell(numROIs, 1);
% for i = 1:numROIs
%     roi_frames{i} = dataTable{:, sprintf('ROI%d_1', i)};
%     roi_durations{i} = dataTable{:, sprintf('ROI%d_2', i)};
% end
% no_roi_durations = dataTable{:, 'NO_ROI'};
% 
% % Variables para almacenar las secuencias
% sequence = {}; % Almacena la secuencia de periodos
% count_no_roi = 1; % Contador para los periodos NO_ROI
% 
% % Procesar y almacenar secuencia de eventos
% current_frame = 1; % Iniciar en el frame 1
% max_frame = max(cellfun(@(x) max(x, [], 'omitnan'), roi_frames), [], 'omitnan');
% 
% while current_frame <= max_frame
%     % Depuración
%     fprintf('Current frame: %d\n', current_frame);
% 
%     % Encontrar el próximo frame de ROI más cercano que sea mayor a current_frame
%     next_frames = arrayfun(@(idx) min(roi_frames{idx}(roi_frames{idx} > current_frame)), 1:numROIs, 'UniformOutput', false);
%     next_frames = [next_frames{:}];
%     next_frames = next_frames(~isnan(next_frames)); % Eliminar NaNs
% 
%     % Si no quedan más frames de ROI por procesar, salimos del bucle
%     if isempty(next_frames)
%         break;
%     end
% 
%     % Encontramos el siguiente frame de ROI más cercano que sea mayor a current_frame
%     [next_frame, roi_index] = min(next_frames);
%     fprintf('Next frame: %d\n', next_frame);
%     fprintf('Next frames: %s\n', mat2str(next_frames))
%     % Calculamos la duración del último ROI si estamos en un ROI
%     duration = 0;
%     if any(roi_frames{roi_index} == current_frame)
%         duration = roi_durations{roi_index}(roi_frames{roi_index} == current_frame);
%     end
% 
%     % Si hay un gap entre el último frame de ROI y el siguiente frame, agregamos NO_ROI
%     if current_frame + duration < next_frame
%         sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi);
%         count_no_roi = count_no_roi + 1;
%     end
% 
%     % Agregamos el ROI a la secuencia
%     sequence{end+1} = sprintf('ROI%d_%d', roi_index, find(roi_frames{roi_index} == next_frame, 1));
% 
%     % Actualizamos current_frame al frame después del final del ROI actual
%     current_frame = next_frame + duration;
% 
% 
% end

%%
% Verificar y añadir el último periodo de NO_ROI si es necesario
aux=dataTable{~isnan(dataTable{:,5}),5}; 
if aux~=0 
    sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi);
end
% % Verificar y añadir el último periodo de NO_ROI si es necesario
% if count_no_roi <= height(dataTable)
%     sequence{end+1} = sprintf('NO_ROI_%d', count_no_roi+1);
% end

% Asignar secuencia a Task.Titles
Task.Titles = sequence;

%%
% Leer el archivo CSV

% Extraer los títulos de los periodos de Task.Titles
period_titles = Task.Titles;

% Inicializar Task.Lengths como un vector de ceros
Task.Lengths = zeros(1, numel(period_titles));
Task.Frames= zeros(1, numel(period_titles));
%%

% Recorrer los títulos y buscar el valor correspondiente en el archivo CSV
for i = 1:numel(period_titles)
    title = period_titles{i}
    
    if startsWith(title, 'NO_ROI')
        % Es un periodo NO_ROI, buscar en la columna "NO_ROI" del CSV
        Task.Lengths(i) = dataTable{str2double(extractAfter(title, 'NO_ROI_')), 'NO_ROI'};
    else
        % Es un periodo ROI, determinar si es ROI1 o ROI2
        roi_type = extractBefore(title, '_')
        roi_index = str2double(extractAfter(title, '_'))
        % Buscar en la columna correspondiente del CSV (ROIX_2)
        Task.Lengths(i) = dataTable{roi_index, sprintf('%s_2', roi_type)};
    end
end
%%
Task.Frames=Task.Lengths;
Task.Lengths = num2cell(Task.Lengths);
% Convertir celdas de números a celdas de cadenas de caracteres
Task.Lengths = cellfun(@num2str, Task.Lengths, 'UniformOutput', false);
%%
% Inicializar Task.Start y Task.End como cell arrays
Task.Start = cell(1, numel(Task.Lengths));
Task.End = cell(1, numel(Task.Lengths));

% Calcular Task.Start
Task.Start{1} = 1; % El primer Task.Start es siempre 1
for i = 2:numel(Task.Lengths)
    Task.Start{i} = Task.Start{i-1} + str2double(Task.Lengths{i-1});
    disp(Task.Start{i})
    
end

% Calcular Task.End
for i = 1:numel(Task.Lengths)
    Task.End{i} = Task.Start{i} + str2double(Task.Lengths{i}) - 1;
    disp(Task.End{i})
end
%%
Task.FPS=20;
%%
% Inicializar Task.Pattern como una matriz de ceros
Task.Pattern = zeros(numel(Task.Titles), max(cellfun(@str2double, Task.Lengths)));

% Llenar Task.Pattern con unos en los frames correspondientes
current_frame = 1;
for i = 1:numel(Task.Titles)
    length = str2double(Task.Lengths{i});
    Task.Pattern(i, current_frame:current_frame + length - 1) = 1;
    current_frame = current_frame + length;
    disp(current_frame)
end
%%
Task.Start = cell2mat(Task.Start);
Task.End = cell2mat(Task.End);

%%
% Especifica la ruta completa de la carpeta donde deseas guardar la variable Task
folder_path = 'F:\Ex3_BLA\DLC\OR_TASK';

% Especifica el nombre del archivo en el que deseas guardar la variable Task
file_name = ['task_M9_OR.mat'];
% Combina la ruta de la carpeta y el nombre del archivo
full_file_path = fullfile(folder_path, file_name);

% Guarda la variable Task en el archivo .mat
save(full_file_path, 'Task');

% Muestra un mensaje de confirmación
fprintf('La variable Task se ha guardado en: %s\n', full_file_path);

