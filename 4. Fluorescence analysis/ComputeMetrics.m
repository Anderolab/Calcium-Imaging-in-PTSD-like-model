%% Loading Dataset

[filename, filepath] = uigetfile('*.mat', 'Select a Experiment File to Load');

if isequal(filename, 0)  % If user cancels the file selection 
    disp('File selection canceled');
else
    load(fullfile(filepath, filename));  % Directly load the selected file
end

TrialName = fieldnames(Experiment);
TrialName = string(TrialName{1});
animalNames = fieldnames(Experiment.(TrialName));

%% Run only for EPM test

animals = fieldnames(Experiment.EPM);
for a = 1:length(animals)
    animal = animals{a}; 
    titles = Experiment.EPM.(animal).Task.Titles;

   for t = 1:length(titles)
         title = titles{t};  

         % Replace 'ROI2' for 'ROI1'
         if startsWith(title, 'ROI2')
            newTitle = strrep(title, 'ROI2', 'ROI1');
             Experiment.EPM.(animal).Task.Titles{t} = newTitle;
         end

         % Replace 'ROI3' for 'ROI2'
         if startsWith(title, 'ROI3')
            newTitle = strrep(title, 'ROI3', 'ROI2');
            Experiment.EPM.(animal).Task.Titles{t} = newTitle;
        end

        % Replace 'ROI4' for 'ROI2'
        if startsWith(title, 'ROI4')
          newTitle = strrep(title, 'ROI4', 'ROI2');
          Experiment.EPM.(animal).Task.Titles{t} = newTitle;
       end
  end
end

%% Process all animals

% Initialize Result table 
allResults = table();

% Initialize the Binary and Composite Events matrices
allBinaryMatrices = struct(); 
allCompositeEvents = struct();

% Verify number of animals 
numAnimals = numel(animalNames);

