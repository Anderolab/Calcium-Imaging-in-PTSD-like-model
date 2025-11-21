%% STEP 1 - LOADING THE REQUIRED DATASETSEPMOF
output_path = "D:\Ex3_BLA\Calcium RESULTS\SPT_metricas";
addpath(genpath('D:\CAIMAN\src'))
target_path = output_path + "\SPT_female_cort" + string(datetime(floor(now),'ConvertFrom','datenum'));
mkdir(target_path)

% Loading and fixing the required datasets

[filename, filepath] = uigetfile('*.mat', 'Select a MAT File to Load');

if isequal(filename, 0)  % If user cancels the file selection
    disp('File selection canceled');
else
    load(fullfile(filepath, filename));  % Directly load the selected file
end

Experiment.Project.Outputpath = target_path

%Adapatar todos los animales a los frames del animal con minFrames1

% if any(contains(fieldnames(Experiment),"SPT"))
%     Experiment=SPTexperiment(Experiment);
% end
%% Nuevos colores en formato RGB
new_color_CORT = [0.341, 0.341, 0.976];
new_color_VEH = [0.784, 0.871, 0.976];

% Actualizar la paleta de colores en Experiment.Project.Palette
Experiment.Project.Palette("CORT") = {new_color_CORT};
Experiment.Project.Palette("VEH") = {new_color_VEH};

% Mostrar la paleta actualizada para verificar los cambios
disp('Paleta de colores actualizada:');
disp(Experiment.Project.Palette);

%% Eliminate Bad Neurones

Experiment = eliminarMalasNeuronas(Experiment);


%% Choose animals to keep BE CAREFUL WITH SPT M6 MUST BE NOT CONSIDERED, FEMALE CORT ONLY REMOVE 4,5,6,7

Experiment = removeAnimalAndGroup(Experiment, [1,2,3,5,8,9,10,11,12]); % Remember to eliminate from the list the animals you want to keep

%% This part is only for EPM
% 
% % Obtén todos los nombres de los animales en Experiment.EPM
%  animals = fieldnames(Experiment.EPM);
% 
% % % Recorre cada animal
% for a = 1:length(animals)
%     animal = animals{a};  % Nombre del animal actual
%     % Obtén los títulos de las tareas del animal actual
%     titles = Experiment.EPM.(animal).Task.Titles;
% 
%     % Recorre cada título
%     for t = 1:length(titles)
%         title = titles{t};  % Título actual
% 
%         % Reemplaza 'ROI2' por 'ROI1'
%         if startsWith(title, 'ROI2')
%             newTitle = strrep(title, 'ROI2', 'ROI1');
%             Experiment.EPM.(animal).Task.Titles{t} = newTitle;
%         end
% 
%         % Reemplaza 'ROI3' por 'ROI2'
%         if startsWith(title, 'ROI3')
%             newTitle = strrep(title, 'ROI3', 'ROI2');
%             Experiment.EPM.(animal).Task.Titles{t} = newTitle;
%         end
% 
%         % Reemplaza 'ROI4' por 'ROI2'
%         if startsWith(title, 'ROI4')
%             newTitle = strrep(title, 'ROI4', 'ROI2');
%             Experiment.EPM.(animal).Task.Titles{t} = newTitle;
%         end
%     end
% end

% Mostrar algunos títulos modificados como verificación

%%
% 
% % Crear un nuevo containers.Map si Palette es un dictionary y no se puede manipular directamente
% newPalette = containers.Map({'CORT', 'VEH'}, ...
%                 {Experiment.Project.Palette('Male'), Experiment.Project.Palette('Female')});
% 
% % Ahora 'newPalette' tiene las nuevas claves con los mismos valores que las antiguas claves en 'Palette'
% Experiment.Project.Palette = newPalette;

%% STEP - SETTING THE INPUT FOR THE FUNCTION

% TunningFC = [];
% Definiendo el input para la función
Iterations = 1000; % 1000 for the real test
Neurons = Experiment.SPT % Asumiendo que 'Experiment.EPM' tiene los datos de neuronas

