%% LOAD THE REQUIRED DATASETS
% 1 - Adding the project path to the searchpath
% Experiment properties
output_path = "C:\Users\1627858\OneDrive - UAB\Escritorio\CAIMAN\SI\ms_files\TestLoad";
% Adding functions to search path
addpath(genpath(output_path))
addpath(genpath("C:\Users\1627858\OneDrive - UAB\Escritorio\CAIMAN\Analysis"))

% 2 - Creating a new folder for the query
target_path = output_path + "\GlobalFluorescence final " + ...
    string(datetime(floor(now),'ConvertFrom','datenum'));
mkdir(target_path)



% Nuevos colores en formato RGB
new_color_CORT = [0.341, 0.341, 0.976];
new_color_VEH = [0.784, 0.871, 0.976];

% Actualizar la paleta de colores en Experiment.Project.Palette
Experiment.Project.Palette("CORT") = {new_color_CORT};
Experiment.Project.Palette("VEH") = {new_color_VEH};

% Mostrar la paleta actualizada para verificar los cambios
disp('Paleta de colores actualizada:');
disp(Experiment.Project.Palette);

%%
Experiment = removeAnimalAndGroup(Experiment, [2,7]);
%%
% Obtén todos los nombres de los animales en Experiment.EPM
animals = fieldnames(Experiment.EPM);

% Recorre cada animal
for a = 1:length(animals)
    animal = animals{a};  % Nombre del animal actual
    % Obtén los títulos de las tareas del animal actual
    titles = Experiment.EPM.(animal).Task.Titles;

    % Recorre cada título
    for t = 1:length(titles)
        title = titles{t};  % Título actual

        % Reemplaza 'ROI2' por 'ROI1'
        if startsWith(title, 'ROI2')
            newTitle = strrep(title, 'ROI2', 'ROI1');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end

        % Reemplaza 'ROI3' por 'ROI2'
        if startsWith(title, 'ROI3')
            newTitle = strrep(title, 'ROI3', 'ROI2');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end

        % Reemplaza 'ROI4' por 'ROI2'
        if startsWith(title, 'ROI4')
            newTitle = strrep(title, 'ROI4', 'ROI2');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end
    end
end

% Mostrar algunos títulos modificados como verificación
disp(Experiment.EPM.M1.Task.Titles(1:10));
%%
% Crear un nuevo containers.Map si Palette es un dictionary y no se puede manipular directamente
newPalette = containers.Map({'CORT', 'VEH'}, ...
                {Experiment.Project.Palette('Male'), Experiment.Project.Palette('Female')});

% Ahora 'newPalette' tiene las nuevas claves con los mismos valores que las antiguas claves en 'Palette'
Experiment.Project.Palette = newPalette;

%% 1 - Global fluorescence changes
% Setting the parameters for the specific query
Data = Experiment.SI;
%Task = Experiment.EPM.Task;
% Extracting the palette and sexes
GroupBy = string(Experiment.Project.Groups);
Palette = Experiment.Project.Palette;
RF = 30;
PerformStats = true;
close all
% Running the function
[Means,Fluorescence] = F_PopulationFluorescence_lei(Data, GroupBy, "Treatment", output_path);
exportgraphics(gcf, strcat(target_path, "\Outliers.pdf"),  ...
    'ContentType','vector')
% Shifting traces
%%
% Pre-allocate para almacenar la media de cada fila
meanFluPerRow_noshift = nan(size(Fluorescence, 1), 1);

% Iterar a través de cada fila para calcular la media, excluyendo NaN
for i = 1:size(Fluorescence, 1)
    % Acceder directamente al vector de 'Flu' para la fila i
    currentFluVector = Fluorescence.Flu(i, :); % Asegúrate de que esto corresponde a cómo están organizados tus datos
    % Calcular la media, excluyendo NaN
    meanFluPerRow_noshift(i) = nanmean(currentFluVector);
end

%%
close all
% Visualising the traces
F_ViewTraces(Fluorescence, 'Flu', 'Treatment', Experiment, RF, 0, "Time (s)",...
    "(\DeltaF/F_0)-F_{Hab}", output_path, true, [], false,[])
exportgraphics(gcf, strcat(target_path, "\GlobalFluorescence.pdf"),  ...
    'ContentType','image')
%close all
%%
RefEpoch = [];
Method = "Pctile 50"; % "Mean", "Pctile n", "None"
Scaling = true;
%%
animalFields = fieldnames(Experiment.SI);
% Filtrar para quedarse solo con los campos que comienzan con 'M'
animals = animalFields(startsWith(animalFields, 'M'));
%%
Task=[];
Fluorescence = F_ShiftTrace(Fluorescence, 'Flu', [], Method, Task, ...
      Scaling);
%%
% Crear una nueva tabla para almacenar los resultados de F_ShiftTrace
FluorescenceShifted = table([], [], [], [], 'VariableNames', {'Treatment', 'Flu', 'Animal', 'Shift'});

% Iterar sobre cada animal y aplicar F_ShiftTrace
for i = 1:length(animals)
    animal = animals{i};
    AnimalData = Experiment.EPM.(animal);
    AnimalTask = AnimalData.Task;  % Estructura Task específica del animal

    % Extraer la fila correspondiente de la tabla Fluorescence
    FluorescenceRow = Fluorescence(Fluorescence.Animal == i, :);

    % Aplicar F_ShiftTrace a esta fila
    ShiftedRow = F_ShiftTrace(FluorescenceRow, 'Flu', [], Method, AnimalTask, Scaling);

    % Agregar los resultados a la tabla FluorescenceShifted
    FluorescenceShifted = [FluorescenceShifted; ShiftedRow];
end

% Reemplazar la variable Fluorescence con la nueva versión Shifted
Fluorescence = FluorescenceShifted;
%Fluorescence = F_ShiftTrace(Fluorescence, 'Flu', [], Method, Task, ...
      %Scaling);
      %%
% Pre-allocate para almacenar la media de cada fila
meanFluPerRow_shift = nan(size(Fluorescence, 1), 1);

% Iterar a través de cada fila para calcular la media, excluyendo NaN
for i = 1:size(Fluorescence, 1)
    % Acceder directamente al vector de 'Flu' para la fila i
    currentFluVector = Fluorescence.Flu(i, :); % Asegúrate de que esto corresponde a cómo están organizados tus datos
    % Calcular la media, excluyendo NaN
    meanFluPerRow_shift(i) = nanmean(currentFluVector);
end

%%
close all
% Visualising the traces
F_ViewTraces(Fluorescence, 'Flu', 'Treatment', Experiment, RF, 0, "Time (s)",...
    "(\DeltaF/F_0)-F_{Hab}", output_path, true, [], false,[])
exportgraphics(gcf, strcat(target_path, "\GlobalFluorescence.pdf"),  ...
    'ContentType','image')
%close all


%% 3 - Grouping specific sessions
% Inputs
% Extraer los títulos de la estructura
% titles = Task.Titles;
% 
% % Inicializar un Map para mantener las categorías y los títulos asociados
% categoryMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
% 
% % Iterar sobre todos los títulos y clasificarlos según el patrón de ROI
% for i = 1:length(titles)
%     title = titles{i};
%     % Encuentra el patrón que indica la categoría del título
%     pattern = regexp(title, '^(ROI\d+|NO_ROI)', 'match', 'once');
%     if ~isempty(pattern)
%         if ~isKey(categoryMap, pattern)
%             categoryMap(pattern) = {title};  % Inicializar con el primer título
%         else
%             currentList = categoryMap(pattern);  % Extraer la lista actual
%             currentList{end+1} = title;  % Agregar el nuevo título
%             categoryMap(pattern) = currentList;  % Reasignar la lista actualizada
%         end
%     end
% end
% 
% % Encontrar el número máximo de títulos en una sola categoría
% max_titles = max(cellfun(@(x) length(x), values(categoryMap)));
% 
% % Rellenar las categorías más cortas con "NaN"
% categories = keys(categoryMap);
% for i = 1:length(categories)
%     currentCategory = categories{i};
%     categoryMap(currentCategory) = [categoryMap(currentCategory), repmat({'NaN'}, 1, max_titles - length(categoryMap(currentCategory)))];
% end
% 
% % Combinar las categorías en una variable Episodes
% Episodes = cell(length(categories), max_titles);
% for i = 1:length(categories)
%     Episodes(i, :) = categoryMap(categories{i});
% end
allEpisodes = struct();  % Estructura para almacenar Episodes de todos los animales

