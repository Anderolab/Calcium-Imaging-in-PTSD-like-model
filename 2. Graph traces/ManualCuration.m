%% Load File
% Identify "good" neurons
% Two options of exclusion criteria: 
% - Exclude cells of low variance: 
%       neuron must have variance >=10% max variance (among non-outliers).
%       change the % by changing the parameter varianceThreshFrac.

varianceThreshFrac = 0.10;

[filename, pathname] = uigetfile('*.mat', 'Select the MS file');
if isequal(filename,0)
    disp('No file selected');
else
    fullpath = fullfile(pathname, filename);
    disp(['Selected file: ' fullpath]);

    fileread(fullpath);
    load(fullpath);
end

% Initialize variance vector
segVariance = zeros(size(ms.RawTraces, 2), 1);

%% Compute variance of each neuron
for cellNum = 1:size(ms.RawTraces, 2)
    segVariance(cellNum) = var(ms.RawTraces(:, cellNum)); 
end

% Compute variance threshold
varThresh = max(segVariance) * varianceThreshFrac; 

% Ask user whether to exclude outliers for threshold calculation
excludeOutliersForThreshold = input('Do you want to exclude outliers from the threshold calculation? (y/n): ', 's');
excludeOutliersForThreshold = strcmpi(excludeOutliersForThreshold, 'y');

% Identify outliers
tempOutlier = isoutlier(segVariance, 'median');

% Exclude outliers if requested
if excludeOutliersForThreshold
    varThresh = max(segVariance(~tempOutlier)) * varianceThreshFrac;
end

% Ask user whether to consider outliers as bad neurons
considerOutliersAsBad = input('Do you want to consider outliers as bad neurons? (y/n): ', 's');
considerOutliersAsBad = strcmpi(considerOutliersAsBad, 'y');

% Ask whether to exclude neurons with abnormally large peaks
excludeNeuronsWithLargePeaks = input('Do you want to exclude neurons with abnormally large peaks? (y/n): ', 's');
excludeNeuronsWithLargePeaks = strcmpi(excludeNeuronsWithLargePeaks, 'y');

% Compute peak amplitudes
peakAmplitudes = zeros(size(ms.FiltTraces, 2), 1);
for cellNum = 1:size(ms.FiltTraces, 2)
    [peaks, ~] = findpeaks(ms.FiltTraces(:, cellNum));
    peakAmplitudes(cellNum) = mean(peaks); 
end

% Ask user which method to use for excluding large-peak neurons
if excludeNeuronsWithLargePeaks
    method = input('Choose method to exclude large-peak neurons: (1) isoutlier, (2) 99% percentile, (3) 95% percentile: ', 's');
    switch method
        case '1'
            peakOutliers = isoutlier(peakAmplitudes, 'median');
        case '2'
            upperBound = prctile(peakAmplitudes, 99);
            peakOutliers = peakAmplitudes > upperBound;
        case '3'
            upperBound = prctile(peakAmplitudes, 92);
            peakOutliers = peakAmplitudes > upperBound;
        otherwise
            error('Invalid method. Choose 1, 2, or 3.');
    end
else
    peakOutliers = false(size(peakAmplitudes));
end

% Ask user for coordinate limits to mark neurons as bad
xUpperLimit = input('Enter upper X coordinate limit to mark neurons as bad (leave blank to skip): ', 's');
xLowerLimit = input('Enter lower X coordinate limit to mark neurons as bad (leave blank to skip): ', 's');
yUpperLimit = input('Enter upper Y coordinate limit to mark neurons as bad (leave blank to skip): ', 's');
yLowerLimit = input('Enter lower Y coordinate limit to mark neurons as bad (leave blank to skip): ', 's');

% Convert limits to numeric if not empty
if ~isempty(xUpperLimit), xUpperLimit = str2double(xUpperLimit); end
if ~isempty(xLowerLimit), xLowerLimit = str2double(xLowerLimit); end
if ~isempty(yUpperLimit), yUpperLimit = str2double(yUpperLimit); end
if ~isempty(yLowerLimit), yLowerLimit = str2double(yLowerLimit); end

% Identify bad neurons based on ms.SFPs coordinates
coordBadNeurons = false(size(ms.FiltTraces, 2), 1);

for neuron = 1:size(ms.SFPs, 3)
    [rows, cols] = find(ms.SFPs(:, :, neuron));
    if ~isempty(xUpperLimit) && any(cols > xUpperLimit)
        coordBadNeurons(neuron) = true;
    end
    if ~isempty(xLowerLimit) && any(cols < xLowerLimit)
        coordBadNeurons(neuron) = true;
    end
    if ~isempty(yUpperLimit) && any(rows > yUpperLimit)
        coordBadNeurons(neuron) = true;
    end
    if ~isempty(yLowerLimit) && any(rows < yLowerLimit)
        coordBadNeurons(neuron) = true;
    end
end

% Ensure all logical arrays match the number of neurons
segVariance = segVariance(:);
peakOutliers = peakOutliers(:);
coordBadNeurons = coordBadNeurons(:);

% Identify good neurons
if considerOutliersAsBad
    good_neurons = segVariance > varThresh & ~tempOutlier & ~peakOutliers & ~coordBadNeurons;
else
    good_neurons = segVariance > varThresh & ~peakOutliers & ~coordBadNeurons;
end

% Display results
disp(['Found ', num2str(sum(good_neurons)), ' good neurons (', ...
    num2str(100 * sum(good_neurons) / length(good_neurons)), '%)']);

%% Save results

folderPath = uigetdir('', 'Select a folder');

if folderPath == 0
    disp('No folder selected');
else
    disp(['Selected folder: ' folderPath]);
end


AnimalName= string(regexp(filename, 'ms_(M\d+)_', 'tokens'));
FileName1 =strcat(folderPath, 'good_neurons_', AnimalName, '.mat')
save(FileName1, 'good_neurons');

% Optionally save indices
good_neurons_indices = find(good_neurons);
FileName2 =strcat(folderPath, 'good_neurons_', AnimalName, '_index.mat')
save(FileName2, 'good_neurons_indices');