% Ejemplo: Analizar todos los ROIs
TunningEpochs = ["ROI1"]; % Todos los títulos que comiencen con "ROI" Always the reference ROI (like cenrter or object...)
ReferenceEpochs = ["NO_ROI","ROI2"]; % Usando "NO_ROI" como referencia (doesn't use it so can be whatever)
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_VEH] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Guardando los resultados
save('TuningOutput.mat', "Tunning");

%% Same as before, convenient if you are using more groups and want to run it all together
% TunningFC = [];
% Definiendo el input para la función
Iterations = 1000
Neurons = Experiment.SPT; % Asumiendo que 'Experiment.OF' tiene los datos de neuronas

% Ejemplo: Analizar todos los ROIs
TunningEpochs = ["NO_ROI"]; % Todos los títulos que comiencen con "ROI"
ReferenceEpochs = ["ROI2","ROI1"]; % Usando "NO_ROI" como referencia
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_CORT] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Guardando los resultados
save('TuningOutput.mat', "Tunning");

%% Same as before, convenient if you are using more groups and want to run it all together
% TunningFC = [];
% Definiendo el input para la función
Iterations = 1000
Neurons = Experiment.SPT; % Asumiendo que 'Experiment.OF' tiene los datos de neuronas

% Ejemplo: Analizar todos los ROIs
TunningEpochs = ["ROI2"]; % Todos los títulos que comiencen con "ROI"
ReferenceEpochs = ["NO_ROI","ROI1"]; % Usando "NO_ROI" como referencia
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_CORT] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Guardando los resultados
save('TuningOutput.mat', "Tunning");
%% Stats

% Paso 1: Define las categorías de respuesta esperadas
categoriasRespuestas = {'Unresponsive', 'Excited', 'Inhibited'};

% Paso 2: Convertir 'ResponseType' a datos categóricos con categorías definidas
respuestasCategCORT = categorical(Responses_CORT.ResponseType, categoriasRespuestas);
respuestasCategVEH = categorical(Responses_VEH.ResponseType, categoriasRespuestas);

% Paso 3: Contar las frecuencias para cada categoría
freqCORT = countcats(respuestasCategCORT);
freqVEH = countcats(respuestasCategVEH);

% Paso 4: Construir la tabla de contingencia
tablaContingencia = [freqCORT, freqVEH]';

% Paso 5: Realizar el test de chi-cuadrado
[tabla, chi2stat, chi2pValue] = crosstab([ones(size(Responses_CORT.ResponseType)); 2*ones(size(Responses_VEH.ResponseType))], ...
                                         [respuestasCategCORT; respuestasCategVEH]);

% Mostrar los resultados
disp('Tabla de contingencia:');
disp(tabla);
disp(['Estadístico de Chi-cuadrado: ', num2str(chi2stat)]);
disp(['P-valor: ', num2str(chi2pValue)]);

%%
% Calcular las medias de "Probability of ROI2 Excited" y "Probability of ROI2 Inhibited" para cada grupo
groups = {'VEH', 'CORT'};
meansExcited = zeros(1, length(groups));
meansInhibited = zeros(1, length(groups));

for i = 1:length(groups)
    group = groups{i};
    meansExcited(i) = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == group));
    meansInhibited(i) = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == group));
end

% Crear el gráfico de barras
figure;
barData = [meansExcited; meansInhibited]';
bar(barData, 'grouped');
set(gca, 'XTickLabel', groups);
ylabel('Probability (%)');
legend({'Excited', 'Inhibited'}, 'Location', 'Best');


% Mejorar la visualización
grid on;
box on;

%%
% Calcular las medias de "Probability of ROI2 Excited" y "Probability of ROI2 Inhibited" para cada grupo
meanExcitedVEH = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == "VEH"));
meanInhibitedVEH = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == "VEH"));

meanExcitedCORT = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == "CORT"));
meanInhibitedCORT = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == "CORT"));

% Generar los gráficos de tarta
figure;

% Gráfico para VEH
pie([meanExcitedVEH, meanInhibitedVEH]);
title('VEH: Mean Probability of ROI2 Excited vs. Inhibited');
legend({'Excited', 'Inhibited'}, 'Location', 'bestoutside');
figure;
% Gráfico para CORT

