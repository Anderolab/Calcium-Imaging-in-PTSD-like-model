function [Matrics_Early] = Add_Neuron_Index_Good(good_neurones,Matrics_Early,loadeddataGoodNeurones, test, animal_list)

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
    
    nameColumn = ['Index_', test];
    index_column = table(index_column', 'VariableNames', {nameColumn});
    Matrics_Early = [Matrics_Early(:,1:2) index_column Matrics_Early(:,3:end)]; 

end