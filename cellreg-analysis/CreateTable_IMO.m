function [finalTable, only_E, only_L]  = CreateTable_IMO(Matrics_Early,Matrics_Late)

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
end