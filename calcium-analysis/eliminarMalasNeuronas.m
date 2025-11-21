% -------------------------------------------EPMEPM----------OF----SPTex----------------
% Eliminar malas neuronas basado en índices previamente guardados
% ----------------------------------------OF---------------------------------
% Inputs:
% - Experiment: Estructura con los datos del experimento.

function Experiment = eliminarMalasNeuronas(Experiment)

    % Obtener la lista de animales a partir de los campos en Experiment.EPM
    animalNames = fieldnames(Experiment.SPT);

    % Ruta base donde se almacenan los índices de las buenas neuronas
    basePath = 'D:\Ex3_BLA\DLC\Good_neurones\Good_Neurones_SPT';

    % Iterar sobre cada animal
    for i = 1:numel(animalNames)
        animalName = animalNames{i};

        % Obtener el número de neuronas
        numNeurons = size(Experiment.SPT.(animalName).Filt, 1);

        % Preguntar al usuario si desea eliminar las neuronas malas para este animal
        removeBadNeurons = input(['¿Desea eliminar las neuronas malas para ' animalName '? (s/n): '], 's');

        % Cargar los índices de las buenas neuronas para el animal actual si se requiere
        if strcmpi(removeBadNeurons, 's')
            % Generar la ruta completa del archivo de buenas neuronas
            goodNeuronsFile = fullfile(basePath, ['good_neurons_' animalName '_index.mat']);

            % Verificar si el archivo existe
            if exist(goodNeuronsFile, 'file')
                % Cargar el archivo de índices de buenas neuronas
                load(goodNeuronsFile, 'good_neurons_indices');

                % Filtrar las neuronas para incluir solo las buenas
                Experiment.SPT.(animalName).Filt = Experiment.SPT.(animalName).Filt(good_neurons_indices, :);
                fprintf('Neuronas malas eliminadas para %s. Quedan %d neuronas.\n', animalName, numel(good_neurons_indices));
            else
                warning('No se encontró el archivo de buenas neuronas para %s. No se eliminaron neuronas.', animalName);
            end
        else
            fprintf('No se eliminaron neuronas para %s. Se mantienen las %d neuronas originales.\n', animalName, numNeurons);
        end
    end
end