for a = 1:length(animals)
    animal = animals{a};
    Task = Experiment.SI.(animal).Task;
    titles = Task.Titles;

    % Inicializar categoryMap para este animal
    categoryMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Procesar títulos para este animal
    for i = 1:length(titles)
        title = titles{i};
        pattern = regexp(title, '^(ROI\d+|NO_ROI)', 'match', 'once');
        if ~isempty(pattern)
            if ~isKey(categoryMap, pattern)
                categoryMap(pattern) = {title};
            else
                currentList = categoryMap(pattern);
                currentList{end+1} = title;
                categoryMap(pattern) = currentList;
            end
        end
    end

    % Rellenar categorías más cortas y combinar en Episodes
    max_titles = max(cellfun(@(x) length(x), values(categoryMap)));
    categories = keys(categoryMap);
    Episodes = cell(length(categories), max_titles);
    for i = 1:length(categories)
        Episodes(i, :) = [categoryMap(categories{i}), repmat({'NaN'}, 1, max_titles - length(categoryMap(categories{i})))];
    end

    % Almacenar Episodes en la estructura global
    allEpisodes.(animal) = Episodes;
end
%%
%Episodes = ["ROI1_1", "ROI1_2","ROI1_3","ROI1_4","ROI1_5","ROI1_6"];
% Episodes = ["NO ROI_1", "NO ROI_2","NO ROI_3";
%     "ROI1_1", "ROI1_2","ROI1_3";...
%     "ROI2_1", "ROI2_2","ROI2_3"];
Cathegory = ["NO ROI", "ROI 1", "ROI 2"];
%Cathegory = ["ROI 1"];
disp('fff')
% allTitleFrames = struct();  % Estructura para almacenar titleFrames de todos los animales
% length(animals)
% for a = 1:length(animals)
%     animal = animals{a};
%     Task = Experiment.EPM.(animal).Task;
%     titles = Task.Titles;
%     length(titles);
%     frames = Task.Frames;
% 
%     % Inicializar titleFrames para este animal
%     titleFrames = containers.Map();
% 
%     % Procesar títulos y frames para este animal
%     for i = 1:length(titles)
%         i
%         frames(i)
%         titleFrames(titles{i}) = frames(i);
%     end
%     titleFrames
% 
%     % Almacenar titleFrames en la estructura global
%     allTitleFrames.(animal) = titleFrames;
% end
allTitleFrames = struct();  % Estructura para almacenar titleFrames de todos los animales

for a = 1:length(animals)
    animal = animals{a};
    Task = Experiment.SI.(animal).Task;
    titles = Task.Titles;
    frames = Task.Frames;

    % Inicializar titleFrames para este animal
    titleFrames = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Procesar títulos y frames para este animal
    for i = 1:length(titles)
        if isKey(titleFrames, titles{i})
            % Si el título ya existe, añadimos el frame al arreglo existente
            currentFrames = titleFrames(titles{i});
            titleFrames(titles{i}) = [currentFrames, frames(i)];  % Añadir nuevo frame al arreglo
        else
            % Si el título no existe, creamos un nuevo arreglo con el frame
            titleFrames(titles{i}) = [frames(i)];  % Inicializar con el primer frame
        end
    end

    % Almacenar titleFrames en la estructura global
    allTitleFrames.(animal) = titleFrames;
end
%%
% categoryFrames = zeros(1, length(Cathegory));
% for i = 1:size(Episodes, 1)
%     for j = 1:size(Episodes, 2)
%         episodeTitle = Episodes{i, j};
%         if ~isempty(episodeTitle) && isKey(titleFrames, episodeTitle)
%             % Sumar el número de frames si el título es válido
%             categoryFrames(i) = categoryFrames(i) + titleFrames(episodeTitle);
%         elseif strcmp(episodeTitle, "NaN")
%             % Omitir o manejar de manera diferente los títulos no válidos
% 
%             % categoryFrames(i) = categoryFrames(i) + valorPredeterminado;
%         end
%     end
% end
% maxFrames = max(categoryFrames);
% Crear una estructura para almacenar categoryFrames de todos los animales
% Crear una estructura para almacenar categoryFrames de todos los animales
allCategoryFrames = struct();

for a = 1:length(animals)
    
    animal = animals{a};
    
    % Obtener el mapa titleFrames para este animal
    titleFrames = allTitleFrames.(animal);

    % Calcular categoryFrames para este animal
    categoryFrames = zeros(1, length(Cathegory));
    for i = 1:size(Episodes, 1)
        for j = 1:size(Episodes, 2)
            episodeTitle = Episodes{i, j};
            if ~isempty(episodeTitle) && isKey(titleFrames, episodeTitle)
                categoryFrames(i) = categoryFrames(i) + sum(titleFrames(episodeTitle));
            elseif strcmp(episodeTitle, "NaN")
                % Omitir o manejar de manera diferente los títulos no válidos
                % categoryFrames(i) = categoryFrames(i) + valorPredeterminado;
            end
        end
    end

    % Determinar maxFrames para este animal
    maxFrames = max(categoryFrames);

    % Almacenar categoryFrames y maxFrames en la estructura global
    allCategoryFrames.(animal) = struct('CategoryFrames', categoryFrames, 'MaxFrames', maxFrames);
end

%%
% Table = Fluorescence;
% Variable = 'Flu';
% Pre_Frames = [];
% Post_Frames = [];
% [cat, TempTable]= F_MergeEpochs_lei(Table, 'Flu', Episodes, Cathegory, Task, ...
%     Pre_Frames, Post_Frames,maxFrames);
% 
% 
% SetZero = Pre_Frames;
% x_label = "Time (s)";
% y_label = "\DeltaF";
% close all
% Crear una tabla vacía para almacenar los resultados combinados

Pre_Frames = [];
Post_Frames = [];

% Obtener todos los valores de MaxFrames en allCategoryFrames
maxFramesValues = struct2cell(allCategoryFrames); % Convierte a celda
maxFramesValues = cellfun(@(x) x.MaxFrames, maxFramesValues); % Extrae los valores MaxFrames

% Encuentra la longitud máxima de 'Flu' entre todos los animales
maxLength = max(maxFramesValues);

% Preparar la tabla final
MergedTable = table([], [], [], [], 'VariableNames', {'Treatment', 'Animal', 'Flu', 'Cathegory'});

for a = 1:length(animals)
    animal = animals{a};
    
    % Extraer la fila correspondiente de Fluorescence para este animal
    AnimalTable = Fluorescence(Fluorescence.Animal == str2double(extractAfter(animal, 'M')), :);

    % Obtener la Task específica del animal
    AnimalTask = Experiment.SI.(animal).Task;
    Episodes = allEpisodes.(animal);
    
    % Depuración
    fprintf('Animal: %s\n', animal);
    disp('Episodes:');
    disp(Episodes);
    disp('Cathegory:');
    disp(Cathegory);
    
    % Aplicar F_MergeEpochs_lei para este animal
    [AnimalMerged, TempTable, ser] = F_MergeEpochs_lei(AnimalTable, 'Flu', Episodes, Cathegory, AnimalTask, [], [], maxLength);

    % Depuración
    disp('AnimalMerged:');
    disp(AnimalMerged);
    disp('Variables in AnimalMerged:');
    disp(AnimalMerged.Properties.VariableNames);
    
    % Verificar que las tablas tengan el mismo número de variables
    if width(MergedTable) ~= width(AnimalMerged)
        error('Mismatch in number of variables: MergedTable has %d, AnimalMerged has %d\n', width(MergedTable), width(AnimalMerged));
    end
    
    % Agregar los resultados a la tabla combinada
    MergedTable = [MergedTable; AnimalMerged];
    
    % Depuración
    disp('MergedTable after adding AnimalMerged:');
    disp(MergedTable);
end

disp('Final MergedTable:');
disp(MergedTable);


%%
% Pre-allocate para almacenar la media de cada fila
meanFluPerRow = nan(size(MergedTable, 1), 1);

% Iterar a través de cada fila para calcular la media, excluyendo NaN
for i = 1:size(MergedTable, 1)
    % Acceder directamente al vector de 'Flu' para la fila i
    currentFluVector = MergedTable.Flu(i, :); % Asegúrate de que esto corresponde a cómo están organizados tus datos
    % Calcular la media, excluyendo NaN
    meanFluPerRow(i) = nanmean(currentFluVector);
end
%%
%cambiar la variable cathegory de merged table
% Reemplazar 'ROI 1' con 'Close Arms' y 'ROI 2' con 'Open Arms' en la columna 'Cathegory'
MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 1', 'DOLL');
%MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 2', 'CLOSE ARMS');
MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 2', 'JUVENILE');
%MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 4', 'OPEN ARMS');
%MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'NO ROI', 'CENTER');

