function Experiment = adjustExperimentInfo(Experiment, animalsIndexToRemove)
    % Make sure that animalsIndexToRemove is an array sorted from lowest to highest
    animalsIndexToRemove = sort(animalsIndexToRemove, 'descend');
    
    % Iterate over each animal index to remove
    for i = 1:length(animalsIndexToRemove)
        animalIndexToRemove = animalsIndexToRemove(i);
        animalToRemove = sprintf('M%d', animalIndexToRemove); 
        
        % Remove the animalRs information from the OR substructure
        if isfield(Experiment.OR, animalToRemove)
            Experiment.OR = rmfield(Experiment.OR, animalToRemove);
        end
        
        % Remove the corresponding Groups entry for the removed animal
        Experiment.Project.Groups(animalIndexToRemove,:) = [];
    end
    
    % Adjust the number of animals to the length of the updated Groups
    Experiment.Project.Animals = numel(Experiment.Project.Groups(:,1));
    
    % Rename the remaining animal keys in OR to reflect the correct indices
    animalFields = fieldnames(Experiment.OR); 
    for i = 1:length(animalFields)
        correctIndex = sprintf('M%d', i);
        if ~strcmp(animalFields{i}, correctIndex)
            Experiment.OR.(correctIndex) = Experiment.OR.(animalFields{i});
            Experiment.OR = rmfield(Experiment.OR, animalFields{i});
        end
    end
end