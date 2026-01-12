%% STEP 1 - LOADING THE REQUIRED DATASETSEPMOF
output_path = "/Volumes/Leire RR/Minis/Calcium RESULTS";
addpath(genpath('/Volumes/Leire RR/Minis/CAIMAN/src'))
target_path = output_path + "/OF_female_veh" + string(datetime(floor(now),'ConvertFrom','datenum'));
mkdir(target_path)

% Loading and fixing the required datasets

[filename, filepath] = uigetfile('*.mat', 'Select a EXPERIMENT.MAT File to Load');

if isequal(filename, 0)  % If user cancels the file selection
    disp('File selection canceled');
else
    load(fullfile(filepath, filename));  % Directly load the selected file
end

Experiment.Project.Outputpath = target_path

%Adapt all animals to the frames of the animal with minFrames1.

% if any(contains(fieldnames(Experiment),"SPT"))
%     Experiment=SPTexperiment(Experiment);
% end
%% New colors in RGB
new_color_CORT = [0.341, 0.341, 0.976];
new_color_VEH = [0.784, 0.871, 0.976];

% Update colors in Experiment.Project.Palette
Experiment.Project.Palette("CORT") = {new_color_CORT};
Experiment.Project.Palette("VEH") = {new_color_VEH};

% Show updated colors
disp('Paleta de colores actualizada:');
disp(Experiment.Project.Palette);

%% Eliminate Artifacts

Experiment = eliminarMalasNeuronas(Experiment);

%% Choose animals to keep BE CAREFUL WITH SPT M6 MUST BE NOT CONSIDERED, FEMALE CORT ONLY REMOVE 4,5,6,7

Experiment = removeAnimalAndGroup(Experiment, [1,2,3,4,5,6,7,8,9]); % Remember to eliminate from the list the animals you want to keep

%% This part is only for EPM

% Take all animals in Experiment.EPM
 animals = fieldnames(Experiment.EPM);

% % Iterate over each animal
for a = 1:length(animals)
    animal = animals{a};  % animal name
    % Task titles of each animal
    titles = Experiment.EPM.(animal).Task.Titles;

    % Iterate over each title
    for t = 1:length(titles)
        title = titles{t};  % Título actual

        % Replace 'ROI2' with 'ROI1'
        if startsWith(title, 'ROI2')
            newTitle = strrep(title, 'ROI2', 'ROI1');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end

        % Replace 'ROI3' with 'ROI2'
        if startsWith(title, 'ROI3')
            newTitle = strrep(title, 'ROI3', 'ROI2');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end

        % Replace 'ROI4' with 'ROI2'
        if startsWith(title, 'ROI4')
            newTitle = strrep(title, 'ROI4', 'ROI2');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end
    end
end

%% STEP - SETTING THE INPUT FOR THE FUNCTION

% TunningFC = [];
% Defining the input for the function
Iterations = 1000; % 1000 for the real test
Neurons = Experiment.OR 

% Analyze 
TunningEpochs = ["ROI1"]; % All titles starting with "ROI" — always the reference ROI (e.g., center or object...)
ReferenceEpochs = ["NO_ROI","ROI2"]; % Using "NO_ROI" as reference (it’s not used, so it can be anything)
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_VEH] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Save results
save('TuningOutput.mat', "Tunning");

%% Same as before, convenient if you are using more groups and want to run it all together
% TunningFC = [];
% Defining the input for the function
Iterations = 1000
Neurons = Experiment.OR; 

% Analyze
TunningEpochs = ["ROI2"]; % Titles starting with ROI -(use the periphery, close arms, doll..)
ReferenceEpochs = ["NO_ROI","ROI1"]; % references
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_CORT] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Save results
save('TuningOutput.mat', "Tunning");

%% Same as before, convenient if you are using more groups and want to run it all together
% TunningFC = [];
% Defining the input for the function
Iterations = 1000
Neurons = Experiment.OR; 

% Analyze
TunningEpochs = ["NO_ROI"]; % Other ROI
ReferenceEpochs = ["ROI2","ROI1"]; % References
[Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,Responses_CORT] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
    ReferenceEpochs, Neurons, Iterations);
Tunning.(erase(TunningEpochs, ' ')) = Output;
% Save results
save('TuningOutput.mat', "Tunning");






%% OPTIONAL Stats

% 1: Define expected categories
categoriasRespuestas = {'Unresponsive', 'Excited', 'Inhibited'};

% 2: Convert 'ResponseType' to categorical data with defined categories
respuestasCategCORT = categorical(Responses_CORT.ResponseType, categoriasRespuestas);
respuestasCategVEH = categorical(Responses_VEH.ResponseType, categoriasRespuestas);

% 3: Count the frequencies for each category
freqCORT = countcats(respuestasCategCORT);
freqVEH = countcats(respuestasCategVEH);

% 4: Write contingency table
tablaContingencia = [freqCORT, freqVEH]';

% 5: Chi -square test
[tabla, chi2stat, chi2pValue] = crosstab([ones(size(Responses_CORT.ResponseType)); 2*ones(size(Responses_VEH.ResponseType))], ...
                                         [respuestasCategCORT; respuestasCategVEH]);

% show results
disp('Tabla de contingencia:');
disp(tabla);
disp(['Estadístico de Chi-cuadrado: ', num2str(chi2stat)]);
disp(['P-valor: ', num2str(chi2pValue)]);

%% OPTIONAL
% Calculate the means of "Probability of ROI2 Excited" and "Probability of ROI2 Inhibited" for each group
groups = {'VEH', 'CORT'};
meansExcited = zeros(1, length(groups));
meansInhibited = zeros(1, length(groups));

for i = 1:length(groups)
    group = groups{i};
    meansExcited(i) = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == group));
    meansInhibited(i) = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == group));
end

% Barplots
figure;
barData = [meansExcited; meansInhibited]';
bar(barData, 'grouped');
set(gca, 'XTickLabel', groups);
ylabel('Probability (%)');
legend({'Excited', 'Inhibited'}, 'Location', 'Best');


% View
grid on;
box on;

%% OPTIONAL

% Calculate the means of "Probability of ROI2 Excited" and "Probability of ROI2 Inhibited" for each group
meanExcitedVEH = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == "VEH"));
meanInhibitedVEH = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == "VEH"));

meanExcitedCORT = mean(Tunning.ROI2.("Probability of ROI2 Excited")(Tunning.ROI2.Sex == "CORT"));
meanInhibitedCORT = mean(Tunning.ROI2.("Probability of ROI2 Inhibited")(Tunning.ROI2.Sex == "CORT"));

% Piecharts
figure;

% plot for VEH
pie([meanExcitedVEH, meanInhibitedVEH]);
title('VEH: Mean Probability of ROI2 Excited vs. Inhibited');
legend({'Excited', 'Inhibited'}, 'Location', 'bestoutside');
figure;
% plot for CORT

pie([meanExcitedCORT, meanInhibitedCORT]);
%title('CORT: Mean Probability of ROI2 Excited vs. Inhibited');
legend({'Excited', 'Inhibited'}, 'Location', 'bestoutside');