%%
% % Preparar la figura
% figure;
% hold on;
% 
% % Colores para las franjas y nombres de las categorías
% franjaColors = {'red', 'green', 'blue'};
% catNames = {'NO ROI', 'ROI 1', 'ROI 2'};
% 
% % Inicializar variables para los límites de las franjas
% franjaStart = 1;
% franjaEnds = zeros(1, length(catNames));
% franjaHandles = gobjects(length(catNames), 1);  % Array para guardar las manijas de las franjas
% 
% % Graficar los datos de fluorescencia y dibujar las franjas
% for i = 1:height(cat)
%     % Extraer y graficar los datos de fluorescencia no NaN
%     catData = cat.Flu(i, :);
%     validData = catData(~isnan(catData));  % Datos no NaN
%     validLength = length(validData);  % Longitud de los datos no NaN
%     franjaEnds(i) = franjaStart + validLength - 1;
%     plot(franjaStart:franjaEnds(i), validData, 'Color', 'black');
% 
%     % Dibujar la franja de fondo y guardar la manija
%     h = fill([franjaStart, franjaEnds(i), franjaEnds(i), franjaStart], ...
%          [min(cat.Flu(:)), min(cat.Flu(:)), max(cat.Flu(:)), max(cat.Flu(:))], ...
%          franjaColors{i}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
%     franjaHandles(i) = h;  % Guardar la manija para la leyenda
% 
%     % Actualizar el inicio para la próxima franja
%     franjaStart = franjaEnds(i) + 1;
% end
% 
% % Ajustes finales del gráfico
% xlabel('Frames');
% ylabel('Fluorescencia');
% legend(franjaHandles, catNames, 'Location', 'northeastoutside');  % Crear leyenda solo para las franjas
% hold off;
% Inicializar colores y nombres de categorías
% Inicializar colores y nombres de categorías
% Inicializar colores y nombres de categorías
% Inicializar colores y nombres de categorías
franjaColors = {'red', 'green', 'blue'};
catNames = {'CENTER', 'CLOSE ARMS', 'OPEN ARMS'};

% Número de animales (basado en el número único de 'Animal' en MergedTable)
numAnimals = max(MergedTable.Animal);

% Iterar sobre cada animal
for a = 1:numAnimals
    % Seleccionar los datos de este animal
    AnimalData = MergedTable(MergedTable.Animal == a, :);

    % Preparar la figura para este animal
    figure;
    hold on;
    %title(strcat('Fluorescencia Animal ', num2str(a)));

    % Inicializar variables para los límites de las franjas
    franjaStart = 1;
    
    % Array para almacenar los manejadores de las franjas para la leyenda
    franjaHandles = [];

    % Graficar los datos de fluorescencia y dibujar las franjas
    for i = 1:length(catNames)
        categoria = catNames{i};
        % Extraer y graficar los datos de fluorescencia para esta categoría
        catData = AnimalData.Flu(strcmp(AnimalData.Cathegory, categoria), :);
        
        % Eliminar NaN para graficar correctamente
        validData = catData(~isnan(catData));
        validLength = length(validData);

        if ~isempty(validData)
            plot(franjaStart:(franjaStart + validLength - 1), validData, 'Color', 'black', 'HandleVisibility', 'off');

            % Dibujar la franja de fondo
            franjaEnds = franjaStart + validLength - 1;
            h = fill([franjaStart, franjaEnds, franjaEnds, franjaStart], ...
                 [min(AnimalData.Flu(:)), min(AnimalData.Flu(:)), max(AnimalData.Flu(:)), max(AnimalData.Flu(:))], ...
                 franjaColors{i}, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            franjaHandles = [franjaHandles, h]; % Agregar el manejador a la lista

            % Actualizar el inicio para la próxima franja
            franjaStart = franjaEnds + 1;
        end
    end

    % Ajustes finales del gráfico
    xlabel('Frame');
    ylabel('Fluorescence');
    legend(franjaHandles, catNames, 'Location', 'northeastoutside'); % Usar los manejadores de las franjas para la leyenda
    hold off;
end
%%
% Calcular la media y el error estándar de la media (SEM) para la fluorescencia de cada categoría
% means = zeros(1, height(cat));
% errors = zeros(1, height(cat));
% 
% for i = 1:height(cat)
%     % Obtener datos de fluorescencia no-NaN para la categoría actual
%     validData = cat.Flu(i, ~isnan(cat.Flu(i, :)));
% 
%     % Calcular la media y el error estándar (SEM)
%     means(i) = mean(validData);
%     errors(i) = std(validData) / sqrt(length(validData));
% end
% 
% % Crear el gráfico de barras
% figure;
% b = bar(means, 'FaceColor', 'flat');
% 
% % Asegurarse de que el color de las barras es visible y diferenciado
% b.CData(1,:) = [1 0 0]; % Rojo para NO ROI
% b.CData(2,:) = [0 1 0]; % Verde para ROI 1
% b.CData(3,:) = [0 0 1]; % Azul para ROI 2
% 
% hold on;
% % Agregar las barras de error
% errorbar(1:length(means), means, errors, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
% 
% % Establecer los nombres de las categorías como etiquetas del eje X
% set(gca, 'xtick', 1:length(means), 'xticklabel', catNames);
% 
% % Ajustes finales del gráfico
% xlabel('Categoría');
% ylabel('Fluorescencia Media');
% title('Fluorescencia Media por Categoría con Barras de Error');
% hold off;
% Inicializar las variables para las medias y los errores
% means = zeros(1, length(catNames));
% errors = zeros(1, length(catNames));
% 
% % Iterar sobre cada categoría
% for i = 1:length(catNames)
%     categoria = catNames{i};
% 
%     % Recopilar datos de fluorescencia de todos los animales para esta categoría
%     catData = MergedTable.Flu(strcmp(MergedTable.Cathegory, categoria), :);
%     validData = catData(~isnan(catData)); % Eliminar NaN
% 
%     % Calcular la media y el SEM
%     means(i) = mean(validData)
%     errors(i) = std(validData) / sqrt(length(validData));
% end
% 
% % Crear el gráfico de barras
% figure;
% b = bar(means, 'FaceColor', 'flat');
% 
% % Configurar los colores de las barras
% b.CData(1,:) = [1 0 0]; % Rojo para NO ROI
% b.CData(2,:) = [0 1 0]; % Verde para ROI 1
% b.CData(3,:) = [0 0 1]; % Azul para ROI 2
% 
% hold on;
% % Agregar las barras de error
% errorbar(1:length(means), means, errors, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
% 
% % Establecer los nombres de las categorías como etiquetas del eje X
% set(gca, 'xtick', 1:length(means), 'xticklabel', catNames);
% 
% % Ajustes finales del gráfico
% xlabel('Zone');
% ylabel('Mean Fluorescence');
% % title('Fluorescencia Media por Categoría con Barras de Error');
% hold off;
% Paso 2: Calcular medias y SEM por categoría y sexo
categories = unique(MergedTable.Cathegory);
sexes = unique(MergedTable.Treatment);
numCategories = length(categories);
numSexes = length(sexes);
combinedDataTable_center = table();
means = zeros(numCategories, numSexes);
errors = zeros(numCategories, numSexes);

% Preparar datos para el gráfico
for i = 1:numCategories
    for j = 1:numSexes
        % Filtrar datos por categoría y sexo
        filteredData = MergedTable.Flu(strcmp(MergedTable.Cathegory, categories{i}) & strcmp(MergedTable.Treatment, sexes{j}), :);
        validData = filteredData(~isnan(filteredData)); % Eliminar NaN
        
        % Calcular la media y SEM
        means(i, j) = mean(validData);
        errors(i, j) = std(validData) / sqrt(length(validData));
        tempTable = table(repmat(categories(i), length(validData), 1), ...
                  repmat(sexes(j), length(validData), 1), ...
                  validData, ...  % Transponer validData para convertirlo en columna
                  'VariableNames', {'Category', 'Treatment', 'Fluorescence'});
        combinedDataTable_center = [combinedDataTable_center; tempTable];
    end
end
% Guardar la tabla combinada como CSV
writetable(combinedDataTable_center, 'CombinedValidData_center.csv');

% Paso 3: Crear el gráfico de barras agrupadas
figure;
b = bar(means, 'grouped');
hold on;

% Colores deseados para cada sexo
colors = [0 0.2941 0.2941; 0.9608 0.6784 0.3216]; % Colores para cada sexo

% Configurar colores de las barras por sexo
for i = 1:length(b) % Iterar sobre cada grupo de sexo
    b(i).FaceColor = 'flat'; % Establecer 'FaceColor' a 'flat' para permitir colores individuales
    b(i).CData = repmat(colors(i,:), size(b(i).CData, 1), 1); % Aplicar el color a todo el grupo
end


% Agregar las barras de error
for i = 1:numCategories
    for j = 1:numSexes
        x = b(j).XEndPoints(i);
        errorbar(x, means(i, j), errors(i, j), 'k', 'LineStyle', 'none', 'LineWidth', 1.5);
    end
end

% Ajustes finales del gráfico
set(gca, 'xtick', 1:numCategories, 'xticklabel', categories);
legend(sexes, 'Location', 'northeastoutside');
xlabel('Zone');
ylabel('Mean Fluorescence');

hold off;

%%
%cambiar la variable cathegory de merged table
% Reemplazar 'ROI 1' con 'Close Arms' y 'ROI 2' con 'Open Arms' en la columna 'Cathegory'
MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 1', ' CENTER');
MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'ROI 2', 'PERIPHERY');
%MergedTable.Cathegory = strrep(MergedTable.Cathegory, 'NO ROI', 'CENTER');


% Mostrar la tabla modificada
disp(MergedTable);
%%
% Aplanar la tabla MergedTable para que pueda ser exportada a un archivo Excel
flattenedTable = table();
for i = 1:height(MergedTable)
    % Obtener los datos de fluorescencia
    fluData = MergedTable.Flu(i,:);
    numDataPoints = length(fluData);
    
    % Crear una tabla temporal con los datos repetidos y aplanados
    tempTable = table(repmat(MergedTable.Treatment(i), 1, numDataPoints)', ...
                      repmat(MergedTable.Animal(i), 1, numDataPoints)', ...
                      repmat(MergedTable.Cathegory(i), 1, numDataPoints)', ...
                      fluData(:), ...
                      'VariableNames', {'Treatment', 'Animal', 'Cathegory', 'Fluorescence'});
    
    % Concatenar la tabla temporal con la tabla aplanada
    flattenedTable = [flattenedTable; tempTable];
end

% Guardar la tabla aplanada como un archivo Excel
filename = 'MergedTable_Flattened.xlsx';
writetable(flattenedTable, filename, 'WriteVariableNames', true);

%% SIN NO ROI

categories = unique(MergedTable.Cathegory);
sexes = unique(MergedTable.Treatment);

% Excluir 'CENTER' de las categorías
categories = categories(~strcmp(categories, 'NO ROI'));
% categories = categories(~strcmp(categories, 'CLOSE ARMS'));

numCategories = length(categories);
numSexes = length(sexes);

means = zeros(numCategories, numSexes);
errors = zeros(numCategories, numSexes);

combinedDataTable = table();
AnimalMeansTable = table();  % Tabla para almacenar las medias por animal

% Preparar datos para el gráfico
for i = 1:numCategories
    for j = 1:numSexes
        % Filtrar datos por categoría y sexo
        filteredData = MergedTable(strcmp(MergedTable.Cathegory, categories{i}) & strcmp(MergedTable.Treatment, sexes{j}), :);
        
        % Calcular la media de fluorescencia por animal
        uniqueAnimals = unique(filteredData.Animal);
        animalMeans = arrayfun(@(x) mean(filteredData.Flu(filteredData.Animal == x, :), 'all', 'omitnan'), uniqueAnimals);
        
        % Calcular la media y SEM para este grupo y categoría
        means(i, j) = mean(animalMeans, 'omitnan');
        errors(i, j) = std(animalMeans, 'omitnan') / sqrt(length(animalMeans));
        
        % Crear una tabla temporal con las medias por animal
        tempTable = table(repmat(categories(i), length(animalMeans), 1), ...
                          repmat(sexes(j), length(animalMeans), 1), ...
                          uniqueAnimals, ...
                          animalMeans, ...  % Medias por animal
                          'VariableNames', {'Category', 'Treatment', 'Animal', 'MeanFluorescence'});
        AnimalMeansTable = [AnimalMeansTable; tempTable];
        
        % Añadir los datos válidos a la tabla combinada con la categoría y el tratamiento correspondientes
        combinedTempTable = table(repmat(categories(i), length(animalMeans), 1), ...
                                  repmat(sexes(j), length(animalMeans), 1), ...
                                  animalMeans, ...  % Medias por animal
                                  'VariableNames', {'Category', 'Treatment', 'Fluorescence'});
        combinedDataTable = [combinedDataTable; combinedTempTable];
    end
end

% Guardar las tablas como CSV
writetable(combinedDataTable, 'CombinedValidData.csv');
writetable(AnimalMeansTable, 'AnimalMeansTable.csv');

% Crear el gráfico de barras agrupadas
figure;
b = bar(means, 'grouped');
hold on;

% Colores deseados para cada sexo
colors = [0.341, 0.341, 0.976; 0.784, 0.871, 0.976]; % Colores para cada grupo

% Configurar colores de las barras por sexo
for i = 1:length(b) % Iterar sobre cada grupo de sexo
    b(i).FaceColor = 'flat'; % Establecer 'FaceColor' a 'flat' para permitir colores individuales
    b(i).CData = repmat(colors(i,:), size(b(i).CData, 1), 1); % Aplicar el color a todo el grupo
end

% Agregar las barras de error
for i = 1:numCategories
    for j = 1:numSexes
        x = b(j).XEndPoints(i);
        errorbar(x, means(i, j), errors(i, j), 'k', 'capsize', 10, 'LineStyle', 'none', 'LineWidth', 1.5);
    end
end

% Ajustes finales del gráfico
set(gca, 'xtick', 1:numCategories, 'xticklabel', categories);
legend(sexes, 'Location', 'northeastoutside');
xlabel('Zone');
ylabel('Mean Fluorescence');
hold off;


%%

% AUC_per_title = containers.Map();
% 
% % Iterar a través de cada animal
% animals = fieldnames(Experiment.EPM);
% for animalIndex = 1:length(animals)
%     animalName = animals{animalIndex}; % Nombre del animal actual
%     animalData = Experiment.EPM.(animalName); % Datos del animal actual
% 
%     % Obtener los títulos y el número total de títulos para este animal
%     Titles = animalData.Task.Titles;
%     numTitles = length(Titles);
% 
%     % Obtener el número de neuronas para este animal
%     numNeurons = size(animalData.Filt, 1);
% 
%     % Calcular el AUC para cada título para este animal
%     for i = 1:numTitles
%         title = Titles{i}; % Nombre del título actual
%         startFrame = animalData.Task.Start(i); % Inicio del frame para este título
%         endFrame = animalData.Task.End(i); % Fin del frame para este título
% 
%         % Inicializar una matriz para almacenar AUC de todas las neuronas para este título
%         AUC_values = zeros(1, numNeurons);
% 
%         % Sumar el AUC para cada neurona para este título
%         for neurona = 1:numNeurons
%             % Extraer la señal de fluorescencia para esta neurona y calcular el AUC
%             signal = animalData.Filt(neurona, startFrame:endFrame);
%             AUC_values(neurona) = trapz(signal);
%         end
% 
%         % Calcular el AUC total (sumando sobre todas las neuronas) para este título
%         total_AUC = sum(AUC_values)
% 
%         % Crear una clave única que combine el nombre del animal y el título
%         key = sprintf('%s - %s', animalName, title);
% 
%         % Guardar el AUC total en el mapa con la clave única
%         AUC_per_title(key) = total_AUC;
%     end
% end
% 
% % Mostrar los resultados
% disp(AUC_per_title);
AUC_per_title = containers.Map();
animalNames = fieldnames(Experiment.EPM); % Nombres de los animales
groups = Experiment.Project.Groups; % Grupos a los que pertenecen los animales

% Asegurarse de que el número de animales y grupos coinciden
assert(numel(animalNames) == numel(groups), 'El número de animales y grupos debe coincidir.');

% Iterar a través de cada animal
for animalIndex = 1:length(animalNames)
    animalName = animalNames{animalIndex}; % Nombre del animal actual
    animalData = Experiment.EPM.(animalName); % Datos del animal actual
    animalGroup = groups(animalIndex); % Grupo del animal actual

    % Obtener los títulos y el número total de títulos para este animal
    Titles = animalData.Task.Titles;
    numTitles = length(Titles);
    
    % Obtener el número de neuronas para este animal
    numNeurons = size(animalData.Filt, 1);
    
    % Calcular el AUC para cada título para este animal
    for i = 1:numTitles
        title = Titles{i}; % Nombre del título actual
        startFrame = animalData.Task.Start(i); % Inicio del frame para este título
        endFrame = animalData.Task.End(i); % Fin del frame para este título
        
        % Inicializar una matriz para almacenar AUC de todas las neuronas para este título
        AUC_values = zeros(1, numNeurons);
        
        % Sumar el AUC para cada neurona para este título
        for neurona = 1:numNeurons
            % Extraer la señal de fluorescencia para esta neurona y calcular el AUC
            signal = animalData.Filt(neurona, startFrame:endFrame);
            AUC_values(neurona) = trapz(signal);
        end
        
        % Calcular el AUC total (sumando sobre todas las neuronas) para este título
        total_AUC = sum(AUC_values);
        
        % Crear una clave única que combine el nombre del animal, el título y el grupo
        key = sprintf('%s - %s - %s', animalName, title, animalGroup);
        
        % Guardar el AUC total en el mapa con la clave única
        AUC_per_title(key) = total_AUC;
    end
end

% Mostrar los resultados
disp(AUC_per_title);
%%
% AUC_sum = containers.Map();
% total_frames = containers.Map();
% 
% % Recorrer cada animal en Experiment.EPM
% animales = fieldnames(Experiment.EPM);
% for i = 1:length(animales)
%     animal = animales{i};
%     Task = Experiment.EPM.(animal).Task;
% 
%     % Recorrer cada título para este animal
%     for j = 1:length(Task.Titles)
%         titulo = Task.Titles{j};
%         key = sprintf('%s - %s', animal, titulo) % Clave para AUC_per_title
% 
%         % Identificar la categoría del título (asumiendo que cualquier cosa antes del guión bajo es la categoría)
%         categoria = regexp(titulo, '^[^_]+', 'match', 'once');
% 
%         % Comprobar si la clave existe en AUC_per_title
%         if isKey(AUC_per_title, key)
%             % Si la categoría es nueva para este animal, inicializarla
%             if ~isKey(AUC_sum, categoria)
%                 AUC_sum(categoria) = 0;
%                 total_frames(categoria) = 0;
%             end
% 
%             % Sumar el AUC para la categoría
%             AUC_sum(categoria) = AUC_sum(categoria) + AUC_per_title(key);
% 
%             % Sumar los frames para la categoría
%             total_frames(categoria) = total_frames(categoria) + Task.Frames(j);
%         end
%     end
% end
% 
% % Calcular el promedio de AUC por frame para cada categoría
% AUC_avg_per_frame = containers.Map();
% categorias = keys(AUC_sum);
% for k = 1:length(categorias)
%     categoria = categorias{k};
%     AUC_avg_per_frame(categoria) = AUC_sum(categoria) / total_frames(categoria);
% end
% 
% % Mostrar los resultados
% disp('Promedio de AUC por frame para cada categoría:');
% for categoria = keys(AUC_avg_per_frame)
%     fprintf('%s: %f\n', categoria{1}, AUC_avg_per_frame(categoria{1}));
% end
% Inicializar contenedores para guardar la suma de AUC, el total de frames y el número total de neuronas por categoría y grupo
% Inicializar contenedores para guardar la suma de AUC, el total de frames y el número total de neuronas por categoría y grupo
AUC_sum_group_category = containers.Map();
total_frames_group_category = containers.Map();
total_neurons_group_category = containers.Map();

% Recorrer cada animal en Experiment.EPM
animals = fieldnames(Experiment.EPM);
groups = Experiment.Project.Groups; % Información de grupo para cada animal

for i = 1:length(animals)
    animal = animals{i};
    Task = Experiment.EPM.(animal).Task;
    group = groups(i); % Grupo correspondiente al animal

    % Depuración: Mostrar el animal y su grupo
    disp(['Procesando animal: ', animal, ' en el grupo: ', char(group)]);

    % Recorrer cada título para este animal
    for j = 1:length(Task.Titles)
        titulo = Task.Titles{j};
        % Clave ajustada para coincidir con AUC_per_title
        key = sprintf('%s - %s - %s', animal, titulo, char(group)); 

        % Depuración: Mostrar la clave generada
        disp(['Clave generada: ', key]);

        % Identificar la categoría del título
        categoria = regexp(titulo, '^[^_]+', 'match', 'once');
        category_group_key = sprintf('%s - %s', char(group), categoria); % Clave por categoría y grupo

        % Depuración: Mostrar la categoría y el grupo
        disp(['Categoría: ', categoria, ', Grupo: ', char(group), ' - Clave combinada: ', category_group_key]);

        % Comprobar si la clave existe en AUC_per_title
        if isKey(AUC_per_title, key)
            % Inicializar contenedores si es necesario
            if ~isKey(AUC_sum_group_category, category_group_key)
                AUC_sum_group_category(category_group_key) = 0;
                total_frames_group_category(category_group_key) = 0;
                total_neurons_group_category(category_group_key) = 0;
            end
            
            % Depuración: Confirmación de clave encontrada
            disp(['Clave encontrada en AUC_per_title: ', key]);

            % Sumar el AUC para la categoría y grupo
            AUC_sum_group_category(category_group_key) = AUC_sum_group_category(category_group_key) + AUC_per_title(key);
            
            % Sumar los frames para la categoría y grupo
            total_frames_group_category(category_group_key) = total_frames_group_category(category_group_key) + Task.Frames(j);
            
            % Sumar las neuronas para la categoría y grupo
            total_neurons_group_category(category_group_key) = total_neurons_group_category(category_group_key) + size(Experiment.EPM.(animal).Filt, 1);
        else
            % Depuración: Clave no encontrada
            disp(['Clave NO encontrada en AUC_per_title: ', key]);
        end
    end
end

% Calcular el promedio de AUC por frame y por neurona para cada categoría y grupo
AUC_avg_per_frame_neuron = containers.Map();
category_group_keys = keys(AUC_sum_group_category);

for key = category_group_keys
    total_AUC = AUC_sum_group_category(key{1});
    total_frames = total_frames_group_category(key{1});
    total_neurons = total_neurons_group_category(key{1});
    AUC_avg_per_frame_neuron(key{1}) = total_AUC / (total_frames * total_neurons);
end

% Mostrar los resultados
disp('Promedio de AUC por frame y por neurona para cada categoría y grupo:');
for key = keys(AUC_avg_per_frame_neuron)
    fprintf('%s: %f\n', key{1}, AUC_avg_per_frame_neuron(key{1}));
end

%%
% % Crear un vector para los valores de AUC promedio
% valores_auc = cell2mat(values(AUC_avg_per_frame));
% 
% % Crear un vector con las etiquetas de las categorías
% categorias_originales = keys(AUC_avg_per_frame);
% categorias_nuevas = replace(categorias_originales, {'NO', 'ROI1', 'ROI2'}, {'NO ROI', 'ROI 1', 'ROI 2'});
% 
% % Crear el gráfico de barras
% figure;
% bar(valores_auc);
% 
% % Ajustar las etiquetas del eje X
% set(gca, 'xtick', 1:length(categorias_nuevas), 'xticklabel', categorias_nuevas);
% 
% % Añadir etiquetas y título
% xlabel('Zone');
% ylabel('Average AUC');
% %title('AUC Promedio por Frame para cada Categoría');
% 
% % Mostrar el gráfico
% grid on;
% Crear vectores para los valores de AUC promedio y las etiquetas
% valores_auc = cell2mat(values(AUC_avg_per_frame_neuron));
% etiquetas = keys(AUC_avg_per_frame_neuron);
% 
% % Preparar las etiquetas para el gráfico, incluyendo la información del grupo y la categoría
% categorias_nuevas = cellfun(@(etiqueta) replace(etiqueta, {'NO', 'ROI1', 'ROI2'}, {'NO ROI', 'ROI 1', 'ROI 2'}), etiquetas, 'UniformOutput', false);
% 
% % Crear el gráfico de barras
% figure;
% bar(valores_auc);
% 
% % Ajustar las etiquetas del eje X para mostrar tanto la categoría como el grupo
% set(gca, 'xtick', 1:length(categorias_nuevas), 'xticklabel', categorias_nuevas, 'XTickLabelRotation', 45);
% 
% % Añadir etiquetas y título
% xlabel('Categoría y Grupo');
% ylabel('AUC Promedio por Frame y Neurona');
% title('AUC Promedio por Frame y por Neurona para cada Categoría y Grupo');
% 
% % Mejorar la presentación
% grid on;
% legend('Categorías', 'Location', 'best');
% Separar las claves en grupos y categorías
categorias_keys =keys(AUC_avg_per_frame_neuron);
auc_values = cell2mat(values(AUC_avg_per_frame_neuron));

grupos = unique(regexprep(categorias_keys, ' - .*', '')); % Extraer nombres de grupos
categorias = unique(regexprep(categorias_keys, '.* - ', '')); % Extraer nombres de categorías

% Inicializar matriz de datos para el gráfico
data_matriz = zeros(numel(categorias), numel(grupos));

% Rellenar la matriz con los valores de AUC
for i = 1:numel(categorias_keys)
    [grupo, categoria] = strtok(categorias_keys{i}, ' - ');
    categoria = strrep(categoria, ' - ', '');
    grupo_idx = find(strcmp(grupos, grupo));
    categoria_idx = find(strcmp(categorias, categoria));
    data_matriz(categoria_idx, grupo_idx) = auc_values(i);
end

% Crear el gráfico de barras agrupado
bar_handle = bar(data_matriz, 'grouped');

% Ajustar las etiquetas del eje X
set(gca, 'xticklabel', categorias);

% Añadir leyenda
legend(grupos);

% Añadir etiquetas y título
xlabel('Categoría');
ylabel('AUC Promedio por Frame y por Neurona');


% Mostrar el gráfico
grid on;
%% Sin no roi
% Separar las claves en grupos y categorías y filtrar 'NO'
categorias_keys = keys(AUC_avg_per_frame_neuron);
auc_values = cell2mat(values(AUC_avg_per_frame_neuron));

% Filtrar para excluir las claves que contienen 'NO'
filt_keys = categorias_keys(~contains(categorias_keys, 'NO'));
filt_auc_values = auc_values(~contains(categorias_keys, 'NO'));

% Reemplazar 'ROI1' con 'Close Arms' y 'ROI2' con 'Open Arms'
filt_keys = strrep(filt_keys, 'ROI1', 'Center');
filt_keys = strrep(filt_keys, 'ROI2', 'Peripheria');

grupos = unique(regexprep(filt_keys, ' - .*', '')); % Extraer nombres de grupos
categorias = {'Center', 'Peripheria'}; % Definir manualmente las categorías

% Inicializar matriz de datos para el gráfico
data_matriz = zeros(numel(categorias), numel(grupos));

% Rellenar la matriz con los valores de AUC filtrados
for i = 1:numel(filt_keys)
    [grupo, categoria] = strtok(filt_keys{i}, ' - ');
    categoria = strrep(categoria, ' - ', '');
    grupo_idx = find(strcmp(grupos, grupo));
    categoria_idx = find(strcmp(categorias, categoria));
    data_matriz(categoria_idx, grupo_idx) = filt_auc_values(i);
end

% Crear el gráfico de barras agrupado
figure;
bar_handle = bar(data_matriz, 'grouped');

% Ajustar las etiquetas del eje X
set(gca, 'xticklabel', categorias);

% Añadir leyenda
legend(grupos);

% Añadir etiquetas y título
xlabel('Zone');
ylabel('Avg AUC');

% Mejorar la presentación
grid on;
%%
% % Paso 1: Inicializar contenedores para AUC por grupo y categoría
% AUC_by_group_and_category = struct();
% 
% % Paso 2: Calcular AUC por título para cada animal y agrupar por categoría y sexo
% for animalIndex = 1:numel(animals)
%     animalName = animals{animalIndex};
%     group = Experiment.Project.Groups(animalIndex); % Suponiendo que el índice de 'animals' y 'Groups' se corresponden
%     animalData = Experiment.EPM.(animalName);
%     Titles = animalData.Task.Titles;
%     numTitles = length(Titles);
% 
%     for i = 1:numTitles
%         title = Titles{i};
%         categoria = regexp(title, '^(NO_ROI|ROI\d+)', 'match', 'once'); % Extraer categoría del título
%         if isempty(categoria)
%             continue; % Si no se encuentra categoría, continuar con el siguiente título
%         end
%         startFrame = animalData.Task.Start(i);
%         endFrame = animalData.Task.End(i);
%         signal = animalData.Filt(:, startFrame:endFrame);
%         AUC = trapz(signal, 2); % Calcular AUC para cada neurona y sumar
%         total_AUC = sum(AUC);
% 
%         % Agregar AUC al contenedor, agrupado por grupo y categoría
%         if ~isfield(AUC_by_group_and_category, group)
%             AUC_by_group_and_category.(group) = containers.Map();
%         end
%         if ~isKey(AUC_by_group_and_category.(group), categoria)
%             AUC_by_group_and_category.(group)(categoria) = [];
%         end
%         AUC_by_group_and_category.(group)(categoria) = [AUC_by_group_and_category.(group)(categoria), total_AUC];
%     end
% end
% 
% % Paso 3: Preparar datos para el gráfico
% categories = ["NO ROI", "ROI 1", "ROI 2"]; % Ajustar según las categorías reales
% groups = fieldnames(AUC_by_group_and_category);
% AUC_means = zeros(numel(categories), numel(groups));
% AUC_sems = zeros(numel(categories), numel(groups));
% 
% for g = 1:numel(groups)
%     group = groups{g};
%     for c = 1:numel(categories)
%         categoria = categories(c);
%         if isKey(AUC_by_group_and_category.(group), categoria)
%             AUCs = AUC_by_group_and_category.(group)(categoria);
%             AUC_means(c, g) = mean(AUCs);
%             AUC_sems(c, g) = std(AUCs) / sqrt(numel(AUCs));
%         end
%     end
% end
% 
% % Paso 4: Generar el gráfico de barras agrupadas
% figure;
% b = bar(AUC_means, 'grouped');
% hold on;
% 
% % Agregar barras de error
% for i = 1:numel(b)
%     x = b(i).XEndPoints;
%     errorbar(x, AUC_means(:, i), AUC_sems(:, i), 'k', 'linestyle', 'none');
% end
% 
% % Ajustes finales del gráfico
% set(gca, 'xtick', 1:numel(categories), 'xticklabel', categories);
% legend(groups, 'Location', 'northeastoutside');
% xlabel('Category');
% ylabel('Average AUC');
% 
% hold off;

%%

%Fuorescencia neurona a neurona
FLU_per_title = containers.Map();
animalNames = fieldnames(Experiment.EPM); % Nombres de los animales
groups = Experiment.Project.Groups; % Grupos a los que pertenecen los animales

% Asegurarse de que el número de animales y grupos coinciden
assert(numel(animalNames) == numel(groups), 'El número de animales y grupos debe coincidir.');

% Iterar a través de cada animal
for animalIndex = 1:length(animalNames)
    animalName = animalNames{animalIndex}; % Nombre del animal actual
    animalData = Experiment.EPM.(animalName); % Datos del animal actual
    animalGroup = groups(animalIndex); % Grupo del animal actual

    % Obtener los títulos y el número total de títulos para este animal
    Titles = animalData.Task.Titles;
    numTitles = length(Titles);
    
    % Obtener el número de neuronas para este animal
    numNeurons = size(animalData.Filt, 1);
    
    % Calcular el AUC para cada título para este animal
    for i = 1:numTitles
        title = Titles{i}; % Nombre del título actual
        startFrame = animalData.Task.Start(i); % Inicio del frame para este título
        endFrame = animalData.Task.End(i); % Fin del frame para este título
        
        % Inicializar una matriz para almacenar AUC de todas las neuronas para este título
        FLU_values = zeros(1, numNeurons);
        
        % Sumar el AUC para cada neurona para este título
        for neurona = 1:numNeurons
            % Extraer la señal de fluorescencia para esta neurona y calcular el AUC
            signal = animalData.Filt(neurona, startFrame:endFrame);
            FLU_values(neurona) = mean(signal);
        end
        
        % Calcular el AUC total (sumando sobre todas las neuronas) para este título
        total_FLU = sum(FLU_values);
        
        % Crear una clave única que combine el nombre del animal, el título y el grupo
        key = sprintf('%s - %s - %s', animalName, title, animalGroup);
        
        % Guardar el AUC total en el mapa con la clave única
        FLU_per_title(key) = total_FLU;
    end
end

% Mostrar los resultados
disp(FLU_per_title);
%%
% AUC_sum = containers.Map();
% total_frames = containers.Map();
% 
% % Recorrer cada animal en Experiment.EPM
% animales = fieldnames(Experiment.EPM);
% for i = 1:length(animales)
%     animal = animales{i};
%     Task = Experiment.EPM.(animal).Task;
% 
%     % Recorrer cada título para este animal
%     for j = 1:length(Task.Titles)
%         titulo = Task.Titles{j};
%         key = sprintf('%s - %s', animal, titulo) % Clave para AUC_per_title
% 
%         % Identificar la categoría del título (asumiendo que cualquier cosa antes del guión bajo es la categoría)
%         categoria = regexp(titulo, '^[^_]+', 'match', 'once');
% 
%         % Comprobar si la clave existe en AUC_per_title
%         if isKey(AUC_per_title, key)
%             % Si la categoría es nueva para este animal, inicializarla
%             if ~isKey(AUC_sum, categoria)
%                 AUC_sum(categoria) = 0;
%                 total_frames(categoria) = 0;
%             end
% 
%             % Sumar el AUC para la categoría
%             AUC_sum(categoria) = AUC_sum(categoria) + AUC_per_title(key);
% 
%             % Sumar los frames para la categoría
%             total_frames(categoria) = total_frames(categoria) + Task.Frames(j);
%         end
%     end
% end
% 
% % Calcular el promedio de AUC por frame para cada categoría
% AUC_avg_per_frame = containers.Map();
% categorias = keys(AUC_sum);
% for k = 1:length(categorias)
%     categoria = categorias{k};
%     AUC_avg_per_frame(categoria) = AUC_sum(categoria) / total_frames(categoria);
% end
% 
% % Mostrar los resultados
% disp('Promedio de AUC por frame para cada categoría:');
% for categoria = keys(AUC_avg_per_frame)
%     fprintf('%s: %f\n', categoria{1}, AUC_avg_per_frame(categoria{1}));
% end
% Inicializar contenedores para guardar la suma de AUC, el total de frames y el número total de neuronas por categoría y grupo
% Inicializar contenedores para guardar la suma de AUC, el total de frames y el número total de neuronas por categoría y grupo
FLU_sum_group_category = containers.Map();
total_frames_group_category = containers.Map();
total_neurons_group_category = containers.Map();

% Recorrer cada animal en Experiment.EPM
animals = fieldnames(Experiment.EPM);
groups = Experiment.Project.Groups; % Información de grupo para cada animal

for i = 1:length(animals)
    animal = animals{i};
    Task = Experiment.EPM.(animal).Task;
    group = groups(i); % Grupo correspondiente al animal

    % Depuración: Mostrar el animal y su grupo
    disp(['Procesando animal: ', animal, ' en el grupo: ', char(group)]);

    % Recorrer cada título para este animal
    for j = 1:length(Task.Titles)
        titulo = Task.Titles{j};
        % Clave ajustada para coincidir con AUC_per_title
        key = sprintf('%s - %s - %s', animal, titulo, char(group)); 

        % Depuración: Mostrar la clave generada
        disp(['Clave generada: ', key]);

        % Identificar la categoría del título
        categoria = regexp(titulo, '^[^_]+', 'match', 'once');
        category_group_key = sprintf('%s - %s', char(group), categoria); % Clave por categoría y grupo

        % Depuración: Mostrar la categoría y el grupo
        disp(['Categoría: ', categoria, ', Grupo: ', char(group), ' - Clave combinada: ', category_group_key]);

        % Comprobar si la clave existe en AUC_per_title
        if isKey(FLU_per_title, key)
            % Inicializar contenedores si es necesario
            if ~isKey(FLU_sum_group_category, category_group_key)
                FLU_sum_group_category(category_group_key) = 0;
                total_frames_group_category(category_group_key) = 0;
                total_neurons_group_category(category_group_key) = 0;
            end
            
            % Depuración: Confirmación de clave encontrada
            disp(['Clave encontrada en AUC_per_title: ', key]);

            % Sumar el AUC para la categoría y grupo
            FLU_sum_group_category(category_group_key) = FLU_sum_group_category(category_group_key) + FLU_per_title(key);
            
            % Sumar los frames para la categoría y grupo
            total_frames_group_category(category_group_key) = total_frames_group_category(category_group_key) + Task.Frames(j);
            
            % Sumar las neuronas para la categoría y grupo
            total_neurons_group_category(category_group_key) = total_neurons_group_category(category_group_key) + size(Experiment.EPM.(animal).Filt, 1);
        else
            % Depuración: Clave no encontrada
            disp(['Clave NO encontrada en FLU_per_title: ', key]);
        end
    end
end

% Calcular el promedio de AUC por frame y por neurona para cada categoría y grupo
FLU_avg_per_frame_neuron = containers.Map();
category_group_keys = keys(FLU_sum_group_category);

for key = category_group_keys
    total_FLU = FLU_sum_group_category(key{1});
    total_frames = total_frames_group_category(key{1});
    total_neurons = total_neurons_group_category(key{1});
    FLU_avg_per_frame_neuron(key{1}) = total_FLU / (total_frames * total_neurons);
end

% Mostrar los resultados
disp('Promedio de FLU por frame y por neurona para cada categoría y grupo:');
for key = keys(FLU_avg_per_frame_neuron)
    fprintf('%s: %f\n', key{1}, FLU_avg_per_frame_neuron(key{1}));
end

%%
% % Crear un vector para los valores de AUC promedio
% valores_auc = cell2mat(values(AUC_avg_per_frame));
% 
% % Crear un vector con las etiquetas de las categorías
% categorias_originales = keys(AUC_avg_per_frame);
% categorias_nuevas = replace(categorias_originales, {'NO', 'ROI1', 'ROI2'}, {'NO ROI', 'ROI 1', 'ROI 2'});
% 
% % Crear el gráfico de barras
% figure;
% bar(valores_auc);
% 
% % Ajustar las etiquetas del eje X
% set(gca, 'xtick', 1:length(categorias_nuevas), 'xticklabel', categorias_nuevas);
% 
% % Añadir etiquetas y título
% xlabel('Zone');
% ylabel('Average AUC');
% %title('AUC Promedio por Frame para cada Categoría');
% 
% % Mostrar el gráfico
% grid on;
% Crear vectores para los valores de AUC promedio y las etiquetas
% valores_auc = cell2mat(values(AUC_avg_per_frame_neuron));
% etiquetas = keys(AUC_avg_per_frame_neuron);
% 
% % Preparar las etiquetas para el gráfico, incluyendo la información del grupo y la categoría
% categorias_nuevas = cellfun(@(etiqueta) replace(etiqueta, {'NO', 'ROI1', 'ROI2'}, {'NO ROI', 'ROI 1', 'ROI 2'}), etiquetas, 'UniformOutput', false);
% 
% % Crear el gráfico de barras
% figure;
% bar(valores_auc);
% 
% % Ajustar las etiquetas del eje X para mostrar tanto la categoría como el grupo
% set(gca, 'xtick', 1:length(categorias_nuevas), 'xticklabel', categorias_nuevas, 'XTickLabelRotation', 45);
% 
% % Añadir etiquetas y título
% xlabel('Categoría y Grupo');
% ylabel('AUC Promedio por Frame y Neurona');
% title('AUC Promedio por Frame y por Neurona para cada Categoría y Grupo');
% 
% % Mejorar la presentación
% grid on;
% legend('Categorías', 'Location', 'best');
% Separar las claves en grupos y categorías
categorias_keys =keys(FLU_avg_per_frame_neuron);
flu_values = cell2mat(values(FLU_avg_per_frame_neuron));

grupos = unique(regexprep(categorias_keys, ' - .*', '')); % Extraer nombres de grupos
categorias = unique(regexprep(categorias_keys, '.* - ', '')); % Extraer nombres de categorías

% Inicializar matriz de datos para el gráfico
data_matriz = zeros(numel(categorias), numel(grupos));

% Rellenar la matriz con los valores de AUC
for i = 1:numel(categorias_keys)
    [grupo, categoria] = strtok(categorias_keys{i}, ' - ');
    categoria = strrep(categoria, ' - ', '');
    grupo_idx = find(strcmp(grupos, grupo));
    categoria_idx = find(strcmp(categorias, categoria));
    data_matriz(categoria_idx, grupo_idx) = flu_values(i);
end

% Crear el gráfico de barras agrupado
bar_handle = bar(data_matriz, 'grouped');

% Ajustar las etiquetas del eje X
set(gca, 'xticklabel', categorias);

% Añadir leyenda
legend(grupos);

% Añadir etiquetas y título
xlabel('Categoría');
ylabel('FLU Promedio por Frame y por Neurona');


% Mostrar el gráfico
grid on;
%% Sin no roi
% Separar las claves en grupos y categorías y filtrar 'NO'
categorias_keys = keys(FLU_avg_per_frame_neuron);
flu_values = cell2mat(values(FLU_avg_per_frame_neuron));

% Filtrar para excluir las claves que contienen 'NO'
filt_keys = categorias_keys(~contains(categorias_keys, 'NO'));
filt_flu_values = flu_values(~contains(categorias_keys, 'NO'));

% Reemplazar 'ROI1' con 'Close Arms' y 'ROI2' con 'Open Arms'
filt_keys = strrep(filt_keys, 'ROI1', 'Close Arms');
filt_keys = strrep(filt_keys, 'ROI2', 'Open Arms');

grupos = unique(regexprep(filt_keys, ' - .*', '')); % Extraer nombres de grupos
categorias = {'Center', 'Peripheria'}; % Definir manualmente las categorías

% Inicializar matriz de datos para el gráfico
data_matriz = zeros(numel(categorias), numel(grupos));

% Rellenar la matriz con los valores de AUC filtrados
for i = 1:numel(filt_keys)
    [grupo, categoria] = strtok(filt_keys{i}, ' - ');
    categoria = strrep(categoria, ' - ', '');
    grupo_idx = find(strcmp(grupos, grupo));
    categoria_idx = find(strcmp(categorias, categoria));
    data_matriz(categoria_idx, grupo_idx) = filt_flu_values(i);
end

% Crear el gráfico de barras agrupado
figure;
bar_handle = bar(data_matriz, 'grouped');

% Ajustar las etiquetas del eje X
set(gca, 'xticklabel', categorias);

% Añadir leyenda
legend(grupos);

% Añadir etiquetas y título
xlabel('Zone');
ylabel('Avg FLU');

% Mejorar la presentación
grid on;

% Aplicar colores específicos a cada grupo de barras
colors = [0 0.2941 0.2941; 0.9608 0.6784 0.3216]; % Definir los colores
for i = 1:length(bar_handle)
    set(bar_handle(i), 'FaceColor', colors(i,:));
end
%%

% Inicializar contenedores para las medias de fluorescencia por grupo y zona
mediasFluorescencia = struct();

% Para cada animal...
for iAnimal = 1:Experiment.Project.Animals
    grupo = Experiment.Project.Groups(iAnimal);
    datosAnimal = Experiment.EPM.(sprintf('M%d', iAnimal));
    
    % Para cada zona de interés...
    for zona = ["ROI1", "ROI2", "NO_ROI"]
        % Identificar frames relevantes para la zona
        indicesZona = find(contains(datosAnimal.Task.Titles, zona));
        framesZona = [];
        
        for indice = indicesZona
            startFrame = datosAnimal.Task.Start(indice);
            endFrame = datosAnimal.Task.End(indice);
            framesZona = [framesZona, startFrame:endFrame];
        end
        
        % Calcular la media de fluorescencia para cada neurona en esos frames
        if ~isempty(framesZona)
            mediasNeuronas = mean(datosAnimal.Filt(:, framesZona), 2);
            
            % Agregar las medias al contenedor correspondiente
            clave = sprintf('%s_%s', grupo, zona);
            if ~isfield(mediasFluorescencia, clave)
                mediasFluorescencia.(clave) = [];
            end
            mediasFluorescencia.(clave) = [mediasFluorescencia.(clave); mediasNeuronas];
        end
    end
end
%%
% Extraer datos de la estructura a cell arrays
veh_data = {mediasFluorescencia.VEH_ROI1, mediasFluorescencia.VEH_ROI2, mediasFluorescencia.VEH_NO_ROI};
cort_data = {mediasFluorescencia.CORT_ROI1, mediasFluorescencia.CORT_ROI2, mediasFluorescencia.CORT_NO_ROI};

% Combina los datos de VEH y CORT en un solo cell array
Y = {veh_data{:}, cort_data{:}};

% Definir los colores para VEH y CORT
colors = [0.9608 0.6784 0.3216; % VEH
          0 0.2941 0.2941];    % CORT

% Definir las etiquetas para el eje X
xtlabels = {'VEH Center', 'VEH Periphery', 'VEH No ROI', 'CORT Center', 'CORT Periphery', 'CORT No ROI'};

% Llamar a la función daviolinplot
h = daviolinplot(Y, 'groups', [1 1 1 2 2 2], ...
                    'violin', 'half', ...
                    'colors', repmat(colors, [3, 1]), ...
                    'xtlabels', xtlabels, ...
                    'scatter', 0, ... % No scatter, solo para este ejemplo
                    'box', 0); % No box, porque vamos a personalizarlo

% Calcula las medias y los errores estándar (SEM)
means = cellfun(@mean, Y);
sems = cellfun(@(x) std(x) / sqrt(length(x)), Y);

% Establece un ancho estimado para las líneas de media y error
estimatedWidth = 0.1;  % Este valor es arbitrario; ajusta según sea necesario para tu gráfico

% Mantiene el gráfico actual para agregar más elementos
hold on;

% Itera a través de cada conjunto de datos para trazar las medias y los SEM
for i = 1:length(Y)
    % Calcula las posiciones en x para las líneas de media y error
    xPos = h.gpos(i); % Usar las posiciones guardadas en la salida de daviolinplot
    
    % Dibuja una línea para la media
    plot([xPos - estimatedWidth, xPos + estimatedWidth], [means(i), means(i)], 'Color', 'k', 'LineWidth', 2);
    
    % Dibuja barras de error para el SEM
    errorbar(xPos, means(i), sems(i), 'k', 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 10);
end

% Finaliza la edición del gráfico actual
hold off;

% Personaliza la gráfica
ylabel('Media de Fluorescencia');
title('Distribución de la Fluorescencia por Grupo y Zona');

% Ajusta las etiquetas del eje x para mejorar la visualización
set(gca, 'xticklabel', xtlabels, 'XTick', 1:numel(Y), 'XTickLabelRotation', 45);

% Muestra la cuadrícula para facilitar la lectura de los datos
grid on;

% Ajusta los límites de los ejes para mejorar la visualización
xlim([min(h.gpos)-1, max(h.gpos)+1]);

% Asegura que todos los elementos del plot se muestren correctamente
set(gcf, 'Position', get(0, 'Screensize')); % Ajusta el tamaño de la figura a la pantalla completa
%%
% Colores para cada grupo
colors = [0 0.2941 0.2941; 0.9608 0.6784 0.3216];

% Datos de ejemplo
datos_CORT = mediasFluorescencia.CORT_ROI2;
datos_VEH = mediasFluorescencia.VEH_ROI2;

% Posiciones en el eje X para cada grupo de datos
x_CORT = 1;
x_VEH = 2;

% Crear figura
figure;

% Cálculo de estadísticas descriptivas
media_CORT = mean(datos_CORT);
std_CORT = std(datos_CORT);
media_VEH = mean(datos_VEH);
std_VEH = std(datos_VEH);

% CORT
[f_CORT, xi_CORT] = ksdensity(datos_CORT);
f_CORT = f_CORT / max(f_CORT) * 0.4; % Normalizar y escalar
fill([f_CORT + x_CORT, flip(x_CORT - f_CORT)], [xi_CORT, flip(xi_CORT)], colors(1,:), 'LineStyle', 'none', 'FaceAlpha', 0.5);
hold on;

% VEH
[f_VEH, xi_VEH] = ksdensity(datos_VEH);
f_VEH = f_VEH / max(f_VEH) * 0.4; % Normalizar y escalar
fill([f_VEH + x_VEH, flip(x_VEH - f_VEH)], [xi_VEH, flip(xi_VEH)], colors(2,:), 'LineStyle', 'none', 'FaceAlpha', 0.5);

% Líneas de la media
plot([x_CORT-0.4, x_CORT+0.4], [media_CORT, media_CORT], 'Color', colors(1,:), 'LineWidth', 2);
plot([x_VEH-0.4, x_VEH+0.4], [media_VEH, media_VEH], 'Color', colors(2,:), 'LineWidth', 2);

% Líneas de error para la desviación estándar
errorbar(x_CORT, media_CORT, std_CORT, 'Color', colors(1,:), 'LineWidth', 2, 'LineStyle', 'none', 'CapSize', 10);
errorbar(x_VEH, media_VEH, std_VEH, 'Color', colors(2,:), 'LineWidth', 2, 'LineStyle', 'none', 'CapSize', 10);

% Configurar gráfico
xlim([0.5 2.5]);
xticks([1 2]);
xticklabels({'CORT', 'VEH'});
ylabel('Valores');
title('Periphery');
hold off;