for a = 1:numAnimals
    animalName = animalNames{a};
    
    % Ask the user to select the timestamp file for the calcium camera (once for animal)
    [timestampFile, timestampPath] = uigetfile({'*.csv;*.dat', 'Timestamp Files (*.csv, *.dat)';}, ...
                                                 ['Select Timestamp File for ', animalName], ...
                                                fullfile(filepath));
    if isequal(timestampFile, 0)  
        disp(['No timestamp file selected for ' animalName]);
        continue;  
    end

    % Read the timestamp file accordingly to format (CSV o DAT)
    [~, ~, ext] = fileparts(timestampFile); % Obtener la extensión del archivo
    if strcmp(ext, '.csv')
        timestampsData = readtable(fullfile(timestampPath, timestampFile));
        timestampsData.TimeStamp_ms_(1)=0;
    elseif strcmp(ext, '.dat')
        cameraNum = input('Select the camera number (0 o 1): ');
        datData = readtable(fullfile(timestampPath, timestampFile));
        datData = datData(datData.camNum == cameraNum, :);  % Filtrar según la cámara seleccionada
        datData.sysClock(1) =0;
    else
        disp('Unsupported timestamp file format.');
        continue;
    end

    numNeurons = size(Experiment.(TrialName).(animalName).Filt, 1);

    % Ask the user if they want to remove artifacts
    removeBadNeurons = input(['Do you want to remove identified artifacts ' animalName '? (y/n): '], 's');
    % Upload the indexes of the real neurones 
    if strcmpi(removeBadNeurons, 'y')
        % Ask the user to select the real neurones index file 
        [good_neurons, good_neurons_path] = uigetfile({'*.mat', 'Artifacts Files (*.mat)'}, ...
            'Select the good index', ...
            filepath);
        
        if isequal(good_neurons, 0)
            disp(['No file selected for ' animalName]);
            continue;
        end

        fullFilePath = fullfile(good_neurons_path, good_neurons);
        good_neurons_indices = load(fullFilePath);
        good_neurons = good_neurons_indices.good_neurons_indices; 
    else
        good_neurons = 1:numNeurons; 
    end

    % Define the intervals for ROI1, ROI2, and NO_ROI
    roi1Intervals = find(contains(Experiment.(TrialName).(animalName).Task.Titles, 'ROI1'));
    roi2Intervals = find(contains(Experiment.(TrialName).(animalName).Task.Titles, 'ROI2'));
    noRoiIntervals = find(contains(Experiment.(TrialName).(animalName).Task.Titles, 'NO_ROI'));

    % Create the categories 
    intervalCategories = {'ROI1', 'ROI2', 'NO_ROI'};
    intervals = {roi1Intervals, roi2Intervals, noRoiIntervals};
    
    % Start the result table
    results = table('Size', [numel(good_neurons), numel(intervalCategories) * 6], ... % chage size if u add categories
                    'VariableTypes', repmat({'double'}, 1, numel(intervalCategories) * 6), ...
                    'VariableNames', [strcat('Mean_', intervalCategories), ...
                                      strcat('TimeIn_', intervalCategories), ...
                                      strcat('Peaks_', intervalCategories), ...
                                      strcat('AmpPeak_', intervalCategories), ...
                                      strcat('TotalAUC_', intervalCategories), ...
                                      strcat('RatePeaks_', intervalCategories)]);
                                      
                                      % if needed add:
                                      %strcat('AUC_', intervalCategories), ...
                                      %strcat('CompPeaks_', intervalCategories), ...
                                      %strcat('AmpComp_', intervalCategories), ...

    % Inicialize the 3D matrix for composite events (if needed)
    maxFrames = max(Experiment.(TrialName).(animalName).Task.End);
    binaryMatrix = NaN(numel(good_neurons), maxFrames, numel(intervalCategories));
    compositeEvents = cell(numel(good_neurons), numel(intervalCategories));

    % Process all neurones
    for n = 1:numel(good_neurons)
        neuronIdx = good_neurons(n);
        
        for c = 1:numel(intervalCategories)
            currentIntervals = intervals{c};
            totalFluorescence = 0;
            totalFrames = 0;
            numPeaksTotal = 0;
            ampPeaksTotal = [];
            aucsTotal = [];
            maxAmpsTotal = [];
            totalCompPeaks = 0;
            totalAUCTotal = 0;
            ratePeaksTotal = [];
            filteredPeaksTotal = [];
            timestamps = [];
            numPeaksWindow = [];
            timeInRoi = 0;

            % Process each interval corresponding to the current category
            totalSeconds = 0;  
            for i = 1:numel(currentIntervals)
                intervalIdx = currentIntervals(i);

                % Obtain intervals of frames
                startFrame = Experiment.(TrialName).(animalName).Task.Start(intervalIdx);
                endFrame = Experiment.(TrialName).(animalName).Task.End(intervalIdx);

                % Obtain fluorescence data for this interval
                dataInterval = Experiment.(TrialName).(animalName).Filt(neuronIdx, startFrame:endFrame);

                % Calculate the seconds corresponding to this interval using the timestamp             
                if exist('timestampsData', 'var')
                    startTime = timestampsData.TimeStamp_ms_(startFrame); 
                    endTime = timestampsData.TimeStamp_ms_(endFrame); 
                    intervalSeconds = (endTime - startTime) / 1000; 
                    totalSeconds = totalSeconds + intervalSeconds; 

                elseif exist('datData', 'var')
                    startTime = datData.sysClock(startFrame); 
                    endTime = datData.sysClock(endFrame);
                    intervalSeconds = (endTime - startTime) / 1000; 
                    totalSeconds = totalSeconds + intervalSeconds; 

                end

                % Sum the fluorescence of this interval
                totalFluorescence = totalFluorescence + sum(dataInterval);
                % Sum the number of frames for this interval
                totalFrames = totalFrames + (endFrame - startFrame + 1);

                % Calculate peaks only if there are enough data
                if length(dataInterval) >= 3
                    % Find peaks (local maximums)
                    [peaks, locs] = findpeaks(dataInterval);

                    % Filter for irrelevant peaks
                    filteredPeaks = [];
                    filteredLocs = [];
                    minVal = min(dataInterval);
                    maxVal = max(dataInterval);
                    threshold = 0.05 * (maxVal - minVal);

                    for p = 1:numel(peaks)
                        if p > 1
                            prevMin = min(dataInterval(locs(p-1):locs(p)));
                        else
                            prevMin = minVal;
                        end
                        if p < numel(peaks)
                            nextMin = min(dataInterval(locs(p):locs(p+1)));
                        else
                            nextMin = minVal;
                        end

                        if (peaks(p) - prevMin > threshold) && (peaks(p) - nextMin > threshold)
                            filteredPeaks = [filteredPeaks; peaks(p)];
                            filteredLocs = [filteredLocs; locs(p)];
                        end
                    end

                    % Calculate the number of peaks as separare events
                    numPeaks = numel(filteredPeaks);
                    numPeaksTotal = numPeaksTotal + numPeaks;
                    % Calculate avarage amplitude
                    ampPeaksTotal = [ampPeaksTotal; filteredPeaks];

                    % Mark peaks in composite venets matrix
                    binaryMatrix(n, startFrame:endFrame, c) = NaN;
                    binaryMatrix(n, startFrame:endFrame, c) = ismember(1:(endFrame-startFrame+1), filteredLocs);

                    % Calculate composite events for AUC and amp
                    baselineComp = min(dataInterval) + 0.1 * (max(dataInterval) - min(dataInterval));
                    [events, aucs, maxAmps, totalEvents] = detectCompositeEvents(dataInterval, baselineComp);

                    % Calculate total AUC of the interval
                    totalAUC = sum(dataInterval);
                    totalAUCTotal = totalAUCTotal + totalAUC;

                    compositeEvents{n, c} = [compositeEvents{n, c}; events + startFrame - 1]; % Ajustar los frames al índice global

                    aucsTotal = [aucsTotal; aucs];
                    maxAmpsTotal = [maxAmpsTotal; maxAmps];
                    totalCompPeaks = totalCompPeaks + totalEvents;
                end
            end
            
            % Calculate peaks rate
            if totalSeconds > 0
                ratePeaks = numPeaksTotal / totalSeconds;     
            else
                ratePeaks = 0;
            end

            % Put results on final table, ignoring NaN
            results{n, sprintf('Mean_%s', intervalCategories{c})} = totalFluorescence / totalSeconds;
            results{n, sprintf('TimeIn_%s', intervalCategories{c})} = totalSeconds;
            results{n, sprintf('Peaks_%s', intervalCategories{c})} = numPeaksTotal;
            %results{n, sprintf('AmpComp_%s', intervalCategories{c})} = mean(maxAmpsTotal(~isnan(maxAmpsTotal)));
            results{n, sprintf('AmpPeak_%s', intervalCategories{c})} = mean(ampPeaksTotal(~isnan(ampPeaksTotal)));
            %results{n, sprintf('AUC_%s', intervalCategories{c})} = mean(aucsTotal(~isnan(aucsTotal)));
            %results{n, sprintf('CompPeaks_%s', intervalCategories{c})} = totalCompPeaks;
            results{n, sprintf('TotalAUC_%s', intervalCategories{c})} = totalAUCTotal;
            results{n, sprintf('RatePeaks_%s', intervalCategories{c})} = ratePeaks;
        end
    end

    % Add animal columns
    results.Animal = repmat({animalName}, numel(good_neurons), 1);
    
    % Add group columns (sex and treatment)
    results.Treatment = repmat(Experiment.Project.Groups(a, 1), numel(good_neurons), 1);
    results.Sex = repmat(Experiment.Project.Groups(a, 2), numel(good_neurons), 1);

    % Reorder the columns to put "Animal", "Sex" and "Treatment" at the
    % beginning 
    results = results(:, [{'Animal'}, {'Sex'}, {'Treatment'}, results.Properties.VariableNames(1:end-3)]);

    % Combine results of all animals
    allResults = [allResults; results];

    allBinaryMatrices.(animalName) = binaryMatrix;
    allCompositeEvents.(animalName) = compositeEvents;
    clear timestampsData; 
    clear datData; 
