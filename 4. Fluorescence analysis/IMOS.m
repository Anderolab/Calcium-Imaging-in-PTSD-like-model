%% Loading the data
% Loading the FC to simulate the first imo (IMO20)
IMOE = load("E:\Ex3_BLA\DLC\IMO\All_IMO_Data_E.mat");

% Loading the FE1 to simulate the second imo (IMO10)
IMOL = load("E:\Ex3_BLA\DLC\IMO\All_IMO_Data_L.mat");

%%
% Sex of each animal: - USAR ESTE NO EL Cat.Dat_SEX
Sexes = {"Female", "Female", "Female", "Female", "Female" ...
    "Male", "Male", "Male", "Male", "Male"}; 

% NOTE - For consistency purposes, let's use this dictionary to settle on
% colours for males and females. Later on (low priority) we can design a
% gui-function that prompts the user to select their own colour scheme.
ColorDict = dictionary(["Male", "Female"], ...
    {[0, 75, 75]./255, [245, 173, 82]./255});

AnimalReg = {IMOE.IMO_Data.AIX, IMOL.IMO_Data.AIX}; % Animal index per neuron
RF = 60; % FPS
EpochNames = {"Early", "Late"}; 
save_path = "E:\Ex3_BLA\DLC\IMO\IMO_Results";
save_path = strcat(save_path, "\Analysis ", string(datetime(floor(now),'ConvertFrom','datenum')));
format long 
 %target_path = output_path + "\GlobalFluorescence FE1" + ...
    %string(datetime(floor(now),'ConvertFrom','datenum'));

mkdir(save_path)

path_stats_folder = strcat(save_path, "\StatResults_");
%% AUC COMPARE

close all
close(gcf)

AUC_Comparison = F_Compare_AUC(IMOE.IMO_Data.FiltTraces, ...
    IMOL.IMO_Data.FiltTraces, RF, Sexes, AnimalReg, EpochNames, true,  ...
    "Mean firing frequency", ColorDict, char(save_path))

image_AUC = strcat(path_stats_folder, "AUC\Sample - AUC Compare.pdf");
exportgraphics(gcf,image_AUC, "ContentType","vector");
report_AUC = strcat(path_stats_folder, "AUC\Sample_AUC_Compare.mat");
save(report_AUC, 'AUC_Comparison');


close(gcf)
%si me da un error sera para el Grafico, mira que haya un archivo csv, si está creado no pasa nada

%% PEAKS COMPARE
% Testing the function - Output displayed in command.
close all  

Peaks_E=islocalmax(IMOE.IMO_Data.FiltTraces,2);
Peaks_L=islocalmax(IMOL.IMO_Data.FiltTraces,2);

comparisons = {'Epochs_peak_2:Male-Epochs_peak_2:Female', 'Epochs_peak_2:Male-Epochs_peak_1:Male', ...
    'Epochs_peak_2:Female-Epochs_peak_1:Female','Epochs_peak_1:Male-Epochs_peak_1:Female'};

PEAK_Comparison = F_Compare_PEAKS(Peaks_E, ...
    Peaks_L, RF, Sexes, AnimalReg, EpochNames, true, ...
    "Mean firing frequency", ColorDict, char(save_path), comparisons, 'PosthocEpochsGroup""',true)

image_PEAKS = strcat(path_stats_folder, "Sample - Peaks Compare.pdf");
exportgraphics(gcf,image_PEAKS, "ContentType","vector");
report_PEAKS = strcat(path_stats_folder, "Sample_PEAKS_Compare.mat");
save(report_PEAKS, 'PEAK_Comparison');
% close(gcf)
%si me da un error sera para el Grafico, mira que haya un archivo csv, si está creado no pasa nada

%% Raster visualisation (NO RUN)
numframs = 10000;
numNeurons = 50;
  % 1 - Finding the best animal for each sex
    % Storage
    select_animals = zeros(1, length(unique(PEAK_Comparison.Groups)));
    % Iteration
    c = 1;
    for group = unique(PEAK_Comparison.Groups).'
        % Setting up the parameters
        gr_ix = PEAK_Comparison.Groups == group;
        gr_ans = PEAK_Comparison.Animals(gr_ix);
        % Computing DeltaPeaks
        diff = abs(PEAK_Comparison.Epochs_peak(gr_ix, 1) - ...
            PEAK_Comparison.Epochs_peak(gr_ix, 2));
        % Finding best fit
        select_animals(c) = gr_ans(diff == max(diff));
        % Counter funcion
        c = c+1;
    end
    clear c

  % 2 - Generating the rasterplots
    ix = {[1, 3, 5], [2, 4, 6], [11, 13, 15], [12, 14, 16]};
    c = 1;
    hist_max = zeros(1, 4);
    for animal = select_animals
        for contrast = {IMOE, IMOL}
            % Loading the data
            contrast = contrast{1};
            an_dat = ...
                contrast.IMO_Data.FiltTraces(contrast.IMO_Data.AIX == ...
                animal, 1:numframs);
            % Extracting the peaks
            [n, f] = find(islocalmax(an_dat(1:numNeurons, :), 2) == 1);
            subplot(9, 2, ix{c})
            scatter(f./RF, n, 5, 'k', "filled")

            xlim([1, numframs/RF])
            ylim([1, numNeurons])
            xticks([])
            xticklabels([])
            h = gca;
            h.XAxis.Visible = 'off';
            box off
            subplot(9, 2, max(ix{c})+2)
            histogram(f./RF, floor(numframs/(RF*5)), "FaceColor", 'k', ...
                'FaceAlpha', 1)
            xlim([[1, numframs/RF]])
            hist_max(c) = max(ylim());
            c = c+1;
            box off
            
        end
    end
    subplot(9, 2, ix{1})
    title("Early IMO")
    ylabel({char(9792), "Neurons"}, 'FontSize', 11, 'FontWeight', 'bold')
    yticklabels
    subplot(9, 2, ix{2})
    title("Late IMO")
    subplot(9, 2, ix{3})
    ylabel({char(9794), "Neurons"}, 'FontSize', 11, 'FontWeight', 'bold')
    subplot(9, 2, max(ix{3})+2)
    xlabel("Time (s)")
    subplot(9, 2, max(ix{4})+2)
    xlabel("Time (s)")

    % Scaling to equal
    for spt = 1:(c-1)
        subplot(9, 2, max(ix{spt})+2)
        ylim([0, max(hist_max)])
        yticks([0, max(hist_max)])
    end
    
    f_ = gcf;
    f_.Position = [294, 369, 655, 420];

image_Rastr = strcat(path_stats_folder, "Rastr.pdf");
exportgraphics(gcf,image_Rastr,'Resolution',2000);


%% AMPL COMPARE
% Testing the function - Output displayed in command.
close all

AMPL_Comparison = F_Compare_AMPL2(IMOE.IMO_Data.FiltTraces, ...
    IMOL.IMO_Data.FiltTraces, Sexes, AnimalReg, EpochNames, true, ...
    "Mean amplitude frequency", ColorDict,'Raw', char(save_path))

image_AMPL = strcat(path_stats_folder, "Sample - Amplitude compare.pdf")
exportgraphics(gcf,image_AMPL, "ContentType", "vector")
report_AMPL = strcat(path_stats_folder, "Sample_AMPL_Compare.mat")
save(report_AMPL, 'AMPL_Comparison')

close(gcf)
%si me da un error sera para el Grafico, mira que haya un archivo csv, si está creado no pasa nada



