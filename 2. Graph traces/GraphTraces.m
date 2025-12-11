%% Load File
[filename, pathname] = uigetfile('*.mat', 'Select the MS file');
if isequal(filename,0)
    disp('No file selected');
else
    fullpath = fullfile(pathname, filename);
    disp(['Selected file: ' fullpath]);

    fileread(fullpath);
    load(fullpath);
end

%% Options

disp('Graph options:');
disp('1. All neurons');
disp('2. Only neurons');
disp('3. Only artifacts');
plotOption = input('Choose an option (1/2/3): ');


ms.FiltTraces = ms.FiltTraces.';
ms.RawTraces = ms.RawTraces.';

% Select neurons to graph 
switch plotOption
    case 1
        neuronsToPlot = 1:size(ms.FiltTraces, 1);
        titleSuffix = 'All neurons';
    case 2
        neuronsToPlot = good_neurons_indices;
        titleSuffix = 'Only neurons';
    case 3
        allNeurons = 1:size(ms.FiltTraces, 1);
        neuronsToPlot = setdiff(allNeurons, good_neurons_indices);
        titleSuffix = 'Only artifacts';
    otherwise
        error('Non valid option. Choose 1, 2 or 3.');
end

% Number of neurons to graph
numNeurons = numel(neuronsToPlot);

% Plot FiltTraces
figure;
hold on;
for i = 1:numNeurons
    neuronIndex = neuronsToPlot(i);
    plot(ms.FiltTraces(neuronIndex, :) + (i-1)*1, 'DisplayName', ['Neuron ' num2str(neuronIndex)]);
end
title(['FiltTraces - ' titleSuffix]);
xlabel('Time (frames)');
ylabel('Intensty (offset per neuron)');
legend('show');
hold off;

% Ploteo de RawTraces
figure;
hold on;
for i = 1:numNeurons
    neuronIndex = neuronsToPlot(i);
    plot(ms.RawTraces(neuronIndex, :) + (i-1)*1, 'DisplayName', ['Neuron ' num2str(neuronIndex)]);
end
title(['RawTraces - ' titleSuffix]);
xlabel('Time (frames)');
ylabel('Intensity (offset per neuron)');
legend('show');
hold off;

% Plot SFP
figure;
hold on;
colormap('jet');
combinedSFP = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
for i = 1:numNeurons
    neuronIndex = neuronsToPlot(i);
    combinedSFP = combinedSFP + ms.SFPs(:,:,neuronIndex);
end
imagesc(combinedSFP);
axis equal;
axis tight;
colorbar;
title(['SFP - ' titleSuffix]);
hold off;