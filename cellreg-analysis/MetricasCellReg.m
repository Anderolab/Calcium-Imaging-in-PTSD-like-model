%% Code for Analysis of Cell Reg Results - Tunning 

%% Load all the files 
x = input('Enter the number of animals: ');  

loadedDataCellReg = cell(1, x);    % Cell array to store loaded data
filePathsCellReg = cell(1, x);     % Store file paths for reference

animal_list = {};
for i = 1:x
    [fileName, filePath] = uigetfile('*.mat', sprintf('Select file for CellReg result of animal %d of %d', i, x));
    
    if isequal(fileName, 0)
        error('File selection cancelled. Exiting...');
    end

    fullPath = fullfile(filePath, fileName);
    filePathsCellReg{i} = fullPath;
    loadedDataCellReg{i} = load(fullPath);

    parts = split(fullPath, filesep);
    folder = parts{end-1};
    animal_list{end + 1} = {folder};
    
    disp(['Loaded file ' num2str(i) ': ' fullPath]);
end

%% Ask user for test names

testName1 = input('Enter the test 1 name: ', 's');
testName2 = input('Enter the test 2 name: ', 's');

%% Take Good Neurones

goodNeurons_test1 = {};
goodNeurons_test2 = {};

for i = 1:length(animal_list)
    animal = animal_list{i};  % Get the neuron name
    
    % Ask user if this is a good neuron
    answer = input(['Do you want to select the good neurones for ', char(animal), ' in session ', testName1, '? (y/n): '], 's');
    if strcmpi(answer, 'y')
        goodNeurons_test1{end+1} = animal;  % Add to good list
    else
        goodNeurons_test1{end+1} = 0;
    end
    answer2 = input(['Do you want to select the good neurones for ', char(animal), ' in session ', testName2, '? (y/n): '], 's');
    if strcmpi(answer2, 'y')
        goodNeurons_test2{end+1} = animal;  % Add to good list
    else
        goodNeurons_test2{end+1} = 0;
    end

end

%% Load good Neurones
                
[loadedDataGoodNeurones_test1,filePathsGoodNeurones_test1] = LoadFilesGoodNeurones(testName1, x, goodNeurons_test1);
[loadedDataGoodNeurones_test2,filePathsGoodNeurones_test2] = LoadFilesGoodNeurones(testName2, x, goodNeurons_test2);

%% Check Percentage of kept neurones

animals_to_exclude = [];
Percentages_list = [];
for i=1:x
    if class(loadedDataGoodNeurones_test1{i}) == 'struct'
        counter = 0;
        table_cellregt = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map;
        for y=1:length(loadedDataGoodNeurones_test1{i}.good_neurons_indices);
            index = loadedDataGoodNeurones_test1{i}.good_neurons_indices(y);
            idx = find(table_cellregt(:,1) == index);
            if ~isempty(idx) & ~ismember(0,table_cellregt(idx,:)) 
                counter = counter + 1;     
            end
        end
        
        num_neurones = length(loadedDataGoodNeurones_test1{i}.good_neurons_indices);
        percentage = counter / num_neurones;
        Percentages_list = [Percentages_list, percentage];
        if percentage < 0.3
            animals_to_exclude = [animals_to_exclude, x];
        end 

    else
        counter = 0;
        table_cellregt = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map;
        for y=1:height(table_cellregt)
            if ~ismember(0,table_cellregt(y,:)) 
                counter = counter + 1;;     
            end
        end 

        num_neurones = nnz(loadedDataCellReg{i}.cell_registered_struct.cell_to_index_map(:,1));
        percentage = counter / num_neurones;
        Percentages_list = [Percentages_list, percentage];
        if percentage < 0.3
            animals_to_exclude = [animals_to_exclude, x];
        end 
    end 
end 

%% Load Matrics data

if contains(testName1, 'IMO', 'IgnoreCase', true) & contains(testName2, 'IMO', 'IgnoreCase', true)
    [matrics_file, matrics_path] = uigetfile('*.xlsx', 'Select matrics result file for IMO');
    matrics_path = fullfile(matrics_path, matrics_file);
    loadedDataMatrics = readtable(matrics_path);
else
    [matrics_file, matrics_path] = uigetfile('*.xlsx', sprintf('Select matrics result file for %s', testName1));
    matrics_path = fullfile(matrics_path, matrics_file);
    loadedDataMatrics_1 = readtable(matrics_path);
    [matrics_file, matrics_path] = uigetfile('*.xlsx', sprintf('Select matrics result file for %s', testName2));
    matrics_path_2 = fullfile(matrics_path, matrics_file);
    loadedDataMatrics_2 = readtable(matrics_path_2);
