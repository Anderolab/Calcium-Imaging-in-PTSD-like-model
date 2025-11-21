%% SettingEPM
warning('off'); % Disabling warnings

% Adding functions to search path
addpath(genpath("F:\Ex3_BLA\DLC\SPT_TASK"))

% Experiment properties
output_path = uigetdir();

% Experiment name
ExpName = "TestLoad";

% Abre una ventana del explorador de archivos
[file, path] = uigetfile('*.*', 'Seleccione el archivo con la información de los animales');

% Verifica si el usuario seleccionó un archivo o canceló
if isequal(file, 0)
    disp('No se seleccionó ningún archivo.');
else
    % Carga el archivo seleccionado como una variable en MATLAB
    full_file_path = fullfile(path, file);
    load(full_file_path, 'AnimalConfig'); % Asegúrate de que el archivo contenga una variable 'AnimalConfig'
end

% Generating output file
output_path = strcat(output_path, '\', ExpName);
mkdir(output_path);

% Expected animals
Animals = length(AnimalConfig.Animals);
Groups = AnimalConfig.AnimalGroups;

ColorDict = dictionary(["CORT", "VEH"], ...
    {[0, 75, 75]./255, [245, 173, 82]./255});

% Expected conditions
TrialTypes = ["SPT"];

% RF
rf = 20;

%% 1 - Finding all the relevant files
% Required function
% F_ListFiles - Identifies all .mat and .xl files in the indicated
% folder and its subfolders.

% Setting the file path
ms_path = "F:\Ex3_BLA\DLC\SPT_ms_new";
path_files = F_ListFiles(ms_path); % Identifying all the files in set path

% Creating the empty Experiment output
Experiment = struct([]);

%% 2 - Loading the files
% Report struct
Report = [];
Report.Missing = ["Missing file sessions:"];
Report.DeconvolutionError = ["Failed deconvolution sessions:"];

for trial_type = TrialTypes
    Experiment(1).(trial_type) = [];

    % Looping through each animal
    for animal = 1:Animals

        % Asking the user to provide with task information for each animal
        prompt = sprintf('Select the task mat file for animal %d', animal);
        [task_file, task_path] = uigetfile('*.mat', prompt);

        if isequal(task_file, 0)
            fprintf('No task file selected for animal %d.\n', animal);
            continue;  % Skip to the next iteration if no file is selected
        else
            task_full_path = fullfile(task_path, task_file);
            load(task_full_path, 'Task');  % Load the task file
        end

        % Identifying session-relevant path
        session_name = F_NamingFunction(animal, trial_type);  % You need to define this function
        relevant_path = path_files(contains(path_files, session_name));

        if isempty(relevant_path)
            fprintf('Session for animal %d and trial %s not found.\n', animal, trial_type);
            Report.Missing = [Report.Missing; "Session for animal " + animal + " and trial " + trial_type + " not found."];
            continue;  % Skip to the next iteration if the session file is not found
        end

        % Loading the ms file
        load(relevant_path, 'ms');  % Load the ms file

        if ~isfield(ms, 'FiltTraces')
            fprintf('Deconvolution failed for animal %d and trial %s.\n', animal, trial_type);
            Report.DeconvolutionError = [Report.DeconvolutionError; "Deconvolution failed for animal " + animal + " and trial " + trial_type];
            continue;  % Skip to the next iteration if deconvolution failed
        end

        % Normalize and filter traces
        % raw_ = ms.RawTraces';
        % for n = 1:size(raw_, 1)
        %     raw_(n, :) = lowpass(raw_(n, :), 1, rf);
        % end
        
        % Populate the Experiment structure
        Experiment.(trial_type).("M" + num2str(animal)) = struct(...
            'Path', relevant_path, ...
            'Raw', ms.RawTraces', ...
            'Filt', ms.FiltTraces', ...
            'Task', Task ...
        );
    end
end

% Save the report
Report_ = ["STEP 1: LOADING"; ""; ""; Report.Missing; ""; ...
    Report.DeconvolutionError; ""];
clear Report

%% Saving
Experiment.Project = struct(...
    'Animals', Animals, ...
    'Groups', Groups, ...
    'Trials', TrialTypes, ...
    'RF', rf, ...
    'Sourcepath', ms_path, ...
    'Outputpath', output_path, ...
    'Palette', ColorDict ...
);

% Save the report and the Experiment structure
writelines(Report_, fullfile(output_path, "Report.txt"));
save(fullfile(output_path, "ExperimentDataSPT.mat"), 'Experiment', '-v7.3');