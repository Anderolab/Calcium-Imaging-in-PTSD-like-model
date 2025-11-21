function [loadedDataTunning_test1,filePathsTunning_test1] = LoadFilesGoodNeurones(testName1, x, list_neurones)

    loadedDataTunning_test1 = cell(1, x);    % Cell array to store loaded data
    filePathsTunning_test1 = cell(1, x);     % Store file paths for reference
    folderPath = uigetdir(pwd, ['Select good neurones folder for ', testName1]);

    for i=1:length(list_neurones)
        animal = string(list_neurones{i});

        if ~strcmp(animal, "0")
            fileNames = dir(folderPath);
            fileNames = {fileNames(~[fileNames.isdir]).name};
            fileNameAnimal = strcat('good_neurons_', animal);

            fileName = fileNames(startsWith(fileNames, fileNameAnimal) & ...
                endsWith(fileNames, '_index.mat'));
            
            matches = cellfun(@(f) contains(f, strcat("_", animal, "_")), fileName);
            
            % Filter filenames
            filteredFiles = fileName(matches);
            
            % If none found, set to 0
            if isempty(filteredFiles)
                fileName = 0;
            else
                fileName = filteredFiles;
            end

            filePath = strcat(folderPath, '\', fileName);
            
            if iscell(fileName)
                filePathsTunning_test1{i} = string(filePath);
                loadedDataTunning_test1{i} = load(string(filePath));
            else 
                loadedDataTunning_test1{i} = [0];
            end
        else
            filePathsTunning_test1{i} = 0;
            loadedDataTunning_test1{i} = 0;
        end
    end 
end