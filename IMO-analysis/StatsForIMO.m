% Request user input for the data table
[fileName, pathName] = uigetfile({'*.xlsx'; '*.csv'}, 'Select your data file');
if isequal(fileName,0)
    disp('User canceled file selection.');
    return;
end

% Read the data
dataPath = fullfile(pathName, fileName);
dataTable = readtable(dataPath);

% Display the imported table
disp('Data table:');
disp(dataTable);

% Extract columns from the table
groups = dataTable.Groups; % Between-subjects factor (e.g., Male/Female)
animals = dataTable.Animals; % Subject IDs
epochs = dataTable{:, startsWith(dataTable.Properties.VariableNames, 'Epoch')}; % Repeated measures

% Number of subjects and epochs
[numSubjects, numEpochs] = size(epochs);

% Repeated Measures ANOVA
% Create a repeated measures design
rm = fitrm(dataTable, sprintf('Epochs_1-Epochs_%d ~ Groups', numEpochs), ...
           'WithinDesign', table((1:numEpochs)', 'VariableNames', {'Epochs'}));

% Perform ANOVA
ranovaResults = ranova(rm);
disp('Repeated Measures ANOVA Results:');
disp(ranovaResults);

% Check interaction effect (Groups x Epochs)
interactionP = ranovaResults.pValue(2); % Assuming interaction is the second term
if interactionP < 0.05
    disp('Significant interaction found (Groups x Epochs). Proceeding with post-hoc analysis.');
else
    disp('No significant interaction found. Post-hoc analysis may not be meaningful.');
end

% Post-hoc analysis: Pairwise comparisons
% Calculate pairwise differences for each group and epoch
disp('Post-hoc pairwise comparisons:');
epochNames = dataTable.Properties.VariableNames(startsWith(dataTable.Properties.VariableNames, 'Epoch'));
groupNames = unique(groups);

% Loop through groups and epochs for pairwise tests
for g = 1:length(groupNames)
    groupData = epochs(strcmp(groups, groupNames{g}), :); % Data for each group
    
    % Pairwise t-tests between epochs for this group
    fprintf('\nPost-hoc comparisons within group: %s\n', groupNames{g});
    for i = 1:numEpochs-1
        for j = i+1:numEpochs
            [h, p, ci, stats] = ttest(groupData(:, i), groupData(:, j));
            fprintf('Epoch %d vs Epoch %d: t(%d) = %.3f, p = %.4f\n', ...
                i, j, stats.df, stats.tstat, p);
        end
    end
end

% Between-group comparisons for each epoch
disp('Between-group comparisons for each epoch:');
for e = 1:numEpochs
    epochData = epochs(:, e); % Data for current epoch
    [p, tbl, stats] = anova1(epochData, groups, 'off'); % One-way ANOVA for groups at this epoch
    fprintf('Epoch %d: F(%d, %d) = %.3f, p = %.4f\n', ...
        e, tbl{2, 3}, tbl{3, 3}, tbl{2, 5}, p);
    if p < 0.05
        disp('  Significant difference found. Performing post-hoc tests...');
        multcompare(stats, 'CType', 'lsd'); % Bonferroni correction
    else
        disp('  No significant difference between groups.');
    end
end
