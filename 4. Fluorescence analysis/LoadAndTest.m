%% Loading the data
% Loading the FC to simulate the first imo (IMO20)
IMOE = load("H:\DLC\IMO\IMO_Crop\All_IMO_Data_E.mat");

% Loading the FE1 to simulate the second imo (IMO10)
IMOL = load("H:\DLC\IMO\IMO_Crop\All_IMO_Data_L.mat");


%%
% Sex of each animal: - USAR ESTE NO EL Cat.Dat_SEX
Sexes = {"Female", "Female", "Female", "Female", "Female" ...
    "Male", "Male", "Male", "Male", "Male", "Male"}; 


% NOTE - For consistency purposes, let's use this dictionary to settle on
% colours for males and females. Later on (low priority) we can design a
% gui-function that prompts the user to select their own colour scheme.
ColorDict = dictionary(["Male", "Female"], ...
    {[0, 75, 75]./255, [245, 173, 82]./255});

AnimalReg = {IMOE.IMO_Data.AIX, IMOL.IMO_Data.AIX}; % Animal index per neuron
RF = 30; % FPS
EpochNames = {"Early", "Late"}; %#ok<CLARRSTR> 

%% AUC COMPARE
close all
close(gcf)
AUC_Comparison = F_Compare_AUC(IMOE.IMO_Data.FiltTraces, ...
    IMOL.IMO_Data.FiltTraces, RF, Sexes, AnimalReg, EpochNames, true,  ...
    "Mean firing frequency", ColorDict)
exportgraphics(gcf,'Sample - AUC Compare.png','Resolution',1000)
save("Sample_AUC_Compare.mat", 'AUC_Comparison')
close(gcf)

%% PEAKS COMPARE
% Testing the function - Output displayed in command.
close all  
PEAK_Comparison = F_Compare_PEAKS(IMOE.IMO_Data.Peaks, ...
    IMOL.IMO_Data.Peaks, RF, Sexes, AnimalReg, EpochNames, true, ...
    "Mean firing frequency", ColorDict)
exportgraphics(gcf,'Sample - Peaks Compare.png','Resolution',1000)
save("Sample_PEAK_Compare.mat", 'PEAK_Comparison')

%% AMPL COMPARE
% Testing the function - Output displayed in command.
close all
AMPL_Comparison = F_Compare_AMPL2(IMOE.IMO_Data.FiltTraces, ...
    IMOL.IMO_Data.FiltTraces, Sexes, AnimalReg, EpochNames, true, ...
    "Mean amplitud frequency", ColorDict,'Raw')
exportgraphics(gcf,'Sample - Amplitude compare.png','Resolution',1000)
save("Sample_AMPL_Compare.mat", 'AMPL_Comparison')

%%
Compare_AUC_PEAKS(AUC_Comparison, PEAK_Comparison)
%%


AUC_PEAKS_AMPL_Comparison=Compare_AUC_PEAKS_AMPL(AUC_Comparison, PEAK_Comparison,AMPL_Comparison)

%% MOVEMENT HIGH ACTIVITY ANALYSIS
close all
% Pre-processing the dataset
% Performing 95%CI rescaling
MovE = F_95CI_Norm(IMOE.IMO_Data.Movement);
%%
MovL = F_95CI_Norm(IMOL.IMO_Data.Movement);

% Concatenating the two structs to generate the model
MaxLen = max(size(MovE, 2), size(MovL, 2));

% Resizing and concatenating
MovE(:, size(MovE, 2):MaxLen) = NaN;
MovL(:, size(MovL, 2):MaxLen) = NaN;
Global = [MovL; MovE];

Model = F_FitGauss(Global, 'gauss2');

% Generating the model and defining the threshold
Model = F_FitGauss(Global, 'gauss2');

% Defining the gaussian fit functions
gauss2 = @(x) Model.a2*exp(-((x-Model.b2)^2)/(2*Model.c2^2));
gauss1 = @(x) Model.a1*exp(-((x-Model.b1)^2)/(2*Model.c1^2));

% Defining the intersect
diff_func = @(x) gauss1(x) - gauss2(x);
LowBound = fzero(diff_func, [Model.b1, Model.b2]);
HighBound = (1.96*Model.c2)/sqrt(2) + Model.b2;
hold on

