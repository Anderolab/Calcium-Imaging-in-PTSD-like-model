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

answer_IMO = input(['How many of your sessions are IMO? One, both or none? (o/b/n): '], 's');

if strcmpi(answer_IMO, 'o')
    testName1 = 'IMO';
    testName2 = input('Enter the test 2 name: ', 's');
elseif strcmpi(answer_IMO, 'n')
    testName1 = input('Enter the test 1 name: ', 's');
    testName2 = input('Enter the test 2 name: ', 's');
else
    testName1 = 'IMO_Early';
    testName2 = 'IMO_Late';
end

%% Take Good Neurones

if strcmpi(answer_IMO, 'o')

    goodNeurons_test1_1 = {};
    goodNeurons_test1_2 = {};
    goodNeurons_test2 = {};
    
    for i = 1:length(animal_list)
        animal = animal_list{i};  % Get the neuron name
        
        % Ask user if this is a good neuron
        answer = input(['Do you want to select the good neurones for ', char(animal), ' in session ', testName1, ' Early? (y/n): '], 's');
        if strcmpi(answer, 'y')
            goodNeurons_test1_1{end+1} = animal;  % Add to good list
        else
            goodNeurons_test1_1{end+1} = 0;
        end
        
        answer1 = input(['Do you want to select the good neurones for ', char(animal), ' in session ', testName1, ' Late? (y/n): '], 's');
        if strcmpi(answer1, 'y')
            goodNeurons_test1_2{end+1} = animal;  % Add to good list
        else
            goodNeurons_test1_2{end+1} = 0;
        end
        
        answer2 = input(['Do you want to select the good neurones for ', char(animal), ' in session ', testName2, '? (y/n): '], 's');
        if strcmpi(answer2, 'y')
            goodNeurons_test2{end+1} = animal;  % Add to good list
        else
            goodNeurons_test2{end+1} = 0;
        end
    
    end


else
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
end
%% Load good Neurones

if strcmpi(answer_IMO, 'o')
    [loadedDataGoodNeurones_test1_1,filePathsGoodNeurones_test1_1] = LoadFilesGoodNeurones([testName1, '_Early'], x, goodNeurons_test1_1);
    [loadedDataGoodNeurones_test1_2,filePathsGoodNeurones_test1_2] = LoadFilesGoodNeurones([testName1, '_Late'], x, goodNeurons_test1_2);
    [loadedDataGoodNeurones_test2,filePathsGoodNeurones_test2] = LoadFilesGoodNeurones(testName2, x, goodNeurons_test2);
else
    [loadedDataGoodNeurones_test1,filePathsGoodNeurones_test1] = LoadFilesGoodNeurones(testName1, x, goodNeurons_test1);
    [loadedDataGoodNeurones_test2,filePathsGoodNeurones_test2] = LoadFilesGoodNeurones(testName2, x, goodNeurons_test2);
end

%% Load Matrics data

if strcmpi(answer_IMO, 'b')
    [matrics_file_1, matrics_path_1] = uigetfile('*.xlsx', 'Select matrics result file for IMO');
    matrics_path_1 = fullfile(matrics_path_1, matrics_file_1);
    loadedDataMatrics_1 = readtable(matrics_path_1);
else
    [matrics_file_1, matrics_path_1] = uigetfile('*.xlsx', sprintf('Select matrics result file for %s', testName1));
    matrics_path_1 = fullfile(matrics_path_1, matrics_file_1);
    loadedDataMatrics_1 = readtable(matrics_path_1);
    [matrics_file_2, matrics_path_2] = uigetfile('*.xlsx', sprintf('Select matrics result file for %s', testName2));
    matrics_path_2 = fullfile(matrics_path_2, matrics_file_2);
    loadedDataMatrics_2 = readtable(matrics_path_2);
end

%% Divide Into two tables: Early and Late

if ~strcmpi(answer_IMO, 'n')

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

%% Add Good Neuron Index and Remove Animals not Included

if strcmpi(answer_IMO, 'b')
    Matrics_Early = Matrics_Early(ismember(string(Matrics_Early.Animal), string(animal_list)), :);
    Matrics_Late = Matrics_Late(ismember(string(Matrics_Late.Animal), string(animal_list)), :);
    [Matrics_Early] = Add_Neuron_Index_Good(goodNeurons_test1,Matrics_Early,loadedDataGoodNeurones_test1, '_E', animal_list);
    [Matrics_Late] = Add_Neuron_Index_Good(goodNeurons_test2,Matrics_Late,loadedDataGoodNeurones_test2, '_L', animal_list);
