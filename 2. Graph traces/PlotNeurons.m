
%%
% Ask the user whether to plot all neurons, only good neurons, only bad neurons, or 20 random neurons
disp('Plotting options:');
disp('1. All neurons');
disp('2. Only good neurons');
disp('3. Only bad neurons');
disp('4. 20 random neurons');
plotOption = input('Choose an option (1/2/3/4): ');

ms.FiltTraces = ms.FiltTraces.';
ms.RawTraces = ms.RawTraces.';

% Select neurons to plot
switch plotOption
    case 1
        neuronsToPlot = 1:size(ms.FiltTraces, 1);
        titleSuffix = 'All neurons';
    case 2
        neuronsToPlot = good_neurons_indices;
        titleSuffix = 'Good neurons';
    case 3
        allNeurons = 1:size(ms.FiltTraces, 1);
        neuronsToPlot = setdiff(allNeurons, good_neurons_indices);
        titleSuffix = 'Bad neurons';
    case 4
        allNeurons = good_neurons_indices;
        numToPlot = min(20, numel(allNeurons)); % Limitar a 20 si hay menos neuronas
        neuronsToPlot = randsample(allNeurons, numToPlot);
        titleSuffix = '20 Random neurons';
    otherwise
        error('Opción no válida. Elija 1, 2, 3 o 4.');
end

% Number of neurons to plot
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
ylabel('Intensity (offset per neuron)');
if numNeurons <= 10 % Show legend only if there are <= 10 neurons
    legend('show');
end
hold off;

% Plot RawTraces
figure;
hold on;
for i = 1:numNeurons
    neuronIndex = neuronsToPlot(i);
    plot(ms.RawTraces(neuronIndex, :) + (i-1)*1, 'DisplayName', ['Neuron ' num2str(neuronIndex)]);
end
title(['RawTraces - ' titleSuffix]);
xlabel('Time (frames)');
ylabel('Intensity (offset per neuron)');
if numNeurons <= 10 % Show legend only if there are <= 10 neurons
    legend('show');
end
hold off;


%% Plot SFP (spatial footprints) in a single combined image
figure;
hold on;
colormap('jet');
combinedSFP = zeros(size(ms.SFPs, 1), size(ms.SFPs, 2));
for i = 1:numNeurons
    neuronIndex = neuronsToPlot(i);
    combinedSFP = combinedSFP + ms.SFPs(:,:,neuronIndex);
end
combinedSFP = combinedSFP / max(combinedSFP(:));
imagesc(combinedSFP);
axis equal;
axis tight;
colorbar;
title(['SFP - ' titleSuffix ' (' num2str(numNeurons) ' neurons)']);
hold off;