pie([meanExcitedCORT, meanInhibitedCORT]);
%title('CORT: Mean Probability of ROI2 Excited vs. Inhibited');
legend({'Excited', 'Inhibited'}, 'Location', 'bestoutside');
%%

% Extracting percentage of freez
Tones = fieldnames(Tunning);
%Tones = Tones(1:5)
Excited = [];
Inhibited = []; 
for tone = Tones.'

    % Finding column
    E_Field = Tunning.(tone{:}).Properties.VariableNames(...
        contains(Tunning.(tone{:}).Properties.VariableNames, ...
        ["Probability"]) + ...
        contains(Tunning.(tone{:}).Properties.VariableNames, ...
        ["Excited"]) == 2)
    Tunning.(tone{:})
    Tunning.(tone{:}).(E_Field{:})
    Excited = [Excited, Tunning.(tone{:}).(E_Field{:})]

    % Finding column
    I_Field = Tunning.(tone{:}).Properties.VariableNames(...
        contains(Tunning.(tone{:}).Properties.VariableNames, ...
        ["Probability"]) + ...
        contains(Tunning.(tone{:}).Properties.VariableNames, ...
        ["Inhibited"]) == 2)
    Tunning.(tone{:}).(I_Field{:})
    Inhibited = [Inhibited, Tunning.(tone{:}).(I_Field{:})];
end

% E_Grouped = [mean(Excited(:, [1:1]), 2), mean(Excited(:, [2:3]), 2),...
%     mean(Excited(:, [4:5]), 2)]
% I_Grouped = [Inhibited(:, [1:1]), mean(Inhibited(:, [2:3]), 2),...
%     mean(Inhibited(:, [4:5]), 2)]
E_Grouped = [mean(Excited(:, [1:1]), 2)]
I_Grouped = [Inhibited(:, [1:1])]

%% STATS 
% Tables Preparation Excited 
Excited = table();
Excited.Sex = Tunning.(tone{:}).Sex;
Excited.Animal = Tunning.(tone{:}).Animal;
Excited.Percentages = E_Grouped

writetable(Excited, "Excited.csv")

F_GlobalOutlierRemovalPlusSTATS('Excited.csv', 'Sex', 'Percentages', 'Animal')%, ...
    %char(target_path), 'StatsResultsExcited')
F_ToneOutlierRemoval('Excited.csv', 'Sex', 'Percentages', 'Animal')%, ...
    %char(target_path), 'StatsResultsExcited_ToneOutliers')
%%
% Tables Preparation Inhibited 
Inhibited = table();
Inhibited.Sex = TunningFE.(tone{:}).Sex;
Inhibited.Animal = TunningFE.(tone{:}).Animal;
Inhibited.Percentages = I_Grouped

writetable(Inhibited, "Inhibited.csv")

F_GlobalOutlierRemovalPlusSTATS('Inhibited.csv', 'Sex', 'Percentages', 'Animal', ...
    char(target_path), 'StatsResultsInhibited')
F_ToneOutlierRemoval('Inhibited.csv', 'Sex', 'Percentages', 'Animal', ...
    char(target_path), 'StatsResultsInhibited_ToneOutliers')
%%


E_means = [];
E_sds = [];
I_means = [];
I_sds = [];

% For visualisation
labels = ["OR"]
yl = [];
% Extracting sex differences
Group = Tunning.(tone{:}).Sex;
for g = unique(Group).'
    E_Grouped
    m_ = mean(E_Grouped(Group == g, :), 1)
    sd_ = std(E_Grouped(Group == g, :), [], 1)
    subplot(1, 2, 1)
    F_FillArea(m_, sd_./sqrt(sum(Group == g)), cell2mat(Experiment.Project.Palette(g)), 1:length(m_))
    hold on
    plot(m_, "LineWidth", 2, "Color", cell2mat(Experiment.Project.Palette(g)))
    hold on
    ylabel("% of responsive neurons")
    xticks(1:length(m_))
    xticklabels(labels)
    yl = [yl, ylim()];
