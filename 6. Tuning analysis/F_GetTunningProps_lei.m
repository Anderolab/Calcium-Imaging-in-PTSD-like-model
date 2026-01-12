function [Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance, Responses] = F_GetTunningProps_lei(Experiment, TunningEpochs, ...
     ReferenceEpochs, Dataset, Iterations)


%% CHANGE LINE  145 FOR CORRECT ROI-REFERENCE ANALYSIS
% if startsWith(Task.Titles{i}, "NO_ROI") || startsWith(Task.Titles{i}, "ROI2") 

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
save_path = strcat(OutputPath, "/", join(TunningEpochs, " - "), ...
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


%% STEP 4 - PERFORMING THE TEST
% Looping through animals
c = 1; % Counter function
all_binarised=[];
max_len = 0;

for an = Animals.'
    wb_ = waitbar(0, strcat("Identifying responsive neurons in animal ", num2str(an)));
    prompt = strcat("   Processing animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];

    
        

    % Create TOI and TOR for each animal
    Task = Dataset.(strcat('M', num2str(an))).Task; 
    length(Task.Titles)
    TOI = []; % Time of Interest
    TOR = []; % Time of Reference

    if strcmp(TunningEpochs, "ROI")
        % When all ROIs are analyzed
        for i = 1:length(Task.Titles)
            if startsWith(Task.Titles{i}, "ROI")
                TOI = [TOI, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            else 
                TOR = [TOR, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            end
        end
    elseif startsWith(TunningEpochs, "ROI")
        % When a specific ROI is analyzed
        for i = 1:length(Task.Titles)
            %disp(['i = ', num2str(i), ' Task.Start(i) = ', num2str(Task.Start(i)), ' Task.End(i) = ', num2str(Task.End(i))])

            if startsWith(Task.Titles{i}, "NO_ROI") || startsWith(Task.Titles{i}, "ROI2")  
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
    % Creation of the binarized variable for comparison
    len_an = length(Dataset.(strcat('M', num2str(an))).Raw); %Length of the animal%s neuronal traces
    BinarisedTask = repelem("0", len_an);
    BinarisedTask(TOI) = "1";
    disp('BT')
    disp(size(BinarisedTask))
 
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

    % Añadir BinarisedTask a la matriz all_binarised
    all_binarised = [all_binarised; BinarisedTask(1:len)];

    c = c + 1;
    close(wb_);
end
length(Distances)
Output

%% STEP 5 - GENERATING THE VISUALISATIONS
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

% Second figure - Individual-neuron level visualization
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
% Define the initial space for the first neuron
espacioInicial = 0.1;

% Store the accumulated height to know where to start the next neuron
alturaAcumulada = 0;

AnimalPerNeuron=str2double(AnimalPerNeuron);
alturaPorNeurona = 0.1;
% Plot each neuron with its corresponding BinarisedTask
for i = 1:size(TopNeurons, 1)
    hold on;
    
    % Find out which animal this neuron belongs to
    neuronIndex = find(ismember(AllTraces, TopNeurons(i, :)), 1, 'first');
    
    neuronAnimalIndex = AnimalPerNeuron(neuronIndex)
    
    % Calculate highest peak
    picoMasAlto = max(TopNeurons(i, :));
    
    % Calculate the Y limits for the current neuron based on the highest peak
    YlimiteInferior = alturaAcumulada + espacioInicial;
    YlimiteSuperior = YlimiteInferior + picoMasAlto;
    
    % Update the accumulated height for the next neuron
    alturaAcumulada = YlimiteSuperior + espacioInicial;

    % Get the BinarisedTask for this neuron
    BinarisedTaskAnimal = double(all_binarised(neuronAnimalIndex, :));

    % Find the indices where the neuron is active
    indicesActivos = find(BinarisedTaskAnimal == 1);
    % Draw the vertical bands for the active indices
    for idx = 1:length(indicesActivos)
        j = indicesActivos(idx);
        if j < length(BinarisedTaskAnimal)  % Make sure we are not in the last indices
            fill([j j j+1 j+1], [YlimiteInferior YlimiteSuperior YlimiteSuperior YlimiteInferior], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', .3);
        end
    end

    % Determine the color based on the index
    if i <= 5
        color = [147, 194, 253]./255; % Blue for inhibited neurons
    else
        color = [203, 237, 146]./255; % Green for excited neurons
    end
    
    % Plot the neuron trace
    plot(TopNeurons(i, :) + YlimiteInferior, 'Color', color);
end
% Adjust limits
ylim([0, alturaAcumulada]);
xlim([1, size(TopNeurons, 2)])
xlabel("Time (Frames)");
ylabel("Filtered fluorescence");
set(gca, 'YTickLabel', arrayfun(@(x) sprintf('Neuron %d', x), 1:size(TopNeurons, 1), 'UniformOutput', false));
% Save the figure
savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
exportgraphics(Fig_, savename, "ContentType", "vector");

% Third figure - Ratios
    % Identifying the percentage of neuron tunning
    close all
    
    Properties = [sum(STD_Distance > 1.96, 'All'), ...
        sum(STD_Distance < -1.96, 'All')];
    Properties(end+1) = length(STD_Distance) - sum(Properties);
    pie(Properties)
    ax = gca();
    ax.Colormap = [203, 237, 146; 147, 194, 253; 212, 212, 212]./255; 
    legend(["Active", "Inactive", "Unresponsive"], "Location", ...
        "northeast")
    F_ = gcf;
    F_.Position = [400, 100, 390, 320];
    savename = strcat(save_path, "\Tunning - Ratios.pdf");
    exportgraphics(gcf, savename, "ContentType", "vector")

    %% STEP 6 - CLOSING
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
end