elseif strcmpi(answer_IMO, 'o')
    Matrics_Early = Matrics_Early(ismember(string(Matrics_Early.Animal), string(animal_list)), :);
    Matrics_Late = Matrics_Late(ismember(string(Matrics_Late.Animal), string(animal_list)), :);
     [Matrics_Late] = Add_Neuron_Index_Good(goodNeurons_test1_1,Matrics_Late,loadedDataGoodNeurones_test1_2, '_L', animal_list); 
    [loadedDataMatrics_2] = Add_Neuron_Index_Good(goodNeurons_test2,loadedDataMatrics_2,loadedDataGoodNeurones_test2, testName2, animal_list); 
else
    loadedDataMatrics_1 = loadedDataMatrics_1(ismember(string(loadedDataMatrics_1.Animal), string(animal_list)), :);
    loadedDataMatrics_2 = loadedDataMatrics_2(ismember(string(loadedDataMatrics_2.Animal), string(animal_list)), :);
    [loadedDataMatrics_1] = Add_Neuron_Index_Good(goodNeurons_test1,loadedDataMatrics_1,loadedDataGoodNeurones_test1, testName1, animal_list);
    [loadedDataMatrics_2] = Add_Neuron_Index_Good(goodNeurons_test2,loadedDataMatrics_2,loadedDataGoodNeurones_test2, testName2, animal_list);
end
%% Select Only CellReg cells and Create new Table with Results

if exist('loadedDataMatrics_1', 'var') & ismember("Sexo", loadedDataMatrics_1.Properties.VariableNames) 
    loadedDataMatrics_1.Properties.VariableNames{'Sexo'} = 'Sex';
elseif exist('Matrics_Early', 'var') & ismember("Sexo", Matrics_Early.Properties.VariableNames)
    Matrics_Early.Properties.VariableNames{'Sexo'} = 'Sex';
    Matrics_Late.Properties.VariableNames{'Sexo'} = 'Sex';
else
end

if exist('loadedDataMatrics_2', 'var') & ismember("Sexo", loadedDataMatrics_2.Properties.VariableNames) 
    loadedDataMatrics_2.Properties.VariableNames{'Sexo'} = 'Sex';
end

if strcmpi(answer_IMO, 'b')
    [finalTable, only_E, only_L, Matrics_Early, Matrics_Late] = CreateTable_IMO(Matrics_Early,Matrics_Late);
elseif strcmpi(answer_IMO, 'o')
    answer3 = input(['Do you want to consider Early or Late IMO? (e/l): '], 's');
    if strcmpi(answer3, 'e')
        [finalTable, only_E, only_L, Matrics_Early,loadedDataMatrics_2]  = CreateTable_IMO_Normal(Matrics_Early,loadedDataMatrics_2, testName2);
    else
        [finalTable, only_E, only_L,Matrics_Late,loadedDataMatrics_2]  = CreateTable_IMO_Normal(Matrics_Late,loadedDataMatrics_2, testName2);
    end
else
    [finalTable, only_E, only_L, loadedDataMatrics_1, loadedDataMatrics_2]  = CreateTable_Normal(loadedDataMatrics_1,loadedDataMatrics_2, testName1, testName2);
end 

%% Add Data to Final Table

if strcmpi(answer_IMO, 'b')
    list_1 = Matrics_Early;
    list_2 = Matrics_Late;    
elseif strcmpi(answer_IMO, 'o')
    if strcmpi(answer3, 'e')
        list_1 = Matrics_Early;
        list_2 = loadedDataMatrics_2;
    else
        list_1 = Matrics_Late;
        list_2 = loadedDataMatrics_2;
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

                if isa(list_1{idx_table1, 4}, 'double')
                    new_row = {animal_list{i}, list_1{idx_table1,2}};
                else
                    new_row = {animal_list{i}, list_1{idx_table1,2}, list_1{idx_table1,4}};
                end

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

if strcmpi(answer_IMO, 'o') & strcmpi(answer3, 'e')
    [animals_to_exclude_1,Percentages_list_1] = Calculate_Percentage_Aligned_Neurones(length(animal_list),loadedDataGoodNeurones_test1_1,loadedDataGoodNeurones_test2,loadedDataCellReg);
elseif strcmpi(answer_IMO, 'o') & strcmpi(answer3, 'l')
    [animals_to_exclude_1,Percentages_list_1] = Calculate_Percentage_Aligned_Neurones(length(animal_list),loadedDataGoodNeurones_test1_2,loadedDataGoodNeurones_test2,loadedDataCellReg);
else
    [animals_to_exclude_1,Percentages_list_1] = Calculate_Percentage_Aligned_Neurones(length(animal_list),loadedDataGoodNeurones_test1,loadedDataGoodNeurones_test2,loadedDataCellReg);
end

Perc_Table = table();
Perc_Table.Animals = animal_list';
Perc_Table.Percentages = Percentages_list_1';
Perc_Table.Properties.VariableNames{'Percentages'} = ['Percentage of cell registered between ' testName1 ' and ' testName2]

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