end

%% Ask the user to select a folder
folder_path = uigetdir(pwd, 'Select a folder to save the data');

% Check if the user pressed "Cancel"
if folder_path == 0
    disp('No folder selected.');
    return;
end

FileName = strcat('Results_', TrialName, '.xlsx')
filename = fullfile(folder_path, FileName);
writetable(allResults, filename);

%% Function to detect composite events (EXTRA)
function [events, aucs, maxAmps, totalEvents] = detectCompositeEvents(data, baselineComp)
    events = [];
    aucs = [];
    maxAmps = [];
    totalEvents = 0;
    inEvent = false;
    eventStart = 0;
    currentMaxAmp = 0;
    auc = 0;
    
    for t = 1:length(data)
        if ~inEvent && data(t) > baselineComp
            % Inicia un nuevo evento compuesto
            inEvent = true;
            eventStart = t;
            currentMaxAmp = data(t);
            auc = data(t);
        elseif inEvent
            % Dentro de un evento compuesto
            auc = auc + data(t);
            if data(t) > currentMaxAmp
                currentMaxAmp = data(t);
            end
            
            if data(t) < baselineComp || t == length(data)
                % Termina el evento compuesto
                inEvent = false;
                eventEnd = t;

                % Calcular el AUC desde el inicio hasta el fin del evento
                events = [events; eventStart, eventEnd];
                aucs = [aucs; sum(data(eventStart:eventEnd))];
                maxAmps = [maxAmps; currentMaxAmp];
                totalEvents = totalEvents + 1;
            end
        end
    end
    
    % Manejar el último evento si no se cerró
    if inEvent
        eventEnd = length(data);
        events = [events; eventStart, eventEnd];
        aucs = [aucs; sum(data(eventStart:eventEnd))];
        maxAmps = [maxAmps; currentMaxAmp];
        totalEvents = totalEvents + 1;
    end
end