%% Entering key inputs
in_path = 'H:\DLC\IMO\IMO_Crop';
animals = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
epochs = ["_E", "_L"];
Sexes = {"Female", "Female", "Female", "Female", "Female", ...
    "Male", "Male", "Male", "Male", "Male"}; %#ok<CLARRSTR>

%% Performing the concatenation

ep_ix = "_E"
an_ix = 2

for ep_ix = epochs
    
    % Generating storage arrays
    Mov = [];
    Peaks = [];
    Filt = [];
    Raw = [];
    NeuronIx = [];
    AnimalIx = [];
    SexIx = [];
    SaveName = strcat(in_path, '\All_IMO_Data', ep_ix, '.mat');
    
    for an_ix = animals

        % Setting the file path
        filename = strcat(in_path, '\IMO_M', num2str(an_ix), ...
            ep_ix, '.mat');
        
        % Loading
        load(filename) % as IMO

        animal_name = strcat('M',num2str(an_ix));
        addpath('C:\Users\1700818\OneDrive - UAB\Escritorio\ERANET_Functions\Analysis');

        if ep_ix == "_E"
            path = strcat('H:\DLC\IMO\GoodNeurones_IMO\Early');
            IMO = eliminarMalasNeuronas_IMO(IMO, animal_name, path, ep_ix); 
        else
            path = strcat('H:\DLC\IMO\GoodNeurones_IMO\Late');
            IMO = eliminarMalasNeuronas_IMO(IMO, animal_name, path, ep_ix); 
        end 
       
        % Normalising
        filtered = IMO.FiltTraces.';

        raw = IMO.RawTraces.';
        movement = IMO.Movement;
        peaks = double(islocalmax(filtered, 2));

        % Filling empty variables with NaNs
        maxCols = max(size(Mov, 2), size(movement, 2));
        
        % Adding previous records with NaNs be that needed
        Mov = [Mov, nan(size(Mov, 1), maxCols - size(Mov, 2))];
        Raw = [Raw, nan(size(Raw, 1), maxCols - size(Raw, 2))];
        Filt = [Filt, nan(size(Filt, 1), maxCols - size(Filt, 2))];
        Peaks = [Peaks, nan(size(Peaks, 1), maxCols - size(Peaks, 2))];

        % Filling it up with NaNs
        movement(size(movement, 2)+1:maxCols) = NaN;
        raw(:, size(raw, 2)+1:maxCols) = NaN;
        filtered(:, size(filtered, 2)+1:maxCols) = NaN;
        peaks(:, size(peaks, 2)+1:maxCols) = NaN;

        % Saving
        Mov = [Mov; movement];
        Raw = [Raw; raw];
        Filt = [Filt; filtered];
        Peaks = [Peaks; peaks];
        
        % Adding the informative variables regarding neuron identification,
        % animal identification and sex
        AnimalIx = [AnimalIx, repelem(an_ix, size(filtered, 1))];
        NeuronIx = [NeuronIx, 1:size(filtered, 1)];
        SexIx = [SexIx, ... 
            repelem(convertCharsToStrings(Sexes{an_ix}{:}), size(filtered, 1))];

    end

    % Structuring before saving
    IMO_Data = [];
    IMO_Data.Movement = Mov;
    IMO_Data.FiltTraces = Filt;
    IMO_Data.RawTraces = Raw;
    IMO_Data.NIX = NeuronIx;
    IMO_Data.AIX = AnimalIx;
    IMO_Data.SEX = SexIx;
    IMO_Data.Animals = animals;
    IMO_Data.Epoch = ep_ix;
    IMO_Data.Peaks = Peaks;

    % Saving
    save(SaveName, "IMO_Data")


end