%    title("Excited")

    m_ = mean(I_Grouped(Group == g, :), 1)
    sd_ = std(I_Grouped(Group == g, :), [], 1)
    subplot(1, 2, 2)
    F_FillArea(m_, sd_./sqrt(sum(Group == g)), cell2mat(Experiment.Project.Palette(g)), 1:length(m_))
    hold on  
    plot(m_, "LineWidth", 2, "Color", cell2mat(Experiment.Project.Palette(g)))
    xticks(1:length(m_))
    xticklabels(labels)
    yl = [yl, ylim()];
   % title("Inhibited")
end
ylim(get(gcf,'children'), [min(yl, [], 'all'), max(yl, [], 'all')])
% %% 
% % STEP - SETTING THE INPUT FOR THE MOVEMENT PROBABILITIES FUNCTION
% Neurons = Experiment.IMO_L;
% Iterations =  2;
% [Output, FRECS] = F_GetMovProps(Experiment,...
%      Neurons, Iterations)
% 
% %%
% % STEP - SETTING THE INPUT FOR THE FUNCTION
% TunningEpochs = ["Tone FC2", "Tone FC3"];
% ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
% Neurons = Experiment.FC;
% 
% 
% Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%     ReferenceEpochs, Neurons, Iterations);
% %%
% % STEP - SETTING THE INPUT FOR THE FUNCTION
% TunningEpochs = ["Tone FC1"];
% ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
% Neurons = Experiment.FC;
% 
% 
% Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%     ReferenceEpochs, Neurons, Iterations);
% 
% 
% %% STEP 1 - LOADING THE REQUIRED DATASETS
% output_path = "C:\Users\Ander\OneDrive\Documents\MISCELL" + ...
%     "\TestEnv\Joaquín\TestTunning";
% 
% % Adding folder to search path
% addpath(genpath(output_path))
% 
% % 2 - Creating a new folder for the query
% target_path = output_path + "\SingleNeuron " + ...
%     string(datetime(floor(now),'ConvertFrom','datenum'));
% mkdir(target_path)
% 
% % 3 - Loading the required datasets
% load("ExperimentData.mat") % As Experiment, contains all traces
% 
% %% FOR CONDITIONING
% % SETTING FUNCTION INPUTS
% Experiment.Project.Outputpath="C:\Users\Ander\OneDrive\Documents\MISCELL" + ...
%     "\TestEnv\Joaquín\TestTunning"
% Neurons = Experiment.FC;
% Iterations =  20;
% Task = Experiment.FC.Task;
% 
% TunningEpochs = ["Tone FC4", "Tone FC5"];
% ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
% %%
%     % FOR THE PRESENTATION
%     TunningEpochs = ["Pre-Tone FC1"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
%     %%
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% %%
%     % FOR EARLY CONDITIONING
%     TunningEpochs = ["Pre-Tone FC2", "Pre-Tone FC3"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
% 
% 
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% 
%     % FOR LATE CONDITIONING
%     TunningEpochs = ["Pre-Tone FC4", "Pre-Tone FC5"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);
% 
% 
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% 
% %% FOR THE EXTINCTION 1
% % SETTING FUNCTION INPUTS
% Neurons = Experiment.FE1;
% Iterations =  10;
% Task = Experiment.FE1.Task;
%     % FOR THE PRESENTATION
%     TunningEpochs = ["Tone FE1"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FE15"]);
% 
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% 
%     % FOR EARLY CONDITIONING
%     TunningEpochs = ["Tone FE2", "Tone FE3", "Tone FE4"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FE5"]);
% 
% 
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% 
%     % FOR LATE CONDITIONING
%     TunningEpochs = ["Tone FE13", "Tone FE14", "Tone FE15"];
%     ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FE5"]);
% 
% 
%     Output = F_GetTunningProps(Experiment, Task, TunningEpochs, ...
%         ReferenceEpochs, Neurons, Iterations);
% 
% %%
% % STEP - SETTING THE INPUT FOR THE FUNCTION
% TunningEpochs = ["Tone FC1"];
% ReferenceEpochs = setdiff(string(Task.Titles), [TunningEpochs, "ITI FC5"]);

