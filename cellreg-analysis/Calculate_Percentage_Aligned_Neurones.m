function [animals_to_exclude,Percentages_list] = Calculate_Percentage_Aligned_Neurones(x,loadedDataGoodNeurones_test1,loadedDataGoodNeurones_test2,loadedDataCellReg)
    
    animals_to_exclude = [];
    Percentages_list = [];
    
    for i=1:x
        if isa(loadedDataGoodNeurones_test1{i}, 'struct') & isa(loadedDataGoodNeurones_test2{i}, 'struct')
            counter = 0;
            table_cellregt = loadedDataCellReg{1,i}.cell_registered_struct.cell_to_index_map;
            for y=1:length(loadedDataGoodNeurones_test1{i}.good_neurons_indices);
                index = loadedDataGoodNeurones_test1{i}.good_neurons_indices(y);
                idx = find(table_cellregt(:,1) == index);
                if ~isempty(idx) & ~ismember(0,table_cellregt(idx,:))
                    index_second_test = table_cellregt(idx,2);
                    index_second_test = find(loadedDataGoodNeurones_test2{i}.good_neurons_indices == index_second_test);
                    if ~isempty(index_second_test)
                        counter = counter + 1;     
                    end
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
end