% Visualising the area of interest
x = -2:.0001:4;
y = zeros(size(x));
y(x > LowBound & x < HighBound) = 1;
area(x, y, 'FaceAlpha', .3);
legnd = string({gca().Legend.String{:}});
legend(["", "", legnd(1:end-1), "High Activity"])

% Setting the X label
xlabel("(Act-M_d)/95CI")
exportgraphics(gcf,'Movement model.png','Resolution',1000)

% Setting the animal register
AnimalReg = {IMOE.IMO_Data.Animals; IMOL.IMO_Data.Animals};


% Comparing frames in high activity
HM_Comparison = F_Compare_MOV(MovE, MovL, Sexes, AnimalReg, EpochNames, ...
    true, "Probability of high activity", ColorDict, LowBound, HighBound)
save("High Movement Compare.mat", "HM_Comparison");
exportgraphics(gcf,'Sample - MovementModel.png','Resolution',1000)
 
%% Generating the model to identify the high movement epochs
close all
Model = F_FitGauss(Global, 'gauss2');
LowBound = Model.b1+0.67*(Model.c1/sqrt(2));
HighBound = Model.b2-0.67*(Model.c2/sqrt(2));
hold on
xline(Model.b1+0.674*(Model.c1/sqrt(2)), 'Color', 'r', 'LineWidth', 2, ...
    'LineStyle', ':')
xline(Model.b2-0.674*(Model.c2/sqrt(2)), 'Color', 'r', 'LineWidth', 2, ...
    'LineStyle', ':')
hold off
legnd = string({gca().Legend.String{:}});
legend(["", "", legnd(1:end-1), "LowBound", "HighBound"])
exportgraphics(gcf,'Sample - EventDefiningModel.png','Resolution',1000)
%%

Data1 = MovE;
Data2 = MovL;

% Sex of each animal: - USAR ESTE NO EL Cat.Dat_SEX
Sexes = {"Female", "Female", "Female", "Female", "Female", "Female", ...
    "Female", "Male", "Male", "Male", "Male", "Male", "Male", "Male"}; %#ok<CLARRSTR>

% NOTE - For consistency purposes, let's use this dictionary to settle on
% colours for males and females. Later on (low priority) we can design a
% gui-function that prompts the user to select their own colour scheme.
ColorDict = dictionary(["Male", "Female"], ...
    {[0, 75, 75]./255, [245, 173, 82]./255});

AnimalReg = {IMOE.IMO_Data.Animals, IMOL.IMO_Data.Animals}; % Animal index per neuron
RF = 30; % FPS
EpochNames = {"Early", "Late"}; %#ok<CLARRSTR> 
GroupBy = Sexes;
Visualise = true;
Y_Label = "High movement events / second";

FreqEvents = F_Compare_HM_Events(Data1, Data2, LowBound, HighBound, ...
    RF, GroupBy, AnimalReg, EpochNames, Visualise, Y_Label, ColorDict);
save("Sample_HM_Freq.mat", "FreqEvents")
exportgraphics(gcf,'Sample - Event Frequency.png','Resolution',1000)

Y_Label = "Mean event length";
[LengthEvents, Ls, Events] = F_Compare_HM_Lengths(Data1, Data2, LowBound, HighBound, ...
    RF, GroupBy, AnimalReg, EpochNames, Visualise, Y_Label, ColorDict);
Y_Label = "Mean event length";
save("Sample_HM_Len.mat", "LengthEvents")
exportgraphics(gcf,'Sample - Event Length.png','Resolution',1000)
% 0.675

%% Visualising coordination between motor and neuronal datasets
Animal = 2
flu = nansum(IMOL.IMO_Data.FiltTraces(IMOL.IMO_Data.AIX == Animal, :), 1);
flu = (flu - nanmedian(flu))/nanmedian(flu);

s1 = subplot(2, 1, 1);
plot(flu, 'Color', 'k')
ylabel("\DeltaF/F_0")
mov = MovL(IMOL.IMO_Data.Animals == Animal, :);

s2 = subplot(2, 1, 2);


plot(mov, 'Color', 'r')
ylabel('Movement score')
yticks([]);
ylabels([]);
linkaxes([s1, s2], 'x')