end

%% Divide Into two tables: Early and Late

if contains(testName1, 'IMO', 'IgnoreCase', true) | contains(testName2, 'IMO', 'IgnoreCase', true)

    if ismember('Mean_E', loadedDataMatrics_1.Properties.VariableNames)
        loadedDataMatrics = loadedDataMatrics_1;
    else
        loadedDataMatrics = loadedDataMatrics_2;
    end

    Matrics_Early = loadedDataMatrics;
    
    for i=height(loadedDataMatrics):-1:1
        if loadedDataMatrics.Mean_E(i) == 0
            Matrics_Early(i, :) = [];
        end 
    end
    
    flat_list = cellfun(@(c) c{1}, animal_list, 'UniformOutput', false);
    rowsToDelete = ~ismember(Matrics_Early.Animal, flat_list);
    Matrics_Early(rowsToDelete, :) = [];
    
    colsToRemove = varfun(@(x) all(x == 0), Matrics_Early(:,3:end), 'OutputFormat', 'uniform');
    colsToRemove = [false false colsToRemove];
    Matrics_Early(:, colsToRemove) = [];
    
    if ismember('Mean_E', loadedDataMatrics_1.Properties.VariableNames)
        loadedDataMatrics = loadedDataMatrics_1;
    else
        loadedDataMatrics = loadedDataMatrics_2;
    end

    Matrics_Late = loadedDataMatrics;
    
    for i=height(loadedDataMatrics):-1:1
        if loadedDataMatrics.Mean_L(i) == 0
            Matrics_Late(i, :) = [];
        end 
    end
    
    rowsToDelete_2 = ~ismember(Matrics_Late.Animal, flat_list);
    Matrics_Late(rowsToDelete_2, :) = [];
    
    colsToRemove = varfun(@(x) all(x == 0), Matrics_Late(:,3:end), 'OutputFormat', 'uniform');
    colsToRemove = [false false colsToRemove];
    Matrics_Late(:, colsToRemove) = [];

end

%% Add Good Neuron Index

if contains(testName1, 'IMO', 'IgnoreCase', true)
    good_neurones = goodNeurons_test1
    loadeddataGoodNeurones = loadedDataGoodNeurones_test1
else
    good_neurones = goodNeurons_test2
    loadeddataGoodNeurones = loadedDataGoodNeurones_test2
end

