function [finalTable, only_E, only_L, Matrics_Early, loadedDataMatrics_2] = CreateTable_Normal(Matrics_Early,loadedDataMatrics_2, testName1, testName2)
    
    % Example: your table is called 'data'
    index_1 = ['Index_' testName1];
    index_2 = ['Index_' testName2];
    excludeCols = {'Animal', 'Sex', 'Treatment', 'Sexo', 'Tratamiento', index_1, index_2}; % columns to exclude
    allCols_1 = Matrics_Early.Properties.VariableNames;
    allCols_2 = loadedDataMatrics_2.Properties.VariableNames;
    
    % Create new names
    newCols = allCols_1; % start with current names
    for i = 1:length(allCols_1)
        if ~ismember(allCols_1{i}, excludeCols)
            newCols{i} = [allCols_1{i} '_' testName1];
        end
    end

    % Apply new column names to the table
    Matrics_Early.Properties.VariableNames = newCols;

    % Create new names
    newCols_2 = allCols_2; % start with current names
    for i = 1:length(allCols_2)
        if ~ismember(allCols_2{i}, excludeCols)
            newCols_2{i} = [allCols_2{i} '_' testName2];
        end
    end

    % Apply new column names to the table
    loadedDataMatrics_2.Properties.VariableNames = newCols_2;

    vars_E = Matrics_Early.Properties.VariableNames;
    vars_L = loadedDataMatrics_2.Properties.VariableNames;
    commonVars = intersect(vars_E, vars_L, 'stable');
    only_E = setdiff(vars_E, commonVars, 'stable');
    only_L = setdiff(vars_L, commonVars, 'stable');
    prefixes_E = erase(only_E, testName1);
    prefixes_L = erase(only_L, testName2);
    
    mergedVars = commonVars;
    usedPrefixes = {};  
    
    for i = 1:length(prefixes_E)
        prefix = prefixes_E{i};
        
        idx_L = find(strcmp(prefixes_L, prefix));
        
        mergedVars{end+1} = only_E{i};
        if ~isempty(idx_L) && ~ismember(prefix, usedPrefixes)
            for y = 1:length(idx_L)
                mergedVars{end+1} = only_L{idx_L(y)};
                usedPrefixes{end+1} = prefix;
            end
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
    finalTable.Sex = strings(0,1);
end