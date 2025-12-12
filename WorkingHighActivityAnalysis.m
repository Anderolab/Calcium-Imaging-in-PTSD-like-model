Early = load("H:\DLC\IMO\IMO_Crop\All_IMO_Data_E.mat");
Late = load("H:\DLC\IMO\IMO_Crop\All_IMO_Data_L.mat");

%% Pre-processing the dataset
% Performing 95%CI rescaling
MovE = F_95CI_Norm(Early.IMO_Data.Movement);
MovL = F_95CI_Norm(Late.IMO_Data.Movement);

% Concatenating the two structs to generate the model
MaxLen = max(size(MovE, 2), size(MovL, 2));

% 
E_ = Early.IMO_Data.Movement;
E_(:, size(E_, 2):MaxLen) = NaN;

L_ = Late.IMO_Data.Movement;
L_(:, size(L_, 2):MaxLen) = NaN;

G_ = [E_; L_];
% Resizing and concatenating
MovE(:, size(MovE, 2):MaxLen) = NaN;
MovL(:, size(MovL, 2):MaxLen) = NaN;
Global = [MovE; MovL];

subplot(1, 2, 2)
for i = 1:size(Global, 1)
    plot(Global(i, :) + i*2)
    hold on
end
yl = ylim();
subplot(1, 2, 1)
for i = 1:size(G_, 1)
    plot(G_(i, :)*10 + i*2-3)
    hold on
end
ylim(yl)
%% Generating the model and defining the threshold
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

%% Generating function input
Data1 = MovE;
Data2 = MovL;
AnimalReg = {Early.IMO_Data.Animals; Late.IMO_Data.Animals};
EpochNames = {"Early", "Late"};
Groups = {"Female", "Male"};
Y_Label = "Probability of high activity frames";
ColorDict = dictionary(["Male", "Female"], ...
    {[0, 75, 75]./255, [245, 173, 82]./255});
Sexes = {"Female", "Female", "Female", "Female", "Female", "Female", ...
    "Female", "Male", "Male", "Male", "Male", "Male", "Male", "Male"}; %#ok<*CLARRSTR> 
Visualise = true;


%% Counting
Counts = [];
Animals = [];
Epochs = [];

% Defining animals
Animals = unique([AnimalReg{:}]);

Groups = string(Sexes(Animals)).';

% Defining the output
Epochs = zeros(length(Animals), 2);

% Generating single array for storage
Data = {Data1, Data2};

for d_ix = 1:2

    for animal = Animals
        select_data = Data{d_ix}(AnimalReg{d_ix} == animal, :);
        % Computing
        high_mov = sum(select_data > LowBound & select_data < HighBound);
        non_nans = sum(~(isnan(select_data)));
        ratio = high_mov/non_nans;

        % Saving
        Epochs(Animals == animal, d_ix) = ratio;
    end
end

% Transposing
Animals = Animals.';

Out = table(Groups, Animals, Epochs)

if Visualise

    %% First visualisation - Bars with errors

    Grs = unique(Groups);
    Means = [];
    STDs = [];
    N = [];
    for gr_ix = 1:length(Grs)
        Means = [Means; nanmean(Epochs(Groups == Grs(gr_ix), :))];
        STDs = [STDs; nanstd(Epochs(Groups == Grs(gr_ix), :))];
        N = [N; sum(Epochs(Groups == Grs(gr_ix), :) - ...
            Epochs(Groups == Grs(gr_ix), :) == 0)];
    end
    
    SEM = STDs./sqrt(N);

    
    % Setting y limit register
    max_y = [];
    subplot(1, 2, 1)
    hb = F_BarPlusError(Means.', SEM.', Grs, EpochNames, ColorDict);
    ylabel(Y_Label)
    max_y = [max_y, max(ylim(gca))];
    title("With incomplete values")
    hold off
    
    
    %% Second visualisation - Points
    subplot(1, 2, 2)
    
    F_PointsAndMeans(Epochs, Groups, EpochNames, ColorDict, true)
    max_y = [max_y, max(ylim(gca))];
    title("Without incomplete values")
    subplot(1, 2, 1)
    ylim([0, max(max_y)])
    subplot(1, 2, 2)
    ylim([0, max(max_y)])
end