answer = input(['Are you interested in Early or Late IMO? (e/l): '], 's');
    if strcmpi(answer, 'e')
        index_column = [];
        for i=1:length(good_neurones)
            if length(good_neurones{i}) == 1
                animal = animal_list{i};
                idx = find(strcmp(Matrics_Early{:,1}, animal));
                idx = 1:length(idx);
                index_column = [index_column, idx];
            else 
                animal = animal_list{i};
                idx = loadeddataGoodNeurones{1,i}.good_neurons_indices;
                index_column = [index_column, idx'];
            end 
        end
        
        nameColumn = ['Index_', 'E'];
        index_column = table(index_column', 'VariableNames', {nameColumn});
        Matrics_Early = [Matrics_Early(:,1:2) index_column Matrics_Early(:,3:end)];
    else 
        index_column2 = [];
        for i=1:length(good_neurones)
            if length(good_neurones{i}) == 1
                animal = animal_list{i};
                idx = find(strcmp(Matrics_Late{:,1}, animal));
                idx = 1:length(idx);
                index_column2 = [index_column2, idx];
            else 
                animal = animal_list{i};
                idx = loadeddataGoodNeurones{1,i}.good_neurons_indices;
                index_column2 = [index_column2, idx'];
            end 
        end
        
        nameColumn = ['Index_', 'L'];
        index_column2 = table(index_column2', 'VariableNames', {nameColumn});
        
        Matrics_Late = [Matrics_Late(:,1:2) index_column2 Matrics_Late(:,3:end)];
    end 

%% Select Only CellReg cells and Create new Table with Results

if contains(testName1, 'IMO', 'IgnoreCase', true) & contains(testName2, 'IMO', 'IgnoreCase', true)
    vars_E = Matrics_Early.Properties.VariableNames;
    vars_L = Matrics_Late.Properties.VariableNames;
    commonVars = intersect(vars_E, vars_L, 'stable');
    only_E = setdiff(vars_E, commonVars, 'stable');
    only_L = setdiff(vars_L, commonVars, 'stable');
    prefixes_E = erase(only_E, "_E");
    prefixes_L = erase(only_L, "_L");
    
    mergedVars = commonVars;
    usedPrefixes = {};
    
    for i = 1:length(prefixes_E)
        prefix = prefixes_E{i};
        
        idx_L = find(strcmp(prefixes_L, prefix), 1);
        
        mergedVars{end+1} = only_E{i};
        if ~isempty(idx_L) && ~ismember(prefix, usedPrefixes)
            mergedVars{end+1} = only_L{idx_L};
            usedPrefixes{end+1} = prefix;
        end
    end
    
    for i = 1:length(only_L)
        prefix = prefixes_L{i};
        if ~ismember(prefix, prefixes_E) && ~ismember(prefix, usedPrefixes)
            mergedVars{end+1} = only_L{i};
        end
    end
    
    % Create an empty table with those columns
    emptyData = cell(0, length(mergedVars));  % 0 rows
    finalTable = cell2table(emptyData, 'VariableNames', mergedVars);
    
    finalTable.Animal = strings(0,1);  % Empty string column
    finalTable.Sexo = strings(0,1);

elseif xor(contains(testName1, 'IMO', 'IgnoreCase', true), contains(testName2, 'IMO', 'IgnoreCase', true))
    if strcmpi(answer, 'e')
        vars_E = Matrics_Early.Properties.VariableNames;
        vars_L = loadedDataMatrics_2.Properties.VariableNames;
        commonVars = intersect(vars_E, vars_L, 'stable');
        only_E = setdiff(vars_E, commonVars, 'stable');
        only_L = setdiff(vars_L, commonVars, 'stable');
        prefixes_E = erase(only_E, "_E");
        prefixes_L = erase(only_L, "_");
        
        mergedVars = commonVars;
        usedPrefixes = {};
        
        for i = 1:length(prefixes_E)
            prefix = prefixes_E{i};
            
            idx_L = find(strcmp(prefixes_L, prefix), 1);
            
            mergedVars{end+1} = only_E{i};
            if ~isempty(idx_L) && ~ismember(prefix, usedPrefixes)
                mergedVars{end+1} = only_L{idx_L};
                usedPrefixes{end+1} = prefix;
            end
        end
        
        for i = 1:length(only_L)
            prefix = prefixes_L{i};
            if ~ismember(prefix, prefixes_E) && ~ismember(prefix, usedPrefixes)
                mergedVars{end+1} = only_L{i};
            end
        end
        
        % Create an empty table with those columns
        emptyData = cell(0, length(mergedVars));  % 0 rows
        finalTable = cell2table(emptyData, 'VariableNames', mergedVars);
        
        finalTable.Animal = strings(0,1);  % Empty string column
        finalTable.Sexo = strings(0,1);
    else
        vars_E = Matrics_Late.Properties.VariableNames;
        vars_L = loadedDataMatrics_2.Properties.VariableNames;
        commonVars = intersect(vars_E, vars_L, 'stable');
        only_E = setdiff(vars_E, commonVars, 'stable');
        only_L = setdiff(vars_L, commonVars, 'stable');
        prefixes_E = erase(only_E, "_E");
        prefixes_L = erase(only_L, "_");
        
        mergedVars = commonVars;
        usedPrefixes = {};
        
        for i = 1:length(prefixes_E)
            prefix = prefixes_E{i};
            
            idx_L = find(strcmp(prefixes_L, prefix), 1);
            
            mergedVars{end+1} = only_E{i};
            if ~isempty(idx_L) && ~ismember(prefix, usedPrefixes)
                mergedVars{end+1} = only_L{idx_L};
                usedPrefixes{end+1} = prefix;
            end
        end
        
        for i = 1:length(only_L)
            prefix = prefixes_L{i};
            if ~ismember(prefix, prefixes_E) && ~ismember(prefix, usedPrefixes)
                mergedVars{end+1} = only_L{i};
            end
        end
        
        % Create an empty table with those columns
        emptyData = cell(0, length(mergedVars));  % 0 rows
        finalTable = cell2table(emptyData, 'VariableNames', mergedVars);
        
        finalTable.Animal = strings(0,1);  % Empty string column
        finalTable.Sexo = strings(0,1);       
    end 
else
    vars_E = loadedDataMatrics_1.Properties.VariableNames;
    vars_L = loadedDataMatrics_2.Properties.VariableNames;
    commonVars = intersect(vars_E, vars_L, 'stable');
    only_E = setdiff(vars_E, commonVars, 'stable');
    only_L = setdiff(vars_L, commonVars, 'stable');
    prefixes_E = erase(only_E, ["_ROI1", "_ROI2", "_NO_ROI"]);
    prefixes_L = erase(only_L, ["_ROI1", "_ROI2", "_NO_ROI"]);
    
    mergedVars = commonVars;
    usedPrefixes = {};
    
    for i = 1:length(prefixes_E)
        prefix = prefixes_E{i};
        
        idx_L = find(strcmp(prefixes_L, prefix), 1);
        
        mergedVars{end+1} = only_E{i};
        if ~isempty(idx_L) && ~ismember(prefix, usedPrefixes)
            mergedVars{end+1} = only_L{idx_L};
            usedPrefixes{end+1} = prefix;
        end
    end
    
    for i = 1:length(only_L)
        prefix = prefixes_L{i};
        if ~ismember(prefix, prefixes_E) && ~ismember(prefix, usedPrefixes)
            mergedVars{end+1} = only_L{i};
        end
    end
    
    % Create an empty table with those columns
    emptyData = cell(0, length(mergedVars));  % 0 rows
    finalTable = cell2table(emptyData, 'VariableNames', mergedVars);
    
    finalTable.Animal = strings(0,1);  % Empty string column
    finalTable.Sexo = strings(0,1);

end 

%% Add Data to Final Table

if contains(testName1, 'IMO', 'IgnoreCase', true) & contains(testName2, 'IMO', 'IgnoreCase', true)
    list_1 = Matrics_Early;
    list_2 = Matrics_Late;
elseif xor(contains(testName1, 'IMO', 'IgnoreCase', true), contains(testName2, 'IMO', 'IgnoreCase', true))
    if strcmpi(answer, 'e') & ismember('Mean_E', loadedDataMatrics_1.Properties.VariableNames)
        list_1 = Matrics_Early;
        list_2 = loadedDataMatrics_2;
    elseif strcmpi(answer, 'e') & ismember('Mean_E', loadedDataMatrics_2.Properties.VariableNames)
        list_1 = Matrics_Early;
        list_2 = loadedDataMatrics_1;
    elseif strcmpi(answer, 'l') & ismember('Mean_E', loadedDataMatrics_1.Properties.VariableNames)
        list_1 = Matrics_Late;
        list_2 = loadedDataMatrics_2;
    else
        list_1 = Matrics_Late;
        list_2 = loadedDataMatrics_1;
    end
else
    list_1 = loadedDataMatrics_1;
    list_2 = loadedDataMatrics_2;    
end

for i=1:length(animal_list)
    index_cell_reg_session1 = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map(:,1);
    index_cell_reg_session2 = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map(:,2);

    for y=1:length(index_cell_reg_session1)
        idx_cell_reg_1 = index_cell_reg_session1(y);
        idx_cell_reg_2 = index_cell_reg_session2(y);

       if idx_cell_reg_1 ~= 0 & idx_cell_reg_2 ~= 0
            idx_table1 = find(strcmp(list_1{:,1}, animal_list{i}) & list_1{:,3} == idx_cell_reg_1);
            idx_table2 = find(strcmp(list_2{:,1}, animal_list{i}) & list_2{:,3} == idx_cell_reg_2); 

            if ~isempty(idx_table1) & ~isempty(idx_table2)
                new_row = {animal_list{i}, list_1{idx_table1,2}};

                for x=1:length(only_E)
                    new_row = [new_row, list_1.(only_E{x})(idx_table1)];
                    new_row = [new_row, list_2.(only_L{x})(idx_table2)];
                end 

                new_row = cell2table(new_row, 'VariableNames', finalTable.Properties.VariableNames);
                finalTable = [finalTable; new_row];
            end
       end
    end
end 

%% Percentages Table

Perc_Table = table();
Perc_Table.Animals = animal_list';
Perc_Table.Percentages = Percentages_list';


%% Save Final Table 

[filename, pathname] = uiputfile('*.xlsx', 'Save table as');
if isequal(filename, 0) || isequal(pathname, 0)
    disp('User canceled saving.');
else
    fullpath = fullfile(pathname, filename);
    fullpath2 = fullfile(pathname, 'Percentage_Cell_Reg_IMO.xlsx')
    writetable(finalTable, fullpath);
    writetable(Perc_Table, fullpath2);
    disp(['Table saved to: ' fullpath]);
end
