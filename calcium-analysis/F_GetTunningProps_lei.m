 function [Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance, Responses] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
     ReferenceEpochs, Dataset, Iterations)
%F_GETTUNNINGPROPS Summary of this function goes here
%   Detailed explanation goes here
%% STEP 1 - GENERATING THE STORAGE OUTPUTS
Expected = [];
Observed = [];
StandDevs = [];
STD_Distance = [];
Active = [];
Inhibited = [];
AllTraces = [];
Report = [];
lengths = [];
ResponseType = [];
AnimalPerNeuron = [];
SexPerNeuron = [];
OutputPath = Experiment.Project.Outputpath;
save_path = strcat(OutputPath, "\", join(TunningEpochs, " - "), ...
    " Tunning ", string(datetime(floor(now),'ConvertFrom','datenum'))); %#ok<TNOW1> 
prompt = strcat("   Results will be saved @ ", save_path);
Report = [Report; prompt; ""];
fprintf('% s\n', prompt)
% And the storage site
mkdir(save_path)


%% STEP 2 - IDENTIFYING OUTLIERS BEFORE PERFORMING THE TEST
% Identifying the animals


an_s = fieldnames(Dataset);


Animals = string(regexp(string(an_s(1:end)), '\d*', 'Match'));


% Finding all trial lengths;
c = 1;
for animal = Animals.'
    
   lengths(c) = size(Dataset.('M'+animal).("Raw"), 2);
   c = c+1;
   
end

% Identifying outliers
outliers = isoutlier(lengths, "mean");

% Reporting outliers to the user
for i = 1:sum(outliers)
    out_an = Animals(outliers);
    out_len = string(lengths(outliers));
    prompt = strcat("       Animal ", ...
        out_an(i), " was identified as an outlier with ",  ...
        out_len(i), ' frames.');
    fprintf('%s\n', prompt)
    Report = [Report; "   OUTLIER DETECTION:"; prompt];
end

% Visualising the outliers
boxplot(lengths)
xticks([])
ylabel("Frames (n)")

% Croppig all sessions and notifying the user
len = min(lengths);




% prompt = strcat("       All sessions will be cropped to ", ...
% num2str(len*timeframe/1000), " seconds.");
% Report = [Report; prompt; ""];
% fprintf('%s\n', prompt)

% Removing outliers
Animals = Animals(outliers == 0);

% Saving current figure
savename = strcat(save_path, "\Tunning - Outliers.pdf");
exportgraphics(gcf, savename, "ContentType", "vector")

%% STEP 3 - GENERATING MAIN USER'S AND STATISTICS OUTPUT TABLE
% Generating the output table
Output = table()
Output.Animal = double(Animals)
Sexes = string(Experiment.Project.Groups)
Output.Sex = Sexes(Output.Animal);

% Adjusting column names based on TunningEpochs content
if strcmp(TunningEpochs, "ROI")
    % Case when all ROIs are analyzed
    Excited_ColName = "All ROI Active IX";
    Inhibited_ColName = "All ROI Inactive IX";
    ExcitedP_ColName = "Probability of All ROI Active";
    InhibitedP_ColName = "Probability of All ROI Inactive";
elseif startsWith(TunningEpochs, "ROI")
    % Case when a specific ROI is analyzed
    Excited_ColName = strcat(TunningEpochs, " Active IX");
    Inhibited_ColName = strcat(TunningEpochs, " Inactive IX");
    ExcitedP_ColName = strcat("Probability of ", TunningEpochs, " Active");
    InhibitedP_ColName = strcat("Probability of ", TunningEpochs, " Inactive");
end

% Generating the storage variable columns
Output.(Excited_ColName) = repelem({""}, length(Animals)).';
Output.(Inhibited_ColName) = repelem({""}, length(Animals)).';
Output.(ExcitedP_ColName) = zeros(length(Animals), 1);
Output.(InhibitedP_ColName) = zeros(length(Animals), 1);

% For figures
Ep_ = {ExcitedP_ColName, InhibitedP_ColName};
%% STEP 5 - PERFORMING THE TEST
% Looping through animals
c = 1; % Counter function
all_binarised=[];
max_len = 0;

