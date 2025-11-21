%% Code for Analysis of Cell Reg Results - Tunning 

%% Load all the files 
x = input('Enter the number of animals: ');  

loadedDataCellReg = cell(1, x);    % Cell array to store loaded data
filePathsCellReg = cell(1, x);     % Store file paths for reference

for i = 1:x
    [fileName, filePath] = uigetfile('*.mat', sprintf('Select file for CellReg result of animal %d of %d', i, x));
    
    if isequal(fileName, 0)
        error('File selection cancelled. Exiting...');
    end

    fullPath = fullfile(filePath, fileName);
    filePathsCellReg{i} = fullPath;
    loadedDataCellReg{i} = load(fullPath);
    
    disp(['Loaded file ' num2str(i) ': ' fullPath]);
end

%% Ask user for test and ROI names
testName1 = input('Enter the test 1 name: ', 's');
testName2 = input('Enter the test 2 name: ', 's');
roiName = input('Enter the ROI name: ', 's');

%% Load Tunning and Good Neurones data

[loadedDataTunning_test1,filePathsTunning_test1] = LoadFiles(testName1, x, 'Tunning');
[loadedDataTunning_test2,filePathsTunning_test2] = LoadFiles(testName2, x, 'Tunning');
[loadedDataGoodNeurones_test1,filePathsGoodNeurones_test1] = LoadFiles(testName1, x, 'Good Neurones');
[loadedDataGoodNeurones_test2,filePathsGoodNeurones_test2] = LoadFiles(testName2, x, 'Good Neurones');

%% Add Index of Good Neurones to Tunning Data

for i=1:x
    loadedDataTunning_test1{1,i}.splitTable.Index = loadedDataGoodNeurones_test1{1,i}.good_neurons_indices;
end

for i=1:x
    loadedDataTunning_test2{1,i}.splitTable.Index = loadedDataGoodNeurones_test2{1,i}.good_neurons_indices;
end

%% Output Table Creation

Table_Output = table();
Table_Output.Animal = strings(0,1);  
Table_Output.Index1 = strings(0,1);  
Table_Output.Index2 = strings(0,1);  
Table_Output.Tunning1 = strings(0,1); 
Table_Output.Tunning2 = strings(0,1);  

for i=1:x
    cell_reg_table = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map

    for y=1:length(cell_reg_table)
        if cell_reg_table(y,1)~= 0 & cell_reg_table(y,2) ~= 0
           index1 = find(loadedDataTunning_test1{1,i}.splitTable.Index == cell_reg_table(y,1));
           index2 = find(loadedDataTunning_test2{1,i}.splitTable.Index == cell_reg_table(y,2));

           tunning1 = loadedDataTunning_test1{1,i}.splitTable.ResponseType(index1)
           tunning2 = loadedDataTunning_test2{1,i}.splitTable.ResponseType(index2)
           
           newRow = {string(i), string(cell_reg_table(y,1)), string(cell_reg_table(y,2)), tunning1, tunning2};  % must match the types
           
           if ~isempty(tunning1) & ~isempty(tunning2) ~= 0
               Table_Output(end+1, :) = newRow;
           end
        end 
    end 
end

[filenameoutput, pathnameoutput] = uiputfile('*.xlsx', 'Save Table As');
if isequal(filenameoutput, 0)
    disp('User canceled file save.');
else
    fullpath = fullfile(pathnameoutput, filenameoutput);
    writetable(Table_Output, fullpath);
    disp(['Table saved to: ' fullpath]);
end

%% Counter  

Table_Output_Counts = table();
Table_Output_Counts.ChangeOfActivity = strings(0,1);
Table_Output_Counts.Times = cell(0,1);

for i=1:height(Table_Output)
    activity1 = Table_Output.Tunning1(i);
    acitvity2 = Table_Output.Tunning2(i);
    couple = activity1 + '-' + acitvity2;
    if ~ismember(couple, Table_Output_Counts.ChangeOfActivity)
        newrow1 = {couple, 1};
        Table_Output_Counts = [Table_Output_Counts; newrow1];
    else 
        index = find(Table_Output_Counts.ChangeOfActivity == couple);
        newcount = Table_Output_Counts.Times{index} + 1;
        Table_Output_Counts.Times(index) = {newcount};
    end
end 

nameFileCount = [pathnameoutput, 'Results_Count.xlsx'];
writetable(Table_Output_Counts, nameFileCount);
