function [Output,tempTable,ser] = F_MergeEpochs_lei(SourceTable, Variable, Episodes,...
    Cathegory, Task, Pre_Frames, Post_Frames,MaxFrames)
% Temporary storage of the tables
tables = {};
Cat = [];
Episodes;
% Looping through the columns
c = 1;  % Counter function
for ser = Episodes.'
    tempTable = F_SelectEpoch_lei(SourceTable, Variable, ser', Task, ...
        Pre_Frames, Post_Frames,MaxFrames);
    %disp([ ser.']);
    tables{c} = tempTable;
    Cat = [Cat, repelem(Cathegory(c), size(tables{c}, 1))];
    c = c+1;
end

% for i = 1:length(tables)
%     disp(size(tables{i}));
% end
Output = vertcat(tables{:}); % Merges
Output.Cathegory = Cat.';

% Sorting
[~, idx] = ismember(Output.Cathegory, unique(Cathegory, 'stable'));
[~, sortorder] = sort(idx);
Output = Output(sortorder,:);

end