for an = Animals.'
    wb_ = waitbar(0, strcat("Identifying responsive neurons in animal ", num2str(an)));
    prompt = strcat("   Processing animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];

    
        

    % Generación de TOI y TOR específicos para cada animal
    Task = Dataset.(strcat('M', num2str(an))).Task; % Accediendo a la Task de cada animal
    length(Task.Titles)
    TOI = []; % Time of Interest
    TOR = []; % Time of Reference

    if strcmp(TunningEpochs, "ROI")
        % Caso cuando se analizan todos los ROIs
        for i = 1:length(Task.Titles)
            if startsWith(Task.Titles{i}, "ROI")
                TOI = [TOI, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            else 
                TOR = [TOR, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            end
        end
    elseif startsWith(TunningEpochs, "ROI")
        % Caso cuando se analiza un ROI específico
        for i = 1:length(Task.Titles)
            %disp(['i = ', num2str(i), ' Task.Start(i) = ', num2str(Task.Start(i)), ' Task.End(i) = ', num2str(Task.End(i))])

            if startsWith(Task.Titles{i}, "NO_ROI") || startsWith(Task.Titles{i}, "ROI1")  
                if i == length(Task.Titles) && (Task.Start(i)>Task.End(i))
                    
                    break
                else
                    TOR = [TOR, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
                end
            end
            if startsWith(Task.Titles{i}, TunningEpochs)
                if (i == length(Task.Titles) && (Task.Start(i)>Task.End(i))) || ((Task.Start(i)+Task.Frames(i)>Task.End(end)))
                    break
                else    
                    TOI = [TOI, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
                end
            end

        end
    end
   
    length(TOR)
    
    length(TOI)
    % Creación del binarizado para comparación
    len_an = length(Dataset.(strcat('M', num2str(an))).Raw); % Longitud de las trazas neuronales del animal
    BinarisedTask = repelem("0", len_an);
    BinarisedTask(TOI) = "1";
    disp('BT')
    disp(size(BinarisedTask))
    %max_len = max(max_len, len);

    % Convertir BinarisedTask a número (para poder usar NaN)
    %BinarisedTaskNumeric = double(string(BinarisedTask) == "1");

    % Aquí continúa el análisis como en la versión anterior
    % Gathering the animal specific data
    Maxims = double(islocalmax(Dataset.(strcat('M', num2str(an))).Filt(:, 1:len_an), 2));
    Peaks = string(Maxims);
    disp('Peaks')
    disp(size(Peaks))
    Intersect = BinarisedTask + Peaks;
    % Identifying the parameters for each neuron
    oo = sum(Intersect == "00", 2);
    lo = sum(Intersect == "10", 2);
    ol = sum(Intersect == "01", 2);
    ll = sum(Intersect == "11", 2);

    Obv = F_ComputePhi(oo, ol, lo, ll);
    % Computing Phi
    Observed = [Observed; Obv];

    % Iterating to attain the expected
    % Expected_Scores = gpuArray(zeros(size(Maxims, 1), Iterations));
    Expected_Scores = zeros(size(Maxims, 1), Iterations);

    for iter = 1:Iterations
        waitbar(iter/Iterations);
        Rand_Peaks = Peaks(:, randperm(len_an));
        Intersect_Rand = BinarisedTask + Rand_Peaks;
        oo = sum(Intersect_Rand == "00", 2);
        lo = sum(Intersect_Rand == "10", 2);
        ol = sum(Intersect_Rand == "01", 2);
        ll = sum(Intersect_Rand == "11", 2);
        Expected_Scores(:, iter) = F_ComputePhi(oo, ol, lo, ll);
    end

    Exp = mean(Expected_Scores, 2);
    Expected = [Expected; Exp];
    SDs = std(Expected_Scores, [], 2);
    StandDevs = [StandDevs; SDs];
    Distances = (Obv - Exp) ./ SDs;
    
    STD_Distance = [STD_Distance; Distances];

    % Saving the activated and inhibited neurons
    
    size(Dataset.(strcat('M', num2str(an))).Filt(Distances > 1.96, 1:len))
    Active = [Active; Dataset.(strcat('M', num2str(an))).Filt(Distances > 1.96, 1:len)];
    size(Active)
    Inhibited = [Inhibited; Dataset.(strcat('M', num2str(an))).Filt(Distances < -1.96, 1:len)];
    % All traces
    AllTraces = [AllTraces; Dataset.(strcat('M', num2str(an))).Filt(:, 1:len)];

    % Saving the results in the output table
    Excit = find(Distances > 1.96);
    Inhibit = find(Distances < -1.96);
    Output.(Excited_ColName)(c) = {Excit};
    Output.(Inhibited_ColName)(c) = {Inhibit};
    Output.(ExcitedP_ColName)(c) = 100 * length(Excit) / size(Maxims, 1);
    Output.(InhibitedP_ColName)(c) = 100 * length(Inhibit) / size(Maxims, 1);

    % For the frequency test
    Tunning_ = repelem("Unresponsive", length(Distances));
    Tunning_(Excit) = "Excited";
    Tunning_(Inhibit) = "Inhibited";
    ResponseType = [ResponseType, Tunning_];

    % Saving the animal and sex information
    AnimalPerNeuron = [AnimalPerNeuron, repelem(an, length(Distances))]
    SexPerNeuron = [SexPerNeuron; repmat({Experiment.Project.Groups{double(an)}}, length(Distances), 1)];
    length(SexPerNeuron)
    prompt = strcat("       ", num2str(length(Excit)), " stimulus-excited neurons have been identified for animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];
    prompt = strcat("       ", num2str(length(Inhibit)), " stimulus-inhibited neurons have been identified for animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];

    % Si BinarisedTask es más corto que el más largo hasta ahora, rellenar con NaN
    % if len_an < max_len
    %     BinarisedTaskNumeric = [BinarisedTaskNumeric, nan(1, max_len - len_an)];
    % end
    
    % Añadir BinarisedTask a la matriz all_binarised
    all_binarised = [all_binarised; BinarisedTask(1:len)];

    c = c + 1;
    close(wb_);
end
length(Distances)
Output
%% STEP 6 - GENERATING THE VISUALISATIONS
% First figure - Methods
    [~, sort_ix] = sort(Observed);
    F_FillArea(Expected(sort_ix).', (StandDevs(sort_ix).*1.96).', ...
        'k', 1:length(Expected(sort_ix)))
    hold on
    plot(Expected(sort_ix), "Color", 'k')
    hold on
    plot(Observed(sort_ix), "Color", 'r', "LineWidth", 2)
    O = Observed(sort_ix);
    STD_Sorted = STD_Distance(sort_ix);
    sig_ix = find(abs(STD_Sorted) > 1.96);
    scatter(sig_ix, O(sig_ix), 20, 'K', 'filled')
    hold off
    legend(["95% CI", "Expected", "Observed", "Significant"], ...
        "Location","northwest");
    xlim([1, length(Observed)])
    xlabel("Neuron", "FontSize", 12)
    ylabel("\phi Coefficient", "FontSize", 12)
    set(gcf,'Position',[400 100 300 400])
    box off
    hold off
    savename = strcat(save_path, "\Tunning - Neuron identification.pdf");
    exportgraphics(gcf, savename, "ContentType","vector")


% % Second figure - Sample
    % % For the active neurons - Calculating the error
    % close all
    % sem_ = std(Active, [], 1)./sqrt(size(Active, 1));
    % 
    % % Getting the axes
    % F_FillArea(mean(Active, 1), sem_, [212, 100, 66]./255, ...
    %     1:length(Active))
    % yl = ylim();
    % 
    % % Labelling areas of interest
    % area(double(BinarisedTask), 'EdgeColor','none', "FaceAlpha", .3, ...
    %     'FaceColor', 'k')
    % hold on
    % 
    % % Visualising the errors for the active neurons
    % F_FillArea(mean(Active, 1), sem_, [212, 100, 66]./255, ...
    %     1:length(Active))
    % % Viewing active neurons
    % plot(mean(Active, 1), "Color", [212, 100, 66]./255)
    % hold on
    % F_FillArea(mean(Inhibited, 1), sem_, [76, 148, 199]./255, ...
    %     1:length(Inhibited))
    % plot(mean(Inhibited, 1), "Color", [76, 148, 199]./255)
    % 
    % ylim([0, max(yl)])
    % xlim([1, length(Active)])
    % set(gcf, 'Position', [400, 100, 1200, 500])
    % box off
    % xlabel("Time (Frames)")
    % ylabel("Mean Fluorescence")
    % legend([join(TunningEpochs, ' & '), "", "Excited", "", "Inhibited"])
    % hold off
    % savename = strcat(save_path, "\Tunning - Group mean.pdf");
    % exportgraphics(gcf, savename, "Resolution", 1200)

% %Third figure - Individual-neuron level visualisation
%     close all
%     % Selecting the top five neurons;
%     Sorted = sort(Observed);
%     TopInactive = AllTraces(Observed < Sorted(6), :);
% 
%     % Getting the axes
%     area(double(BinarisedTask).*13, 'EdgeColor','none', ...
%         "FaceAlpha", .3, 'FaceColor', 'k')
%     hold on
%     for i = 1:5
%         plot(TopInactive(i, :) + i, "Color", [76, 148, 199]./255)
%         hold on
%     end
%     Sorted = flip(Sorted);
%     TopActive = AllTraces(Observed > Sorted(6), :);
%     for i = 7:11
% 
%         plot(TopActive(i-6, :)+i, "Color", [212, 100, 66]./255)
%         hold on
%     end
%     hold off
%     ylim([0, 13])
%     yticks([3, 9])
%     yticklabels({"Inhibited", "Excited"}); 
%     ytickangle(90)
%     xlabel("Time (Frames)")
%     ylabel("Filtered fluorescence")
%     xlim([1, size(AllTraces, 2)])
%     box off
%     Fig_ = gcf;
%     Fig_.Position = [400, 100, 600, 500];
%     savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
%     exportgraphics(gcf, savename, "ContentType", "vector")
%%
% % Third figure - Individual-neuron level visualization
% close all;
% Fig_ = figure;
% Fig_.Position = [400, 100, 600, 500];
% 
% % Selecting the top five excited and inhibited neurons;
% Sorted = sort(Observed, 'ascend');
% TopInactive = AllTraces(Observed <= Sorted(5), [1:3000]);
% TopActive = AllTraces(Observed >= Sorted(end-4), [1:3000]);
% 
% % Combine top neurons for plotting
% TopNeurons = [TopInactive; TopActive];
% %TopNeurons = normalize(TopNeurons, 2, 'range', [0, 1]);
% 
% AnimalPerNeuron=str2double(AnimalPerNeuron);
% alturaPorNeurona = 0.1;
% % Plot each neuron with its corresponding BinarisedTask
% for i = 1:size(TopNeurons, 1)
%     hold on;
% 
%     % Find out which animal this neuron belongs to
%     neuronIndex = find(ismember(AllTraces, TopNeurons(i, [1:3000])), 1, 'first');
% 
%     neuronAnimalIndex = AnimalPerNeuron(neuronIndex)
% 
%     % Obtiene los límites en Y para la neurona actual
%     YlimiteInferior = (i) * alturaPorNeurona;
%     YlimiteSuperior = (i+1) * alturaPorNeurona;
% 
%     % Obtiene el BinarisedTask para esta neurona
%     BinarisedTaskAnimal = double(all_binarised(neuronAnimalIndex, [1:3000]));
% 
%     % Encuentra los índices donde la neurona está activa
%     indicesActivos = find(BinarisedTaskAnimal == 1);
%     % Dibuja las franjas verticales para los índices activos
%     for idx = 1:length(indicesActivos)
%         j = indicesActivos(idx);
%         if j < length(BinarisedTaskAnimal)  % Asegurarse de que no estamos en el último índice
%             fill([j j j+1 j+1], [YlimiteInferior YlimiteSuperior YlimiteSuperior YlimiteInferior], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', .3);
%         end
%     end
% 
%     % Crea una nueva matriz para pintar solo donde BinarisedTaskAnimal es 1
%     % BinarisedTaskParaPintar = zeros(size(BinarisedTaskAnimal));
%     % BinarisedTaskParaPintar(BinarisedTaskAnimal == 1) = YlimiteSuperior;
% 
% 
%     % % Ajusta BinarisedTaskAnimal para pintarlo solo en la sección de esta neurona
%     % BinarisedTaskAnimal = BinarisedTaskAnimal * (YlimiteSuperior -YlimiteInferior) + YlimiteInferior;
% 
%     % Plot the BinarisedTask for this neuron
%     %area(BinarisedTaskAnimal .* 13, 'EdgeColor', 'none', 'FaceAlpha', .3, 'FaceColor', [0.8 0.8 0.8]);
%     % Dibuja el área ajustada
%     %area(BinarisedTaskParaPintar, 'EdgeColor', 'none', "FaceAlpha", .3, 'FaceColor', [0.8 0.8 0.8]);
%     % Determine the color based on the index
%     if i <= 5
%         color = [76, 148, 199]./255; % Blue for inhibited neurons
%     else
%         color = [212, 100, 66]./255; % Red for excited neurons
%     end
% 
%     % Plot the neuron trace
%     plot(TopNeurons(i, :) + (i * 0.1), 'Color', color)
% end
% 
% % Formatting the plot
% ylim([0, size(TopNeurons, 1) * 0.1 + 0.1]);
% xlim([1, size(TopNeurons, 2)])
% xlabel("Time (Frames)");
% ylabel("Filtered fluorescence");
% set(gca, 'YTick', 0.1:0.1:size(TopNeurons, 1) * 0.1);
% set(gca, 'YTickLabel', arrayfun(@(x) sprintf('Neuron %d', x), 1:size(TopNeurons, 1), 'UniformOutput', false));
% % box off;
% 
% % Save the figure
% savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
% exportgraphics(Fig_, savename, "ContentType", "vector");
%%
% Third figure - Individual-neuron level visualization
close all;
Fig_ = figure;
Fig_.Position = [400, 100, 600, 500];

% Selecting the top five excited and inhibited neurons;
Sorted = sort(Observed, 'ascend');
TopInactive = AllTraces(Observed <= Sorted(5), :);
TopActive = AllTraces(Observed >= Sorted(end-4),:);

% Combine top neurons for plotting
TopNeurons = [TopInactive; TopActive];
%TopNeurons = normalize(TopNeurons, 2, 'range', [0, 1]);
% Define el espacio inicial para la primera neurona
espacioInicial = 0.1;

% Almacena la altura acumulada para saber dónde comenzar la siguiente neurona
alturaAcumulada = 0;

AnimalPerNeuron=str2double(AnimalPerNeuron);
alturaPorNeurona = 0.1;
% Plot each neuron with its corresponding BinarisedTask
for i = 1:size(TopNeurons, 1)
    hold on;
    
    % Find out which animal this neuron belongs to
    neuronIndex = find(ismember(AllTraces, TopNeurons(i, :)), 1, 'first');
    
    neuronAnimalIndex = AnimalPerNeuron(neuronIndex)
    
    % Calcular el pico más alto para la traza actual
    picoMasAlto = max(TopNeurons(i, :));
    
    % Calcular los límites en Y para la neurona actual basándose en el pico más alto
    YlimiteInferior = alturaAcumulada + espacioInicial;
    YlimiteSuperior = YlimiteInferior + picoMasAlto;
    
    % Actualizar la altura acumulada para la siguiente neurona
    alturaAcumulada = YlimiteSuperior + espacioInicial;

    % Obtiene el BinarisedTask para esta neurona
    BinarisedTaskAnimal = double(all_binarised(neuronAnimalIndex, :));

    % Encuentra los índices donde la neurona está activa
    indicesActivos = find(BinarisedTaskAnimal == 1);
    % Dibuja las franjas verticales para los índices activos
    for idx = 1:length(indicesActivos)
        j = indicesActivos(idx);
        if j < length(BinarisedTaskAnimal)  % Asegurarse de que no estamos en el último índice
            fill([j j j+1 j+1], [YlimiteInferior YlimiteSuperior YlimiteSuperior YlimiteInferior], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', .3);
        end
    end

    % Crea una nueva matriz para pintar solo donde BinarisedTaskAnimal es 1
    % BinarisedTaskParaPintar = zeros(size(BinarisedTaskAnimal));
    % BinarisedTaskParaPintar(BinarisedTaskAnimal == 1) = YlimiteSuperior;


    % % Ajusta BinarisedTaskAnimal para pintarlo solo en la sección de esta neurona
    % BinarisedTaskAnimal = BinarisedTaskAnimal * (YlimiteSuperior -YlimiteInferior) + YlimiteInferior;
    
    % Plot the BinarisedTask for this neuron
    %area(BinarisedTaskAnimal .* 13, 'EdgeColor', 'none', 'FaceAlpha', .3, 'FaceColor', [0.8 0.8 0.8]);
    % Dibuja el área ajustada
    %area(BinarisedTaskParaPintar, 'EdgeColor', 'none', "FaceAlpha", .3, 'FaceColor', [0.8 0.8 0.8]);
    % Determine the color based on the index
    if i <= 5
        color = [76, 148, 199]./255; % Blue for inhibited neurons
    else
        color = [212, 100, 66]./255; % Red for excited neurons
    end
    
    % Plot the neuron trace
    plot(TopNeurons(i, :) + YlimiteInferior, 'Color', color);
end
% Ajustar los límites del gráfico para acomodar todas las trazas
ylim([0, alturaAcumulada]);
xlim([1, size(TopNeurons, 2)])
xlabel("Time (Frames)");
ylabel("Filtered fluorescence");
%set(gca, 'YTick', arrayfun(@(y) y + espacioInicial, 0:alturaAcumulada/size(TopNeurons, 1):alturaAcumulada, 'UniformOutput', false));
set(gca, 'YTickLabel', arrayfun(@(x) sprintf('Neuron %d', x), 1:size(TopNeurons, 1), 'UniformOutput', false));
% Formatting the plot
% ylim([0, size(TopNeurons, 1) * 0.1 + 0.1]);
% xlim([1, size(TopNeurons, 2)])
% xlabel("Time (Frames)");
% ylabel("Filtered fluorescence");
% set(gca, 'YTick', 0.1:0.1:size(TopNeurons, 1) * 0.1);
% set(gca, 'YTickLabel', arrayfun(@(x) sprintf('Neuron %d', x), 1:size(TopNeurons, 1), 'UniformOutput', false));
% box off;

% Save the figure
savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
exportgraphics(Fig_, savename, "ContentType", "vector");

%Third figure - Individual-neuron level visualisation
% close all;
% Fig_ = figure;
% Fig_.Position = [400, 100, 600, 500];
% 
% % Selecting the top five neurons;
% Sorted = sort(Observed);
% TopInactive = AllTraces(Observed < Sorted(6), :);
% TopActive = AllTraces(Observed > Sorted(end-5), :);
% TopNeurons = [TopInactive; TopActive];  % Combine for ease of access
% 
% for i = 1:size(TopNeurons, 1)
%     % Find out which animal this neuron belongs to
%     neuronAnimalIndex = AnimalPerNeuron(i);
% 
%     % Extract the BinarisedTask for this animal
%     neuronBinarisedTask = all_binarised(neuronAnimalIndex, :);
% 
%     % Overlay the BinarisedTask area for this neuron
%     area(neuronBinarisedTask * 13, 'EdgeColor', 'none', 'FaceAlpha', .3, 'FaceColor', 'k');
%     hold on;
% 
%     % Plot the neuron trace
%     plot(TopNeurons(i, :) + i*2, 'Color', [76, 148, 199]./255); % Adjust color as needed
% end
% 
% ylim([0, 13+size(TopNeurons, 1)*2])
% yticks([3, 9])
% yticklabels({"Inhibited", "Excited"}); 
% ytickangle(90)
% xlabel("Time (Frames)")
% ylabel("Filtered fluorescence")
% xlim([1, size(all_binarised, 2)])
% box off
% hold off;
% 
% savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
% exportgraphics(Fig_, savename, "ContentType", "vector");

%     % Third figure - Individual-neuron level visualisation
% close all;
% % Initialize the figure
% Fig_ = figure;
% Fig_.Position = [400, 100, 600, 500];
% 
% % Selecting the top five excited and inhibited neurons;
% Sorted = sort(Observed);
% TopInactive = AllTraces(Observed < Sorted(6), :);
% TopActive = AllTraces(Observed > Sorted(end-5), :);
% 
% % Combine top neurons for plotting
% TopNeurons = [TopInactive(1:5, :); TopActive(1:5, :)];
% 
% % Plot settings
% colors = {[76, 148, 199]./255, [212, 100, 66]./255}; % Blue for inhibited, Red for excited
% labels = {"Inhibited", "Excited"};
% ytickloc = [3, 9];
% 
% % Plot each neuron with its corresponding BinarisedTask
% for i = 1:size(TopNeurons, 1)
%     subplot(size(TopNeurons, 1), 1, i);
%     hold on;
% 
%     % Find the corresponding animal for this neuron
%     neuronIndex = find(AllTraces == TopNeurons(i, :), 1);
%     correspondingAnimal = AnimalPerNeuron(neuronIndex);
% 
%     % Generate the specific BinarisedTask for this animal
%     animalTask = Dataset.(strcat('M', num2str(correspondingAnimal))).Task;
%     len_animal = size(Dataset.(strcat('M', num2str(correspondingAnimal))).Raw, 2);
%     BinarisedTaskAnimal = zeros(1, len_animal);
%     for j = 1:length(animalTask.Titles)
%         if startsWith(animalTask.Titles{j}, "ROI")
%             BinarisedTaskAnimal(animalTask.Start(j):(animalTask.Start(j)+animalTask.Frames(j)-1)) = 1;
%         end
%     end
% 
%     % Plot the BinarisedTask for this neuron
%     area(BinarisedTaskAnimal.*13, 'EdgeColor','none', 'FaceAlpha', .3, 'FaceColor', 'k');
% 
%     % Plot the neuron trace
%     plot(TopNeurons(i, :) + ytickloc(ceil(i/5)), 'Color', colors{ceil(i/5)});
% 
%     % Formatting
%     ylim([0, 14]);
%     xlim([1, len_animal]);
%     if i == size(TopNeurons, 1)
%         xlabel("Time (Frames)");
%     end
%     ylabel(labels{ceil(i/5)});
%     set(gca, 'YTick', ytickloc, 'YTickLabel', labels, 'YTickLabelRotation', 90);
% end
% 
% % Save the figure
% savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
% exportgraphics(Fig_, savename, "ContentType", "vector");

% % Third figure - Individual-neuron level visualisation
% close all;
% Fig_ = figure; % Inicializa la figura
% Fig_.Position = [400, 100, 600, 500]; % Establece la posición y tamaño de la figura
% 
% % Selecciona las cinco neuronas con puntuaciones más bajas y más altas.
% Sorted = sort(Observed);
% TopInactive = AllTraces(Observed < Sorted(6), :);
% TopActive = AllTraces(Observed > Sorted(end-5), :);
% 
% % Determina la altura de las trazas en la figura
% traceHeight = max([TopInactive(:); TopActive(:)]) * 0.1; % Altura ajustable de las trazas
% 
% % Inicializa las variables para las leyendas
% handles = [];
% labels = {};
% 
% % Grafica todas las neuronas, primero las inactivas y luego las activas.
% for i = 1:10
%     if i <= 5
%         neuronTrace = TopInactive(i, :);
%         color = [76, 148, 199]./255; % Color para neuronas inactivas
%     else
%         neuronTrace = TopActive(i-5, :);
%         color = [212, 100, 66]./255; % Color para neuronas activas
%     end
% 
%     % Encuentra el índice de la neurona en AllTraces
%     neuronIndex = find(AllTraces == neuronTrace, 1);
%     % Encuentra el animal correspondiente a esta neurona
%     correspondingAnimal = AnimalPerNeuron(neuronIndex);
% 
%     % Grafica la traza de la neurona
%     plot(neuronTrace + (i-1) * traceHeight, 'Color', color)
%     hold on;
% 
%     % Genera la BinarisedTask para este animal específico
%     animalTask = Dataset.(strcat('M', num2str(correspondingAnimal))).Task;
%     BinarisedTaskAnimal = zeros(1, length(neuronTrace));
%     for j = 1:length(animalTask.Titles)
%         if startsWith(animalTask.Titles{j}, "ROI")
%             BinarisedTaskAnimal(animalTask.Start(j):(animalTask.Start(j)+animalTask.Frames(j)-1)) = 1;
%         end
%     end
% 
%     % Grafica las áreas de interés de la BinarisedTask para esta neurona
%     h = area(BinarisedTaskAnimal .* (i * traceHeight + traceHeight/2), 'EdgeColor','none', 'FaceAlpha', .3, 'FaceColor', color)
%     if i <= 5
%         labels{end+1} = "Inhibited";
%     else
%         labels{end+1} = "Excited";
%     end
%     handles(end+1) = h;
% end
% 
% % Formatea la figura
% ylim([0, i * traceHeight]);
% xlabel("Time (Frames)");
% ylabel("Neuron Index");
% set(gca, 'YTick', traceHeight:traceHeight:i*traceHeight, 'YTickLabel', 1:i); % Etiquetas para cada neurona
% legend(handles, labels); % Leyenda para cada tipo de neurona
% 
% % Guarda la figura
% savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
% exportgraphics(gcf, savename, "ContentType", "vector");
% 
% Fourth figure - Ratios
    % Identifying the percentage of neuron tunning
    close all
    
    Properties = [sum(STD_Distance > 1.96, 'All'), ...
        sum(STD_Distance < -1.96, 'All')];
    Properties(end+1) = length(STD_Distance) - sum(Properties);
    pie(Properties)
    ax = gca();
    ax.Colormap = [212, 100, 66; 76, 148, 199; 200, 200, 200]./255; 
    legend(["Active", "Inactive", "Unresponsive"], "Location", ...
        "northeast")
    F_ = gcf;
    F_.Position = [400, 100, 390, 320];
    savename = strcat(save_path, "\Tunning - Ratios.pdf");
    exportgraphics(gcf, savename, "ContentType", "vector")


%%
% Fifth figure - Distinction between conditions
% Generating the first subplot
% Convertir los valores de Output.Sex a tipo char para poder usarlos como claves
% uniqueSexChar = cellstr(unique(Output.Sex, 'stable'));
% 
% % Obtener los colores para cada grupo usando el mapa Palette
% colourValues = values(Experiment.Project.Palette, uniqueSexChar);
% 
% % Inicializar la matriz de colores
% colours = zeros(length(colourValues), 3); % Asumiendo que los colores son RGB
% 
% % Rellenar la matriz de colores
% for i = 1:length(colourValues)
%     currentColour = colourValues{i};
%     if isnumeric(currentColour)
%         colours(i, :) = currentColour;
%     elseif iscell(currentColour) && isnumeric(currentColour{1})
%         colours(i, :) = currentColour{1};
%     else
%         error('El formato del color no es reconocido o compatible.');
%     end
% end
% 
% close all;
% yls = [];
% subplot(1, 2, 1);
% disp(Output.(ExcitedP_ColName));
% boxplot(Output.(ExcitedP_ColName), Output.Sex, "Colors", 'k');
% colours = flip(colours, 1); % Asegúrate de que los colores estén en el orden correcto después de ajustarlos
% 
% f = findobj(gca, 'Tag', 'Box');
% for i = 1:length(f)
%     patch(get(f(i),'XData'),get(f(i),'YData'), colours(i,:), 'FaceAlpha',.6);
% end
% h = findobj('LineStyle', '--'); set(h, 'LineStyle', '-');
% box off;
% hold on;
% ylabel("Tunned neurons (%)");
% xlabel("Excited");
% yls = [yls; ylim()];
% 
% subplot(1, 2, 2);
% boxplot(Output.(InhibitedP_ColName), Output.Sex, "Colors", 'k');
% f = findobj(gca, 'Tag', 'Box');
% for i = 1:length(f)
%     patch(get(f(i),'XData'),get(f(i),'YData'), colours(i,:), 'FaceAlpha',.6);
% end
% h = findobj('LineStyle', '--'); set(h, 'LineStyle', '-');
% xlabel("Inhibited");
% h = gca;
% h.YAxis.Visible = 'off';
% box off;
% yls = [yls; ylim()];
% ylim([min(yls(:, 1)), max(yls(:, 2))]);
% 
% savename = strcat(save_path, "\Tunning - Group Differences.pdf");
% exportgraphics(gcf, savename, "ContentType", "vector");
% close all;
%% STEP 7 - CLOSING
% Saving the report
savename = strcat(save_path, "\Report.txt");
writelines(Report,savename);
% And the data
savename = strcat(save_path, "\TunningOutput.mat");
Tunning = Output;
save(savename, "Tunning");

% Generating the frequency table
Responses = table();
size(SexPerNeuron)
size(ResponseType)
size(AnimalPerNeuron)
Responses.Sex = SexPerNeuron;
Responses.Animal = AnimalPerNeuron.';
Responses.ResponseType = ResponseType.';

% And saving it
savename = strcat(save_path, "\SingleNeuronResponses.mat");
save(savename, "Responses");
savename_chi = strcat(save_path, "\SingleNeuronResponses.csv");
writetable(Responses, savename_chi);

%% STEP 8 - STATS
% Save Table of Data
% savename = strcat(save_path, "\TunningOutput.csv");
% StatsTable = table();
% StatsTable.Sex = Output.Sex;
% StatsTable.Animal = Output.Animal;
% StatsTable.(ExcitedP_ColName) = Output.(ExcitedP_ColName);
% StatsTable.(InhibitedP_ColName) = Output.(InhibitedP_ColName);
% writetable(StatsTable, savename);
% 
% % Make Table of Variables 
% GroupBy = "Sex";
% Variable1 = ExcitedP_ColName;
% Variable2 = InhibitedP_ColName;
% Id = "Animal";
% DatasetPath = string(savename);
% NewFolderName = "StatResults";
% NewFolderPath = strcat(save_path, "\", NewFolderName);
% DatasetPath_ChiTest = string(savename_chi)
% 
% F_MakeCSVForStat(GroupBy, Variable1, Variable2, Id, DatasetPath, NewFolderPath, DatasetPath_ChiTest);
% 
% % Run R Script of Analysis
% ScriptPath = strcat('', pwd, '\BoxTestAndANOVA.R')
% F_RunRScript(ScriptPath)


end